import 'package:flutter/material.dart';

import 'api/punch_api.dart';
import 'incluir_batida_screen.dart';

class SelecionarDiaScreen extends StatefulWidget {
  final DateTime inicial;
  final PunchRepository repository;
  final ValueChanged<DateTime> onDateChanged;

  const SelecionarDiaScreen({
    super.key,
    required this.inicial,
    required this.repository,
    required this.onDateChanged,
  });

  @override
  State<SelecionarDiaScreen> createState() => _SelecionarDiaScreenState();
}

class _SelecionarDiaScreenState extends State<SelecionarDiaScreen> {
  late DateTime _data;
  PunchResult? _espelho;
  bool _carregando = true;
  bool _expandido = false;
  int _tab = 0;

  static const _semanas = ['dom.', 'seg.', 'ter.', 'qua.', 'qui.', 'sex.', 'sáb.'];

  @override
  void initState() {
    super.initState();
    _data = DateTime(
      widget.inicial.year,
      widget.inicial.month,
      widget.inicial.day,
    );
    _carregar();
  }

  Future<void> _carregar() async {
    final dia = _data;
    setState(() => _carregando = true);
    final esp = await widget.repository.espelhoAtual(dia: dia);
    if (!mounted || !_mesmoDia(dia, _data)) return;
    setState(() {
      _espelho = esp;
      _carregando = false;
    });
  }

  static bool _mesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _ehHoje => _mesmoDia(_data, DateTime.now());

  void _selecionar(DateTime dia) {
    final alvo = DateTime(dia.year, dia.month, dia.day);
    if (_mesmoDia(alvo, _data)) return;
    setState(() => _data = alvo);
    widget.onDateChanged(alvo);
    _carregar();
  }

  void _voltarHoje() {
    final agora = DateTime.now();
    _selecionar(DateTime(agora.year, agora.month, agora.day));
  }

  Future<void> _incluirSolicitacao() async {
    final enviado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => IncluirBatidaScreen(
          repository: widget.repository,
          referencia: _data,
        ),
      ),
    );
    if (enviado == true && mounted) {
      await _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    final mesAno = formatMonthYearPt(_data).split(' de ');
    final mesAnoTexto =
        '${mesAno.first.toUpperCase()}/${mesAno.length > 1 ? mesAno.last : _data.year}';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                children: [
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _ehHoje ? null : _voltarHoje,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: cor.withValues(alpha: 0.45),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'HOJE',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    mesAnoTexto,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _expandido = !_expandido),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          _expandido
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: cor,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_expandido) _tabs(cor),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    if (_expandido && _tab == 0) _calendario(cor),
                    if (_expandido && _tab == 1) _resumoDoMes(),
                    if (!_expandido) ...[
                      _circuloDia(cor, 220),
                      const SizedBox(height: 24),
                      _resumoDia(),
                    ],
                    if (_expandido) ...[
                      const SizedBox(height: 20),
                      _circuloDia(cor, 140),
                      const SizedBox(height: 20),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _incluirSolicitacao,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cor,
                            side: BorderSide(color: cor, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          child: const Text(
                            'INCLUIR SOLICITAÇÃO',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _saldoBar(),
          ],
        ),
      ),
    );
  }

  Widget _tabs(Color cor) {
    Widget tab(String titulo, int indice) {
      final ativo = _tab == indice;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = indice),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: ativo ? cor : const Color(0xFF9CA3AF),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                height: 3,
                color: ativo ? cor : Colors.transparent,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            tab('CALENDÁRIO', 0),
            tab('RESUMO DO MÊS', 1),
          ],
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
      ],
    );
  }

  Widget _calendario(Color cor) {
    final primeiro = DateTime(_data.year, _data.month, 1);
    final diasNoMes = DateTime(_data.year, _data.month + 1, 0).day;
    final offset = primeiro.weekday % 7;
    final hoje = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Row(
            children: _semanas
                .map(
                  (s) => Expanded(
                    child: Text(
                      s,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.15,
            children: [
              for (var i = 0; i < offset; i++) const SizedBox.shrink(),
              for (var d = 1; d <= diasNoMes; d++)
                _DiaCalendario(
                  dia: d,
                  selecionado: _data.day == d,
                  hoje: hoje.year == _data.year &&
                      hoje.month == _data.month &&
                      hoje.day == d,
                  cor: cor,
                  onTap: () => _selecionar(DateTime(_data.year, _data.month, d)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circuloDia(Color cor, double tamanho) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatWeekdayPt(_data).substring(0, 3).toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: tamanho > 180 ? 26 : 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          Text(
            '${_data.day}',
            style: TextStyle(
              color: Colors.white,
              fontSize: tamanho > 180 ? 72 : 46,
              fontWeight: FontWeight.w700,
              height: 0.95,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumoDia() {
    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final itens = _espelho?.resumoDia ?? const <({String descricao, String valor})>[];
    if (itens.isEmpty) return const SizedBox.shrink();
    return Column(
      children: itens
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.descricao,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(
                    item.valor,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _resumoDoMes() {
    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: CircularProgressIndicator(),
      );
    }
    final itens = _espelho?.resumoMes ?? const <({String descricao, String valor})>[];
    if (itens.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Text(
          'Nenhum resumo disponível.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFE5E7EB),
          child: const Text(
            'OUTROS',
            style: TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...itens.asMap().entries.map(
              (entry) => Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: entry.key.isEven ? const Color(0xFFF8FAFC) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.value.descricao,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.value.valor,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _saldoBar() {
    final mes = _espelho?.saldoMes;
    final total = _espelho?.saldoBancoHoras;
    String valor(String? v) => (v == null || v.isEmpty) ? '--:--' : v;
    return Container(
      color: const Color(0xFF5CB85C),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SALDO DO MÊS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    valor(mes),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 34, color: Colors.white24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SALDO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    valor(total),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaCalendario extends StatelessWidget {
  final int dia;
  final bool selecionado;
  final bool hoje;
  final Color cor;
  final VoidCallback onTap;

  const _DiaCalendario({
    required this.dia,
    required this.selecionado,
    required this.hoje,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selecionado ? cor : Colors.transparent,
          border: hoje && !selecionado
              ? Border.all(color: cor, width: 1.5)
              : null,
        ),
        child: Text(
          '$dia',
          style: TextStyle(
            color: selecionado
                ? Colors.white
                : (hoje ? cor : const Color(0xFF9CA3AF)),
            fontSize: 17,
            fontWeight: selecionado || hoje ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
