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

  Future<void> _abrirSeletorMes() async {
    final escolhido = await showDialog<DateTime>(
      context: context,
      builder: (_) => _SeletorMesDialog(
        anoInicial: _data.year,
        mesSelecionado: _data.month,
        cor: Theme.of(context).colorScheme.primary,
      ),
    );
    if (escolhido == null || !mounted) return;
    final ultimoDia =
        DateTime(escolhido.year, escolhido.month + 1, 0).day;
    final dia = _data.day > ultimoDia ? ultimoDia : _data.day;
    _selecionar(DateTime(escolhido.year, escolhido.month, dia));
  }

  void _anterior() {
    _selecionar(_data.subtract(const Duration(days: 1)));
  }

  void _seguinte() {
    final hoje = DateTime.now();
    final proximo = _data.add(const Duration(days: 1));
    if (proximo.isAfter(DateTime(hoje.year, hoje.month, hoje.day))) return;
    _selecionar(proximo);
  }

  Future<void> _mostrarEscala() async {
    final jornada = _espelho?.jornada ?? '';
    final escala = _espelho?.escala ?? '';
    if (jornada.isEmpty && escala.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Escala/Jornada',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              if (jornada.isNotEmpty)
                Text(
                  jornada,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),
              if (escala.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  escala,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 17,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _diaComMenu(Color cor) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _circuloDia(cor, 180),
        Positioned(
          top: 6,
          right: -8,
          child: Material(
            color: const Color(0xFFD1D5DB),
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _mostrarEscala,
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(Icons.more_horiz, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
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
                  InkWell(
                    onTap: _abrirSeletorMes,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mesAnoTexto,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, color: cor, size: 22),
                        ],
                      ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _anterior,
                            icon: Icon(Icons.chevron_left, color: cor, size: 36),
                            tooltip: 'Dia anterior',
                          ),
                          _diaComMenu(cor),
                          IconButton(
                            onPressed: _ehHoje ? null : _seguinte,
                            icon: Icon(
                              Icons.chevron_right,
                              color: _ehHoje ? const Color(0xFFCBD5E1) : cor,
                              size: 36,
                            ),
                            tooltip: 'Próximo dia',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _resumoDia(),
                    ],
                    if (_expandido) ...[
                      const SizedBox(height: 20),
                      _diaEBatidas(cor),
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

  Widget _diaEBatidas(Color cor) {
    final entradas = _entradasDia(_espelho);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _circuloDiaContorno(cor, 70),
          const SizedBox(width: 8),
          Expanded(
            child: _carregando
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : entradas.isEmpty
                    ? const Text(
                        'Sem batidas neste dia',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: entradas
                              .map(
                                (entrada) => Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: _batidaCirculo(
                                    entrada.hora,
                                    cor,
                                    previsto: entrada.previsto,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<({String hora, bool previsto})> _entradasDia(PunchResult? espelho) {
    if (espelho == null) return const [];
    final previstas = _previstasDosSlots(espelho);
    final slots = List<String?>.filled(4, null);
    final usados = <int>{};

    for (final raw in espelho.batidasDia) {
      final hora = formatPunchTime(raw);
      final alvo = _minutos(hora);
      var melhor = -1;
      var menorDistancia = 9999;
      for (var i = 0; i < 4; i++) {
        if (previstas[i].isEmpty || usados.contains(i)) continue;
        final distancia = (_minutos(previstas[i]) - alvo).abs();
        if (distancia < menorDistancia) {
          menorDistancia = distancia;
          melhor = i;
        }
      }
      if (melhor < 0) {
        for (var i = 0; i < 4; i++) {
          if (slots[i] == null) {
            melhor = i;
            break;
          }
        }
      }
      if (melhor >= 0) {
        slots[melhor] = hora;
        usados.add(melhor);
      }
    }

    final resultado = <({String hora, bool previsto})>[];
    for (var i = 0; i < 4; i++) {
      final real = slots[i];
      if (real != null) {
        resultado.add((hora: real, previsto: false));
      } else if (previstas[i].isNotEmpty) {
        resultado.add((hora: previstas[i], previsto: true));
      }
    }
    return resultado;
  }

  List<String> _previstasDosSlots(PunchResult espelho) {
    final previstas = List<String>.filled(4, '');
    for (var i = 0; i < 4 && i < espelho.sugestoes.length; i++) {
      previstas[i] = formatPunchTime(espelho.sugestoes[i]);
    }
    if (previstas.every((h) => h.isEmpty)) {
      final horarios = RegExp(r'([01]?\d|2[0-3]):[0-5]\d')
          .allMatches(espelho.jornada ?? '')
          .map((m) => m.group(0)!)
          .take(4)
          .toList();
      for (var i = 0; i < horarios.length; i++) {
        previstas[i] = horarios[i];
      }
    }
    return previstas;
  }

  int _minutos(String hora) {
    final partes = hora.split(':');
    return (int.tryParse(partes.first) ?? 0) * 60 +
        (partes.length > 1 ? int.tryParse(partes[1]) ?? 0 : 0);
  }

  Widget _circuloDiaContorno(Color cor, double tamanho) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: cor, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatWeekdayPt(_data).substring(0, 3).toUpperCase(),
            style: TextStyle(
              color: cor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '${_data.day}',
            style: TextStyle(
              color: cor,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 0.95,
            ),
          ),
        ],
      ),
    );
  }

  Widget _batidaCirculo(
    String hora,
    Color cor, {
    bool previsto = false,
  }) {
    final tom = previsto ? const Color(0xFF94A3B8) : cor;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: tom, width: previsto ? 1 : 1.3),
      ),
      child: Text(
        hora,
        style: TextStyle(
          color: tom,
          fontSize: 11,
          fontWeight: previsto ? FontWeight.w400 : FontWeight.w500,
        ),
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
              fontSize: tamanho > 150 ? 26 : 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          Text(
            '${_data.day}',
            style: TextStyle(
              color: Colors.white,
              fontSize: tamanho > 150 ? 72 : 46,
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

class _SeletorMesDialog extends StatefulWidget {
  final int anoInicial;
  final int mesSelecionado;
  final Color cor;

  const _SeletorMesDialog({
    required this.anoInicial,
    required this.mesSelecionado,
    required this.cor,
  });

  @override
  State<_SeletorMesDialog> createState() => _SeletorMesDialogState();
}

class _SeletorMesDialogState extends State<_SeletorMesDialog> {
  static const _meses = [
    'JAN.',
    'FEV.',
    'MAR.',
    'ABR.',
    'MAI.',
    'JUN.',
    'JUL.',
    'AGO.',
    'SET.',
    'OUT.',
    'NOV.',
    'DEZ.',
  ];
  late int _ano;

  @override
  void initState() {
    super.initState();
    _ano = widget.anoInicial;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 340,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _ano--),
                    icon: Icon(Icons.chevron_left, color: widget.cor, size: 30),
                  ),
                  const Spacer(),
                  Text(
                    '$_ano',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _ano++),
                    icon: Icon(Icons.chevron_right, color: widget.cor, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.15,
                children: List.generate(12, (i) {
                  final mes = i + 1;
                  final selecionado = mes == widget.mesSelecionado &&
                      _ano == widget.anoInicial;
                  return Padding(
                    padding: const EdgeInsets.all(4),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(
                        DateTime(_ano, mes),
                      ),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: selecionado
                            ? BoxDecoration(
                                color: widget.cor,
                                borderRadius: BorderRadius.circular(4),
                              )
                            : null,
                        child: Text(
                          _meses[i],
                          style: TextStyle(
                            color: selecionado ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
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
