import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'api/punch_api.dart';

class IncluirBatidaScreen extends StatefulWidget {
  final PunchRepository repository;
  final DateTime referencia;

  const IncluirBatidaScreen({
    super.key,
    required this.repository,
    required this.referencia,
  });

  @override
  State<IncluirBatidaScreen> createState() => _IncluirBatidaScreenState();
}

class _IncluirBatidaScreenState extends State<IncluirBatidaScreen> {
  late DateTime _data;
  TimeOfDay? _hora;
  final _mensagem = TextEditingController();
  PlatformFile? _arquivo;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _data = DateTime(
      widget.referencia.year,
      widget.referencia.month,
      widget.referencia.day,
    );
  }

  @override
  void dispose() {
    _mensagem.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(hoje.year - 2),
      lastDate: DateTime(hoje.year, hoje.month, hoje.day),
      helpText: 'Data da batida',
      cancelText: 'Cancelar',
      confirmText: 'Usar data',
    );
    if (escolhida == null || !mounted) return;
    setState(() {
      _data = DateTime(escolhida.year, escolhida.month, escolhida.day);
    });
  }

  Future<void> _escolherHora() async {
    final escolhida = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
      helpText: 'Horário da batida',
      cancelText: 'Cancelar',
      confirmText: 'Usar horário',
    );
    if (escolhida == null || !mounted) return;
    setState(() => _hora = escolhida);
  }

  Future<void> _escolherArquivo() async {
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (resultado == null || resultado.files.isEmpty || !mounted) return;
      setState(() => _arquivo = resultado.files.single);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível selecionar o comprovante: $e');
    }
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (_enviando) return;

    final hora = _hora;
    if (hora == null) {
      setState(() => _erro = 'Informe o horário da batida.');
      return;
    }
    if (_mensagem.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o motivo da inclusão.');
      return;
    }

    final agora = DateTime.now();
    final dataHora = DateTime(
      _data.year,
      _data.month,
      _data.day,
      hora.hour,
      hora.minute,
    );
    if (dataHora.isAfter(agora)) {
      setState(() => _erro = 'Não é permitido incluir uma batida futura.');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      final bytes = _arquivo?.bytes;
      await widget.repository.incluirBatida(
        referencia: _data,
        hora: '${hora.hour.toString().padLeft(2, '0')}:'
            '${hora.minute.toString().padLeft(2, '0')}',
        mensagem: _mensagem.text.trim(),
        nomeArquivo: _arquivo?.name,
        bytesArquivo: bytes,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Incluir batida')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dados da solicitação',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _linha(
                    icone: Icons.calendar_today_outlined,
                    titulo: 'Data da batida',
                    valor: DateFormat('dd/MM/yyyy').format(_data),
                    onTap: _escolherData,
                  ),
                  const Divider(height: 24),
                  _linha(
                    icone: Icons.schedule,
                    titulo: 'Horário',
                    valor: _hora == null
                        ? 'Selecionar horário'
                        : '${_hora!.hour.toString().padLeft(2, '0')}:'
                            '${_hora!.minute.toString().padLeft(2, '0')}',
                    onTap: _escolherHora,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _mensagem,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Motivo / justificativa',
                      hintText: 'Ex.: esqueci de bater o ponto',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'A solicitação será enviada para aprovação. O comprovante é opcional.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comprovante',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _enviando ? null : _escolherArquivo,
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _arquivo == null
                          ? 'Anexar comprovante'
                          : _arquivo!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_arquivo != null)
                    TextButton.icon(
                      onPressed: _enviando
                          ? null
                          : () => setState(() => _arquivo = null),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Remover anexo'),
                    ),
                ],
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 14),
              Text(
                _erro!,
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Enviar solicitação',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha({
    required IconData icone,
    required String titulo,
    required String valor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _enviando ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icone, size: 20, color: const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
