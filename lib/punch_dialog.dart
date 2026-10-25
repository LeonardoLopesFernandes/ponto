import 'dart:async';

import 'package:flutter/material.dart';

import 'api/punch_api.dart';
import 'main.dart';
import 'widgets/animated_lock.dart';
import 'widgets/success_check_animation.dart';

Widget centeredActions(List<Widget> buttons) {
  if (buttons.length == 1) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: buttons);
  }
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      for (var i = 0; i < buttons.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        Expanded(child: buttons[i]),
      ],
    ],
  );
}

class PunchDialog extends StatefulWidget {
  final String initialEnrollment;
  final String initialPassword;
  final bool initialRemember;
  final List<String> existingPunches;
  final String? sugestaoPausa;
  final Future<PunchFlowResult> Function(
      String enrollment, String password, bool remember) onRegister;

  const PunchDialog({
    super.key,
    required this.initialEnrollment,
    this.initialPassword = '',
    required this.initialRemember,
    this.existingPunches = const [],
    this.sugestaoPausa,
    required this.onRegister,
  });

  @override
  State<PunchDialog> createState() => _PunchDialogState();
}

class _PunchDialogState extends State<PunchDialog> {
  late final TextEditingController _enrollmentCtl;
  late final TextEditingController _passwordCtl;
  late bool _remember;
  bool _stepConfirm = false;
  bool _loading = false;
  bool _showPassword = false;
  final FocusNode _enrollmentFocus = FocusNode();
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _enrollmentCtl = TextEditingController(text: widget.initialEnrollment);
    _passwordCtl = TextEditingController(text: widget.initialPassword);
    _remember = widget.initialRemember;
    _enrollmentFocus.addListener(_onEnrollmentFocus);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _enrollmentFocus.removeListener(_onEnrollmentFocus);
    _enrollmentFocus.dispose();
    _enrollmentCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  void _onEnrollmentFocus() {
    if (mounted) setState(() {});
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    final result = await widget.onRegister(
      _enrollmentCtl.text.trim(),
      _passwordCtl.text,
      _remember,
    );
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_stepConfirm) ...[
                Text(
                  'Registre seu ponto',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: PontoApp.brand,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _stepConfirm ? _buildConfirmStep() : _buildCredentialStep(),
              const SizedBox(height: 22),
              centeredActions(
                _stepConfirm
                    ? [
                        FilledButton(
                          onPressed: _loading ? null : _confirm,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 56)),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('CONFIRMAR PONTO'),
                                ),
                        ),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() => _stepConfirm = false),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 56),
                            foregroundColor: Colors.black87,
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ]
                    : [
                        FilledButton(
                          onPressed: (_enrollmentCtl.text.trim().isNotEmpty &&
                                  _passwordCtl.text.isNotEmpty)
                              ? () => setState(() => _stepConfirm = true)
                              : null,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 56)),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('AVANÇAR'),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 56),
                            foregroundColor: Colors.black87,
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        const Text(
          'Precisamos da sua identificação para realizar o registro de ponto.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87, fontSize: 13),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _enrollmentCtl,
          focusNode: _enrollmentFocus,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Matrícula (prontuário)',
            prefixIcon: Icon(Icons.person_outline,
                color: _enrollmentFocus.hasFocus
                    ? PontoApp.brand
                    : Colors.black45),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordCtl,
          obscureText: !_showPassword,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Senha',
            prefixIcon: IconButton(
              tooltip: _showPassword ? 'Ocultar senha' : 'Mostrar senha',
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: AnimatedLockIcon(
                locked: !_showPassword,
                color: PontoApp.brand,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _remember = !_remember),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _remember
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: _remember ? PontoApp.brand : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Lembrar login (matrícula e senha)',
                      style: TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
      ),
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Color(0xFFEEF2FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock, color: PontoApp.brand, size: 26),
        ),
        const SizedBox(height: 16),
        const Text(
          'Confirme seu registro de ponto!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PontoApp.brand,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Seu ponto será registrado no horário abaixo:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${_now.hour.toString().padLeft(2, '0')}:'
                    '${_now.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: PontoApp.brand,
                      fontSize: 88,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _now.second.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatDatePt(_now),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Prefere a jornada do espelho (do site) quando disponível:
  /// "08:50 | 12:50 | 14:20 | 17:40" -> pausa = horários 2 e 3.
  String? _pausaSugerida() {
    final j = widget.sugestaoPausa;
    if (j != null && j.isNotEmpty) {
      final parts =
          j.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 4) {
        return '${parts[1]} - ${parts[2]}';
      }
    }
    return _sugerirPausa();
  }

  /// Sugere o horário de pausa (início/fim) para totalizar 07:20 trabalhadas,
  /// usando o início de jornada registrado e o horário atual como fim.
  String? _sugerirPausa() {
    if (widget.existingPunches.isEmpty) return null;
    final inicio = _parseHm(widget.existingPunches[0]);
    if (inicio == null) return null;
    final fim = _now;
    final total = fim.difference(inicio);
    if (total.isNegative) return null;
    const carga = Duration(hours: 7, minutes: 20);
    final pausa = total - carga;
    // Precisa de pausa mínima relevante para sugerir.
    if (pausa < const Duration(minutes: 15)) return null;
    // Trabalho dividido em duas metades iguais, pausa no meio.
    final antes = carga ~/ 2; // 3h40
    final inicioPausa = inicio.add(antes);
    final fimPausa = inicioPausa.add(pausa);
    return '${_fmtHm(inicioPausa)} - ${_fmtHm(fimPausa)}';
  }

  String _fmtHm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  DateTime? _parseHm(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, h, m);
  }
}

class SuccessPunchDialog extends StatelessWidget {
  final PunchResult punch;
  const SuccessPunchDialog({super.key, required this.punch});

  @override
  Widget build(BuildContext context) {
    final time = formatPunchTime(punch.time ?? clockHms(DateTime.now()));
    return AlertDialog(
      icon: const SuccessCheckAnimation(),
      title: const Center(child: Text('Ponto registrado!')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Seu ponto foi registrado com sucesso!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (punch.employeeName != null) ...[
                  Text(
                    punch.employeeName!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: PontoApp.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  punch.day != null ? '$time  •  ${punch.day}' : time,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: PontoApp.success),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        centeredActions([
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
            child: const Text('FECHAR'),
          ),
        ]),
      ],
    );
  }
}

class ErrorPunchDialog extends StatelessWidget {
  final String message;
  const ErrorPunchDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded,
          color: PontoApp.error, size: 60),
      title: const Center(child: Text('Ponto não registrado')),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black87),
      ),
      actions: [
        centeredActions([
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
            child: const Text('TENTAR NOVAMENTE'),
          ),
        ]),
      ],
    );
  }
}