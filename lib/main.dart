import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/punch_api.dart';
import 'punch_dialog.dart';
import 'package:lottie/lottie.dart';
import 'widgets/ponto_logo_animado.dart';
import 'widgets/animated_lock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  runZonedGuarded(() {
    runApp(const PontoApp());
  }, (error, stack) {
    debugPrint('UNCAUGHT ERROR: $error\n$stack');
  });
}

class PontoApp extends StatelessWidget {
  const PontoApp({super.key});

  static const brand = Color(0xFF0109B2);
  static const brandLight = Color(0xFF4A55E8);
  static const brandDark = Color(0xFF000073);
  static const background = Color(0xFFF8FAFC);
  static const success = Color(0xFF2E7D32);
  static const error = Color(0xFFC62828);
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0008A5), Color(0xFF000073)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        primary: brand,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          color: brand,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F7FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD6DEFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD6DEFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brand, width: 1.6),
        ),
      ),
    );

    return MaterialApp(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final DateTime _captured;
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _captured = DateTime.now();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AuthGate(initialNow: _captured),
        ),
      );
    });
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PontoApp.brand,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Lottie.asset(
                      'assets/clock_doodle.json',
                      fit: BoxFit.contain,
                      controller: _clock,
                    ),
                    AnimatedBuilder(
                      animation: _clock,
                      builder: (_, __) {
                        final f = _clock.value * 120;
                        final op = f < 34
                            ? 0.0
                            : (f < 48
                                ? (f - 34) / 14
                                : (f >= 102 ? (120 - f) / 18 : 1.0));
                        return Opacity(
                          opacity: op.clamp(0.0, 1.0),
                          child: const _ClockNumbers(size: 300),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const TypewriterText(
                text: 'Registrar Ponto',
                startDelay: Duration(milliseconds: 700),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration startDelay;
  final Duration charDuration;
  final String? onceKey;
  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.startDelay = Duration.zero,
    this.charDuration = const Duration(milliseconds: 80),
    this.onceKey,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  static final Set<String> _played = <String>{};
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: widget.charDuration * widget.text.length,
    );
    final key = widget.onceKey;
    if (key != null && _played.contains(key)) {
      _c.value = 1.0;
      return;
    }
    if (key != null) _played.add(key);
    if (widget.startDelay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.startDelay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final n = (widget.text.length * _c.value)
            .floor()
            .clamp(0, widget.text.length);
        final done = n >= widget.text.length;
        final typed =
            '${widget.text.substring(0, n)}${done ? '' : '|'}';
        return Stack(
          children: [
            Opacity(
              opacity: 0,
              child: Text(widget.text, style: widget.style),
            ),
            Text(typed, style: widget.style),
          ],
        );
      },
    );
  }
}

class _ClockNumbers extends StatelessWidget {
  final double size;
  const _ClockNumbers({required this.size});

