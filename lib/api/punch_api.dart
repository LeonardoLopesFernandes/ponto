import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rsa_crypto.dart';

abstract class AppConfig {
  static const defaultCompanyCode = 'a474114';
  static const appTitle = 'Registrar Ponto';
}

class AhgoraApiException implements Exception {
  final String message;
  final int? code;
  AhgoraApiException(this.message, [this.code]);
  @override
  String toString() => message;
}

class PunchResult {
  final bool ok;
  final String? reason;
  final String? day;
  final String? time;
  final String? employeeName;
  final List<String> batidasDia;
  final String? jornada;

  /// Sugestões de batida do espelho (entradas com tipo "PREVISTA"),
  /// alinhadas por posição de slot (0=início, 1=início pausa, 2=fim pausa,
  /// 3=fim jornada). Posições sem previsão ficam como string vazia.
  final List<String> sugestoes;

  PunchResult({
    required this.ok,
    this.reason,
    this.day,
    this.time,
    this.employeeName,
    this.batidasDia = const [],
    this.jornada,
    this.sugestoes = const [],
  });
}

String formatPunchTime(String raw) {
  final t = raw.trim();
  if (t.contains(':')) return t.length >= 5 ? t.substring(0, 5) : t;
  if (t.length >= 6 && t.split('').every((c) => RegExp(r'\d').hasMatch(c))) {
    return '${t.substring(0, 2)}:${t.substring(2, 4)}';
  }
  if (t.length == 4 && t.split('').every((c) => RegExp(r'\d').hasMatch(c))) {
    return '${t.substring(0, 2)}:${t.substring(2, 4)}';
  }
  return t;
}

