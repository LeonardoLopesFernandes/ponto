import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/punch_api.dart';
import 'punch_dialog.dart';

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
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _captured = DateTime.now();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(initialNow: _captured),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
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
              ScaleTransition(
                scale: _pulse.drive(Tween<double>(begin: 1.0, end: 0.8)),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.schedule, size: 64, color: PontoApp.brand),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Registrar Ponto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final DateTime? initialNow;
  const HomeScreen({super.key, this.initialNow});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PunchRepository? _repository;
  List<String> _todayPunches = [];
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    _now = widget.initialNow ?? DateTime.now();
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
      _repository = PunchRepository(p);
      _todayPunches = _loadTodayPunches(p);
    });
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
        });
        _persistTodayPunches();
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
          setState(() {
            repository.setCompanyCode(code);
          });
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
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
              _ClockCard(now: _now),
              const SizedBox(height: 24),
              _GradientButton(
                onPressed: _openPunchDialog,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 22, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'REGISTRE SEU PONTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _TodayPunchesSection(punches: _todayPunches),
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
          Text(
            formatDatePt(now),
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            clockHms(now),
            style: const TextStyle(
              color: PontoApp.brand,
              fontSize: 58,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
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

class _TodayPunchesSection extends StatelessWidget {
  final List<String> punches;
  const _TodayPunchesSection({required this.punches});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registros de hoje',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (punches.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: punches.map((t) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: PontoApp.brand,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  t,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
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