  @override
  Widget build(BuildContext context) {
    final s = size / 512;
    final r = 66 * s;
    final fs = 30 * s;
    final cx = size / 2;
    final cy = size / 2;
    return Stack(
      children: [
        for (var h = 1; h <= 12; h++)
          Positioned(
            left: cx + r * math.cos((h * 30 - 90) * math.pi / 180) - fs * 0.75,
            top: cy + r * math.sin((h * 30 - 90) * math.pi / 180) - fs * 0.75,
            child: SizedBox(
              width: fs * 1.5,
              height: fs * 1.5,
              child: Center(
                child: Text(
                  '$h',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fs,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AuthGate extends StatefulWidget {
  final DateTime? initialNow;
  const AuthGate({super.key, this.initialNow});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _logged = false;
  PunchRepository? _repo;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    var logged = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = PunchRepository(prefs);
      _repo = repo;
      final jwt = repo.espelhoJwt;
      final exp = repo.espelhoExp;
      final jwtOk = jwt != null &&
          jwt.isNotEmpty &&
          (exp == null || exp.isAfter(DateTime.now()));
      final saved = repo.rememberLogin &&
          (repo.savedEnrollment?.isNotEmpty ?? false) &&
          (repo.savedPassword?.isNotEmpty ?? false);
      logged = jwtOk || saved;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _logged = logged;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_logged) {
      return HomeScreen(initialNow: widget.initialNow, repository: _repo);
    }
    return LoginScreen(
      repository: _repo,
      onLoggedIn: () => setState(() => _logged = true),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  final PunchRepository? repository;
  const LoginScreen({super.key, required this.onLoggedIn, this.repository});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _empresa = TextEditingController();
  final _matricula = TextEditingController();
  final _senha = TextEditingController();
  bool _salvar = true;
  bool _loading = false;
  bool _showPassword = false;
  String? _erro;
  final FocusNode _matriculaFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _matriculaFocus.addListener(_onMatriculaFocus);
    _load();
  }

  void _onMatriculaFocus() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = widget.repository ?? PunchRepository(prefs);
      if (!mounted) return;
      setState(() {
        _empresa.text =
            prefs.getString('company_code') ?? AppConfig.defaultCompanyCode;
        _matricula.text = repo.savedEnrollment ?? '';
        _senha.text = repo.savedPassword ?? '';
        _salvar = repo.rememberLogin || repo.savedPassword == null;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _matriculaFocus.removeListener(_onMatriculaFocus);
    _matriculaFocus.dispose();
    _empresa.dispose();
    _matricula.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final empresa = _empresa.text.trim();
    final matricula = _matricula.text.trim();
    final senha = _senha.text;
    if (empresa.isEmpty || matricula.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Preencha empresa, matrícula e senha.');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = widget.repository ?? PunchRepository(prefs);
      repo.setCompanyCode(empresa);
      final esp = await repo.espelhoAtual(
          enrollment: matricula, password: senha, persist: _salvar);
      if (!mounted) return;
      if (esp == null) {
        setState(() {
          _loading = false;
          _erro = 'Não foi possível entrar. Verifique os dados e tente novamente.';
        });
        return;
      }
      if (_salvar) {
        repo.saveEnrollment(matricula);
        repo.savePassword(senha);
        repo.setRememberLogin(true);
      } else {
        repo.setRememberLogin(false);
        repo.clearPassword();
      }
      if (!mounted) return;
      widget.onLoggedIn();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = 'Falha de conexão. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.access_time, size: 72, color: PontoApp.brand),
              const SizedBox(height: 12),
              const Text(
                'Registrar Ponto',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: PontoApp.brand),
              ),
              const SizedBox(height: 4),
              const Text(
                'Entre com os dados da empresa',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _empresa,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Código da empresa',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _matricula,
                focusNode: _matriculaFocus,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Matrícula',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline,
                        color: _matriculaFocus.hasFocus
                            ? PontoApp.brand
                            : Colors.black45)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _senha,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                    labelText: 'Senha',
                    border: const OutlineInputBorder(),
                    prefixIcon: IconButton(
                      tooltip:
                          _showPassword ? 'Ocultar senha' : 'Mostrar senha',
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: AnimatedLockIcon(
                        locked: !_showPassword,
                        color: PontoApp.brand,
                      ),
                    )),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _salvar,
                onChanged: (v) => setState(() => _salvar = v ?? false),
                title: const Text('Salvar login'),
                subtitle: const Text(
                    'Na próxima vez não precisa digitar',
                    style: TextStyle(fontSize: 12)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_erro != null) ...[
                const SizedBox(height: 8),
                Text(_erro!,
                    style: const TextStyle(color: PontoApp.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _entrar,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('ENTRAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final DateTime? initialNow;
  final PunchRepository? repository;
  const HomeScreen({super.key, this.initialNow, this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PunchRepository? _repository;
  List<String> _todayPunches = [];
  String? _jornada;
  List<String> _sugestoes = [];
  late DateTime _now;
  late DateTime _selectedDate;
  PunchResult? _historico;
  bool _historicoLoading = false;
  String? _historicoErro;
  int _historicoRequest = 0;
  Timer? _clockTimer;

  @override
  void initState() {
    final agora = widget.initialNow ?? DateTime.now();
    _now = agora;
    _selectedDate = DateTime(agora.year, agora.month, agora.day);
    super.initState();
    _init();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  Future<void> _init() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('SharedPreferences init failed: $e');
    }
    if (!mounted) return;
    if (prefs == null) return;
    final p = prefs;
    setState(() {
      _repository = widget.repository ?? PunchRepository(p);
      _todayPunches = _loadTodayPunches(p);
      _jornada = _loadJornada(p);
      _sugestoes = _loadSugestoes(p);
    });
    _atualizarEspelho();
  }

  String? _loadJornada(SharedPreferences prefs) {
    final v = prefs.getString('jornada_$_todayKey');
    return (v == null || v.isEmpty) ? null : v;
  }

  List<String> _loadSugestoes(SharedPreferences prefs) {
    final raw = prefs.getString('sugestoes_$_todayKey') ?? '';
    return raw.isEmpty ? [] : raw.split('|');
  }

  void _persistEspelho(PunchResult esp) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('jornada_$_todayKey', esp.jornada ?? '');
      prefs.setString('sugestoes_$_todayKey', esp.sugestoes.join('|'));
      prefs.setString('punches_$_todayKey', _todayPunches.join(','));
    });
  }

  Future<void> _atualizarEspelho() async {
    final repo = _repository;
    if (repo == null) return;
    final esp = await repo.espelhoAtual();
    if (!mounted || esp == null) return;
    setState(() {
      if (esp.batidasDia.isNotEmpty) {
        _todayPunches = esp.batidasDia.map(formatPunchTime).toList();
        _persistTodayPunches();
      }
      if (esp.jornada != null && esp.jornada!.isNotEmpty) {
        _jornada = esp.jornada;
      }
      if (esp.sugestoes.isNotEmpty) {
        _sugestoes = esp.sugestoes;
      }
    });
    _persistEspelho(esp);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  List<String> _loadTodayPunches(SharedPreferences prefs) {
    final raw = prefs.getString('punches_$_todayKey');
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
  }

  void _persistTodayPunches() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('punches_$_todayKey', _todayPunches.join(','));
    });
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _isHoje => _sameDay(_selectedDate, DateTime.now());

  Future<void> _pickDate() async {
    final hoje = DateTime.now();
    final primeiro = DateTime(hoje.year - 1, 1, 1);
    final ultimo = DateTime(hoje.year, hoje.month, hoje.day);
    var inicial = _selectedDate;
    if (inicial.isBefore(primeiro)) inicial = primeiro;
    if (inicial.isAfter(ultimo)) inicial = ultimo;
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primeiro,
      lastDate: ultimo,
      helpText: 'Escolha o dia',
      cancelText: 'Cancelar',
      confirmText: 'Ver dia',
      fieldLabelText: 'Dia',
      fieldHintText: 'dd/mm/aaaa',
    );
    if (picked == null || !mounted) return;
    final dia = DateTime(picked.year, picked.month, picked.day);
    if (_sameDay(dia, DateTime.now())) {
      _voltarParaHoje();
    } else {
      _carregarDia(dia);
    }
  }

  Future<void> _carregarDia(DateTime dia) async {
    final repo = _repository;
    if (repo == null) return;
    final token = ++_historicoRequest;
    setState(() {
      _selectedDate = dia;
      _historico = null;
      _historicoErro = null;
      _historicoLoading = true;
    });
    final esp = await repo.espelhoAtual(dia: dia);
    if (!mounted || token != _historicoRequest) return;
    setState(() {
      _historico = esp;
      _historicoLoading = false;
      _historicoErro =
          esp == null ? 'Não foi possível carregar este dia.' : null;
    });
  }

  void _voltarParaHoje() {
    _historicoRequest++;
    final agora = DateTime.now();
    setState(() {
      _selectedDate = DateTime(agora.year, agora.month, agora.day);
      _historico = null;
      _historicoErro = null;
      _historicoLoading = false;
    });
    _atualizarEspelho();
  }

  Future<void> _openPunchDialog() async {
    final repository = _repository;
    if (repository == null) return;
    final result = await showDialog<PunchFlowResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PunchDialog(
        initialEnrollment: repository.savedEnrollment ?? '',
        initialPassword: repository.savedPassword ?? '',
        initialRemember: repository.rememberLogin,
        existingPunches: _todayPunches,
        sugestaoPausa: _jornada,
        onRegister: (enrollment, password, remember) async {
          if (remember) {
            repository.saveEnrollment(enrollment);
            repository.savePassword(password);
            repository.setRememberLogin(true);
          } else {
            repository.clearPassword();
            repository.setRememberLogin(false);
          }
          return repository.registerPunch(enrollment, password);
        },
      ),
    );

    if (result != null && result.ok && mounted) {
      final punch = result.punch;
      if (punch != null) {
        final serverPunches = punch.batidasDia.map(formatPunchTime).toList();
        setState(() {
          if (serverPunches.isNotEmpty) {
            _todayPunches = serverPunches;
          } else {
            _todayPunches = [..._todayPunches,
                clockHms(DateTime.now()).substring(0, 5)];
          }
          if (punch.jornada != null && punch.jornada!.isNotEmpty) {
            _jornada = punch.jornada;
          }
          if (punch.sugestoes.isNotEmpty) {
            _sugestoes = punch.sugestoes;
          }
        });
        _persistTodayPunches();
        _persistEspelho(punch);
        _showSuccessDialog(punch);
      }
    } else if (result != null && !result.ok) {
      _showErrorDialog(result.error ?? 'Tente novamente.');
    }
  }

  void _showSuccessDialog(PunchResult punch) {
    showDialog(
      context: context,
      builder: (_) => SuccessPunchDialog(punch: punch),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => ErrorPunchDialog(message: message),
    );
  }

  void _showSettings() {
    final repository = _repository;
    if (repository == null) return;
    showDialog(
      context: context,
      builder: (_) => SettingsDialog(
        currentCode: repository.companyCode,
        onSave: (code) {
          repository.setCompanyCode(code);
          _historicoRequest++;
          final agora = DateTime.now();
          setState(() {
            _selectedDate = DateTime(agora.year, agora.month, agora.day);
            _historico = null;
            _historicoErro = null;
            _historicoLoading = false;
            _todayPunches = [];
            _jornada = null;
            _sugestoes = [];
          });
          _atualizarEspelho();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_repository == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: _init,
                style: TextButton.styleFrom(foregroundColor: PontoApp.brand),
                child: const Text('Não foi possível iniciar. Toque para tentar novamente.'),
              ),
            ],
          ),
        ),
      );
    }
    final hoje = _isHoje;
    final punches =
        hoje ? _todayPunches : (_historico?.batidasDia ?? const <String>[]);
    final jornada = hoje ? _jornada : _historico?.jornada;
    final sugestoes =
        hoje ? _sugestoes : (_historico?.sugestoes ?? const <String>[]);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!_isHoje) {
          _voltarParaHoje();
          return;
        }
        showDialog(
          context: context,
          builder: (_) => const _ExitDialog(),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConfig.appTitle),
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: PontoApp.brandGradient,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: 'Escolher dia',
              onPressed: _pickDate,
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Configurações',
              onPressed: _showSettings,
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (hoje)
                _ClockCard(now: _now)
              else
                _SelectedDateCard(
                  date: _selectedDate,
                  onToday: _voltarParaHoje,
                ),
              if (hoje) ...[
                const SizedBox(height: 24),
                _GradientButton(
                  onPressed: _openPunchDialog,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule, size: 22, color: Colors.white),
                      const SizedBox(width: 12),
                      TypewriterText(
                        text: 'REGISTRE SEU PONTO',
                        onceKey: 'badge_registrar',
                        startDelay: const Duration(milliseconds: 300),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule, size: 22, color: Colors.white),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (!hoje && _historicoLoading)
                const _DiaLoadingCard()
              else if (!hoje && _historicoErro != null)
                _DiaErroCard(
                  mensagem: _historicoErro!,
                  onTentarNovamente: () => _carregarDia(_selectedDate),
                )
              else
                _PunchesSection(
                  punches: punches,
                  jornada: jornada,
                  sugestoes: sugestoes,
                  titulo: hoje ? 'Registros de hoje' : 'Registros do dia',
                  mostrarPrevistas: !hoje,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  final DateTime now;
  const _ClockCard({required this.now});

  static TextSpan _digits(String d) => TextSpan(
        text: d,
        style: const TextStyle(
          color: PontoApp.brand,
          fontSize: 58,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
      );

  static TextSpan _letter(String l) => TextSpan(
        text: l,
        style: const TextStyle(
          color: PontoApp.brand,
          fontSize: 26,
          fontWeight: FontWeight.w400,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0109B2),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          const Text(
            'Olá!',
            style: TextStyle(
                color: Color(0xFF1A202C),
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          const Text(
            'Não perca mais tempo, registre o seu ponto!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Text(
            formatDatePt(now),
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(children: [
              _digits(now.hour.toString().padLeft(2, '0')),
              _letter('h'),
              _digits(now.minute.toString().padLeft(2, '0')),
              _letter('m'),
              _digits(now.second.toString().padLeft(2, '0')),
              _letter('s'),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SelectedDateCard extends StatelessWidget {
  final DateTime date;
  final VoidCallback onToday;
  const _SelectedDateCard({required this.date, required this.onToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        gradient: PontoApp.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x280108B2),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            formatWeekdayPt(date),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${date.day}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 62,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          Text(
            formatMonthYearPt(date),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onToday,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0x22FFFFFF),
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Voltar para hoje',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaLoadingCard extends StatelessWidget {
  const _DiaLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E9FF)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Carregando o dia...',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DiaErroCard extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentarNovamente;
  const _DiaErroCard({
    required this.mensagem,
    required this.onTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E9FF)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: PontoApp.error, size: 28),
          const SizedBox(height: 8),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onTentarNovamente,
            style: TextButton.styleFrom(foregroundColor: PontoApp.brand),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const _GradientButton({this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        gradient: PontoApp.brandGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x280108B2),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _PunchesSection extends StatelessWidget {
  final List<String> punches;
  final String? jornada;
  final String titulo;
  final bool mostrarPrevistas;

  /// Sugestões vindas do espelho (batidas com tipo "PREVISTA"), por slot.
  final List<String> sugestoes;

  const _PunchesSection({
    required this.punches,
    this.jornada,
    this.sugestoes = const [],
    this.titulo = 'Registros de hoje',
    this.mostrarPrevistas = false,
  });

  static const _labels = [
    'Início\njornada',
    'Início\npausa',
    'Fim\npausa',
    'Fim\njornada',
  ];

  static String _norm(String s) => s.length > 5 ? s.substring(0, 5) : s;

  /// Sugestões "PREVISTA" que a própria API manda por slot (ex.: depois do
  /// início, o espelho já prevê a batida final). Null se não houver nenhuma.
  List<String>? _sugestoesApi() {
    final api = sugestoes.take(4).map(_norm).toList();
    final out = List.generate(4, (i) => i < api.length ? api[i] : '');
    return out.every((s) => s.isEmpty) ? null : out;
  }

  /// Previstas do espelho: os slots da jornada, exatamente como o site
  /// mostra (ex.: 08:50 / 12:50 / 14:20 / 17:40). Null quando não há 4
  /// horários (ex.: jornada "DSR").
  List<String>? _jornadaPrevista() => _jornadaSlots();

  List<String>? _jornadaSlots() {
    final j = jornada?.trim() ?? '';
    if (j.isEmpty) return null;
    final horarios = RegExp(r'([01]?\d|2[0-3]):[0-5]\d')
        .allMatches(j)
        .map((m) => _norm(m.group(0)!))
        .toList();
    if (horarios.length < 4) return null;
    return horarios.take(4).toList();
  }

  static int _toMin(String t) {
    final p = t.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
    return h * 60 + m;
  }

  static List<String?>? _slotsPorVazios(
      List<String> punches, List<String>? sug) {
    if (sug == null || sug.length < 4) return null;
    final vistos = <String>{};
    final unicos = <String>[];
    for (final p in punches) {
      final h = p.length > 5 ? p.substring(0, 5) : p;
      if (vistos.add(h)) unicos.add(h);
    }
    final vazios = <int>[];
    for (var i = 0; i < 4; i++) {
      if (sug[i].isEmpty) vazios.add(i);
    }
    if (vazios.isEmpty || vazios.length != unicos.length) return null;
    final slots = List<String?>.filled(4, null);
    for (var i = 0; i < unicos.length; i++) {
      slots[vazios[i]] = unicos[i];
    }
    return slots;
  }

  /// Encaixa cada batida no slot (0..3) mais próximo da sugestão.
  /// Assim, registrar só o fim de jornada preenche o slot certo e os
  /// demais vêm do espelho. Sem sugestão, mantém a ordem posicional.
  /// Duplicadas (mesmo minuto) e extras além de 4 são descartadas.
  static List<String?> _slotsAlinhados(
      List<String> punches, List<String>? sug) {
    final vistos = <String>{};
    final unicos = <String>[];
    for (final p in punches) {
      final h = p.length > 5 ? p.substring(0, 5) : p;
      if (vistos.add(h)) unicos.add(h);
    }
    final slots = List<String?>.filled(4, null);
    if (sug == null) {
      if (unicos.length == 1) {
        slots[0] = unicos[0];
      } else if (unicos.length >= 2) {
        slots[0] = unicos.first;
        slots[3] = unicos.last;
        for (var k = 1; k < unicos.length - 1 && k < 3; k++) {
          slots[k] = unicos[k];
        }
      }
      return slots;
    }
    final livres = <int>{0, 1, 2, 3};
    final ordenadas = [...unicos]..sort();
    if (ordenadas.length >= 4) {
      for (var i = 0; i < 4; i++) {
        slots[i] = ordenadas[i];
      }
      return slots;
    }
    for (final p in ordenadas) {
      if (livres.isEmpty) break;
      var best = -1;
      var bestDiff = 1 << 30;
      for (final i in livres) {
        if (sug[i].isEmpty) continue;
        final d = (_toMin(p) - _toMin(sug[i])).abs();
        if (d < bestDiff) {
          bestDiff = d;
          best = i;
        }
      }
      if (best < 0) best = livres.first;
      slots[best] = p;
      livres.remove(best);
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final apiSug = _sugestoesApi();
    final previstas = _jornadaPrevista();
    final slots = _slotsPorVazios(punches, sugestoes) ??
        _slotsAlinhados(punches, previstas ?? apiSug);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A202C)),
        ),
        const SizedBox(height: 12),
        if (punches.isEmpty && !mostrarPrevistas)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE3E9FF)),
            ),
            child: const Column(
              children: [
                Icon(Icons.lock_outline, color: Colors.black38, size: 30),
                SizedBox(height: 8),
                Text(
                  'Nenhum registro feito hoje no Batida Online.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 15,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (i) {
                final t = slots[i];
                final apiVal =
                    (apiSug != null && i < apiSug.length) ? apiSug[i] : '';
                final prevVal =
                    (previstas != null && i < previstas.length)
                        ? previstas[i]
                        : '';
                // Logo após o 1º registro, já prevê as pausas (e o fim) com a
                // jornada prevista do espelho (igual ao site), preenchendo os
                // círculos em azul. Após registrar, o valor real substitui.
                // Antes da batida final mostra só o que o site manda (pausas
                // em branco); depois da final preenche as pausas com a
                // jornada, caso o site ainda não tenha assinalado.
                final finalOk = punches.length >= 2 || mostrarPrevistas;
                final sugVal = apiVal.isNotEmpty
                    ? apiVal
                    : (apiSug == null || finalOk ? prevVal : '');
                final sugOK = sugVal.isNotEmpty;
                final preenchido = t != null || sugOK;
                final hora = t != null
                    ? _norm(t)
                    : (sugOK ? sugVal : '--:--');
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TimeCircle(
                      time: hora,
                      sugerido: !preenchido,
                      previsto: t == null && sugOK,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _labels[i],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          height: 1.2),
                    ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _TimeCircle extends StatelessWidget {
  final String time;
  final bool sugerido;
  final bool previsto;
  const _TimeCircle(
      {required this.time, this.sugerido = false, this.previsto = false});

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF0300A2);
    const prevBg = Color(0xFFE5E7EB);
    const prevText = Color(0xFF475569);
    const prevBorder = Color(0xFFC7D0DB);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: previsto ? prevBg : (sugerido ? Colors.white : brand),
            shape: BoxShape.circle,
            border: previsto
                ? Border.all(color: prevBorder, width: 1.5)
                : (sugerido ? Border.all(color: brand, width: 2) : null),
          ),
          alignment: Alignment.center,
          child: Text(
            time,
            style: TextStyle(
              color:
                  previsto ? prevText : (sugerido ? brand : Colors.white),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: -2,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color:
                  previsto ? Colors.white : (sugerido ? brand : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(
                  color: previsto
                      ? prevBorder
                      : (sugerido ? Colors.white : brand)),
            ),
            child: Icon(
                previsto
                    ? Icons.schedule
                    : (sugerido ? Icons.schedule : Icons.check),
                size: 14,
                color:
                    previsto ? prevText : (sugerido ? Colors.white : brand)),
          ),
        ),
      ],
    );
  }
}

class _ExitDialog extends StatelessWidget {
  const _ExitDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(child: Text('Deseja sair do app?')),
      content: const Text(
        'Tem certeza de que deseja sair do app?',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black87),
      ),
      actions: [
        centeredActions([
          FilledButton(
            onPressed: () => SystemNavigator.pop(),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: const Text('SAIR'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: Colors.black87,
            ),
            child: const Text('Cancelar'),
          ),
        ]),
      ],
    );
  }
}

class SettingsDialog extends StatefulWidget {
  final String currentCode;
  final void Function(String) onSave;
  const SettingsDialog({
    super.key,
    required this.currentCode,
    required this.onSave,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentCode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurações'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Código da empresa (utilizado para identificar o dispositivo de batida online).',
            style: TextStyle(color: PontoApp.brand, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Código da empresa',
              labelStyle: TextStyle(color: PontoApp.brand),
            ),
          ),
        ],
      ),
      actions: [
        centeredActions([
          FilledButton(
            onPressed: () {
              if (_controller.text.trim().isNotEmpty) {
                widget.onSave(_controller.text.trim());
              }
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: const Text('SALVAR'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: Colors.black87,
            ),
            child: const Text('Cancelar'),
          ),
        ]),
      ],
    );
  }
}