class AhgoraApi {
  static const baseUrl = 'https://app.ahgora.com.br';
  static const userAgent =
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Mobile Safari/537.36';

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);
  final Map<String, String> _cookies = {};
  bool _sessionInitialized = false;

  void clearSession() {
    _cookies.clear();
    _sessionInitialized = false;
  }

  String _cookieHeader(String? company) {
    if (company != null && company.isNotEmpty) {
      _cookies['company'] = company;
    }
    return _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  void _storeCookies(HttpHeaders headers) {
    final setCookies = headers[HttpHeaders.setCookieHeader];
    if (setCookies == null) return;
    for (final line in setCookies) {
      final parts = line.split(';');
      if (parts.isEmpty) continue;
      final first = parts.first.trim();
      final idx = first.indexOf('=');
      if (idx > 0) {
        _cookies[first.substring(0, idx)] = first.substring(idx + 1);
      }
    }
  }

  Future<void> ensureSession(String company) async {
    if (_sessionInitialized && _cookieHeader(company).isNotEmpty) return;
    try {
      await _get('/novabatidaonline/?defaultDevice=${Uri.encodeQueryComponent(company)}',
          company);
    } catch (_) {}
    _sessionInitialized = true;
  }

  Future<Map<String, dynamic>> defaultComputer(
      String company, int timezoneOffsetMinutes) async {
    final url = '$baseUrl/batidaonline/defaultComputer'
        '?c=${Uri.encodeQueryComponent(company)}&timezone_offset=$timezoneOffsetMinutes';
    final raw = await _get(url, company);
    return _json(raw);
  }

  Future<String?> getPublicKey(String identity, String company) async {
    try {
      final url = '$baseUrl/batidaonline/getPublicKey'
          '?identity=${Uri.encodeQueryComponent(identity)}';
      final json = _json(await _get(url, company));
      final key = json['public_key']?.toString();
      return (key == null || key.isEmpty) ? null : key;
    } catch (_) {
      return null;
    }
  }

  /// Espelho do ponto (usando a sessão do login): retorna os dias com
  /// jornada (sugestão de pausa) e as batidas registradas.
  Future<Map<String, dynamic>> getEspelho(
      String company, String ano, String mes) async {
    final url = '$baseUrl/api-espelho/apuracao/$ano-$mes';
    return _json(await _get(url, company));
  }

  Future<PunchResult> verifyIdentification({
    required String account,
    required String password,
    required String identity,
    required String company,
    required bool passwordEncrypted,
  }) async {
    final fields = <String, String>{
      'account': account,
      'password': password,
      'identity': identity,
      'origin': 'pw2',
      'app_version': '2.0',
      'key': '',
      if (passwordEncrypted) 'enc': 'true',
    };
    final raw = await _multipart('/batidaonline/verifyIdentification', fields, company);
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final batidas = <String>[];
      final arr = json['batidas_dia'];
      if (arr is List) {
        for (final item in arr) {
          final s = item?.toString();
          if (s != null && s.isNotEmpty) batidas.add(s);
        }
      }
      return PunchResult(
        ok: json['result'] == true,
        reason: json['reason']?.toString(),
        day: json['day']?.toString(),
        time: json['time']?.toString(),
        employeeName: json['nome']?.toString(),
        batidasDia: batidas,
      );
    } catch (_) {
      return PunchResult(ok: false);
    }
  }

  Future<String> _multipart(
      String path, Map<String, String> fields, String company) async {
    final boundary = '----WebKitFormBoundaryPontoNovo${DateTime.now().millisecondsSinceEpoch}';
    final body = StringBuffer();
    fields.forEach((key, value) {
      body.write('--$boundary\r\n');
      body.write('Content-Disposition: form-data; name="$key"\r\n\r\n');
      body.write(value);
      body.write('\r\n');
    });
    body.write('--$boundary--\r\n');

    final request = await _client.postUrl(Uri.parse('$baseUrl$path'));
    request.headers
      ..set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary')
      ..set(HttpHeaders.acceptHeader, 'application/json, text/plain, */*')
      ..set(HttpHeaders.userAgentHeader, userAgent)
      ..set('Origin', baseUrl)
      ..set('Referer',
          '$baseUrl/novabatidaonline/?defaultDevice=${Uri.encodeQueryComponent(company)}')
      ..set(HttpHeaders.cookieHeader, _cookieHeader(company));
    request.add(utf8.encode(body.toString()));
    return _response(request);
  }

  Future<String> _get(String url, String company) async {
    final request = await _client.getUrl(Uri.parse(url));
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/json, text/plain, */*')
      ..set(HttpHeaders.userAgentHeader, userAgent)
      ..set('Origin', baseUrl)
      ..set('Referer',
          '$baseUrl/novabatidaonline/?defaultDevice=${Uri.encodeQueryComponent(company)}')
      ..set(HttpHeaders.cookieHeader, _cookieHeader(company));
    return _response(request);
  }

  Future<String> _response(HttpClientRequest request) async {
    final response = await request.close();
    _storeCookies(response.headers);
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? serverMessage;
      try {
        final j = jsonDecode(body) as Map<String, dynamic>;
        serverMessage = j['message']?.toString();
      } catch (_) {}
      throw AhgoraApiException(
          serverMessage ?? 'Erro HTTP ${response.statusCode}',
          response.statusCode);
    }
    return body;
  }

  Map<String, dynamic> _json(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return {};
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}

class PunchRepository {
  final AhgoraApi _api = AhgoraApi();
  final SharedPreferences _prefs;

  PunchRepository(this._prefs);

  String? get identity => _prefs.getString('identity');
  set identity(String? value) {
    if (value == null) {
      _prefs.remove('identity');
    } else {
      _prefs.setString('identity', value);
    }
  }

  String? get publicKey => _prefs.getString('public_key');
  set publicKey(String? value) {
    if (value == null) {
      _prefs.remove('public_key');
    } else {
      _prefs.setString('public_key', value);
    }
  }

  String get companyCode =>
      _prefs.getString('company_code') ?? AppConfig.defaultCompanyCode;

  String? get savedEnrollment => _prefs.getString('enrollment');

  String? get savedPassword => _prefs.getString('password');

  bool get rememberLogin => _prefs.getBool('remember_login') ?? false;

  void setRememberLogin(bool value) => _prefs.setBool('remember_login', value);

  void saveEnrollment(String value) => _prefs.setString('enrollment', value.trim());

  void savePassword(String value) => _prefs.setString('password', value);

  void clearPassword() => _prefs.remove('password');

  void setCompanyCode(String code) {
    _prefs.setString('company_code', code.trim());
    identity = null;
    publicKey = null;
    clearPassword();
    _api.clearSession();
  }

  Future<PunchFlowResult> registerPunch(String enrollment, String password) async {
    try {
      return await _performPunch(enrollment.trim(), password);
    } catch (e) {
      final msg = e is AhgoraApiException
          ? e.message
          : (e is SocketException
              ? 'Sem conexão com a internet. Verifique sua rede e tente novamente.'
              : 'Erro inesperado: ${e.toString()}');
      return PunchFlowResult.failure(msg);
    }
  }

  Future<PunchFlowResult> _performPunch(String enrollment, String password) async {
    final tzOffset = DateTime.now().timeZoneOffset.inMinutes;
    final company = companyCode;

    await _api.ensureSession(company);

    var ident = identity;
    if (ident == null || ident.isEmpty) {
      final computer = await _api.defaultComputer(company, tzOffset);
      ident = computer['identity']?.toString();
      if (ident == null || ident.isEmpty || ident == 'false') {
        return PunchFlowResult.failure(
          'Não foi possível identificar o dispositivo. Verifique se o celular está conectado '
          'à rede da empresa e se o código da empresa está correto (Configurações).',
        );
      }
      identity = ident;
    }

    var key = publicKey;
    if (key == null || key.isEmpty) {
      key = await _api.getPublicKey(ident, company);
      if (key != null && key.isNotEmpty) publicKey = key;
    }

    var passwordEncrypted = false;
    String effectivePassword = password;
    if (key != null && key.isNotEmpty) {
      final encrypted = RsaCrypto.encryptWithPublicKey(key, password);
      if (encrypted != null) {
        effectivePassword = encrypted;
        passwordEncrypted = true;
      }
    }

    final result = await _api.verifyIdentification(
      account: enrollment,
      password: effectivePassword,
      identity: ident,
      company: company,
      passwordEncrypted: passwordEncrypted,
    );

    if (result.ok) {
      // Busca o espelho do ponto para obter a jornada (sugestão de pausa)
      // e as batidas reais do dia.
      try {
        final hoje = DateTime.now();
        final espelho = await _api.getEspelho(
          company,
          '${hoje.year}',
          '${hoje.month.toString().padLeft(2, '0')}',
        );
        final hojeKey = DateFormat('yyyy-MM-dd').format(hoje);
        print('ESPELHO_API $hojeKey: $espelho');
        final dias = espelho['dias'];
        Map? dia;
        if (dias is Map) {
          final d = dias[hojeKey];
          if (d is Map) dia = Map.from(d);
        } else if (dias is List) {
          for (final d in dias) {
            if (d is Map &&
                (d['data']?.toString() == hojeKey ||
                    d['dia']?.toString() == hojeKey ||
                    d['date']?.toString() == hojeKey)) {
              dia = d;
              break;
            }
          }
        }
        final jornada = (dia?['jornada'] ??
                dia?['jornadaPrevista'] ??
                dia?['escala'] ??
                '')
            .toString();
        // O espelho traz as batidas por slot: as reais vêm com tipo
        // "ORIGINAL" (ou "MANUAL"/"registrado") e as sugestões com tipo
        // "PREVISTA". Mantemos as sugestões alinhadas à posição do slot.
        final espelhoBatidas = <String>[];
        final espelhoSugestoes = <String>[];
        final arr = dia?['batidas'] ?? dia?['marcacoes'] ?? dia?['registros'];
        if (arr is List) {
          for (final b in arr) {
            if (b is! Map) continue;
            final hora =
                (b['hora'] ?? b['time'] ?? b['batida'] ?? '').toString();
            final tipo =
                (b['tipo'] ?? b['type'] ?? '').toString().toUpperCase();
            if (tipo == 'PREVISTA') {
              // Mantém a posição do slot (índice do array) na lista.
              espelhoSugestoes.add(hora.isEmpty ? '' : formatPunchTime(hora));
            } else {
              espelhoSugestoes.add('');
              if (hora.isNotEmpty) espelhoBatidas.add(formatPunchTime(hora));
            }
          }
        }
        return PunchFlowResult.success(PunchResult(
          ok: true,
          day: result.day,
          time: result.time,
          employeeName: result.employeeName,
          batidasDia: espelhoBatidas.isNotEmpty
              ? espelhoBatidas
              : result.batidasDia,
          jornada: jornada,
          sugestoes: espelhoSugestoes,
        ));
      } catch (_) {
        // Sem espelho, mantém o resultado do registro.
      }
      return PunchFlowResult.success(result);
    }
    return PunchFlowResult.failure(_mapFailure(result.reason));
  }

  String _mapFailure(String? reason) {
    switch (reason) {
      case 'invalid_user_or_password':
        return 'Matrícula ou senha inválidos. Verifique seus dados e tente novamente.';
      case 'invalid_company':
        return 'Código da empresa inválido. Verifique e tente novamente.';
      case 'device_not_activated':
      case 'not_activated':
      case 'device_inactive':
        return 'Dispositivo não ativado. Ative-o no PontoWEB antes de registrar o ponto.';
      case 'ip_not_allowed':
      case 'invalid_ip':
        return 'Faixa de IP não liberada. Registre o ponto em uma rede autorizada.';
      case 'device_expired':
        return 'Validade do dispositivo expirada. Contate o RH para reativar.';
      case 'employee_not_found':
        return 'Funcionário não encontrado. Verifique sua matrícula.';
      case 'outside_work_schedule':
        return 'Registro fora do horário de trabalho permitido.';
      case null:
      case '':
        return 'Seu ponto não pôde ser registrado. Tente novamente ou entre em contato com o RH.';
      default:
        return 'Seu ponto não pôde ser registrado ($reason). Tente novamente ou contate o RH.';
    }
  }
}

class PunchFlowResult {
  final bool ok;
  final PunchResult? punch;
  final String? error;

  PunchFlowResult._(this.ok, this.punch, this.error);

  factory PunchFlowResult.success(PunchResult punch) =>
      PunchFlowResult._(true, punch, null);

  factory PunchFlowResult.failure(String error) =>
      PunchFlowResult._(false, null, error);
}

String formatDatePt(DateTime d) {
  final weekdays = {
    DateTime.monday: 'Segunda-feira',
    DateTime.tuesday: 'Terça-feira',
    DateTime.wednesday: 'Quarta-feira',
    DateTime.thursday: 'Quinta-feira',
    DateTime.friday: 'Sexta-feira',
    DateTime.saturday: 'Sábado',
    DateTime.sunday: 'Domingo',
  };
  final months = {
    1: 'janeiro', 2: 'fevereiro', 3: 'março', 4: 'abril', 5: 'maio', 6: 'junho',
    7: 'julho', 8: 'agosto', 9: 'setembro', 10: 'outubro', 11: 'novembro', 12: 'dezembro',
  };
  return '${weekdays[d.weekday]}, ${d.day} de ${months[d.month]} de ${d.year}';
}

String clockHm(DateTime t) => DateFormat('HH:mm').format(t);
String clockHms(DateTime t) => DateFormat('HH:mm:ss').format(t);

String clockHmS(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}h'
    '${t.minute.toString().padLeft(2, '0')}m'
    '${t.second.toString().padLeft(2, '0')}s';