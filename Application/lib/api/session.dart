import 'package:flutter/foundation.dart';

import '../data.dart';
import '../models.dart';
import 'api_client.dart';
import 'mappers.dart';

/// Code 2FA demandé à la connexion.
class TwoFactorRequired implements Exception {
  final String? devCode;
  TwoFactorRequired(this.devCode);
}

/// Session utilisateur + chargement des données depuis l'API.
///
/// `online == false` : mode démo (données embarquées de `MockData`).
class Session extends ChangeNotifier {
  Session._();
  static final Session instance = Session._();

  final api = ApiClient.instance;

  bool online = false;
  bool loading = false;
  Map<String, dynamic>? me;
  String demoRole = 'client';

  // Portefeuille
  int balanceXaf = 45000;
  int escrowXaf = 250000;
  int withdrawableXaf = 44500;
  bool twoFaRequired = false;
  List<Map<String, dynamic>> transactions = [];

  // Espace pro
  Map<String, dynamic>? dashboard;
  List<Map<String, dynamic>> quotes = [];

  // ------------------------------------------------------------ identité

  String get role => online ? (me?['role'] ?? 'client') : demoRole;
  bool get isPro => role == 'pro';
  String get userId => online ? (me?['id'] ?? '') : 'me';
  String get name =>
      online ? (me?['name'] ?? '') : (isPro ? MockData.pros[0].name : 'Emmanuel Sakam');
  String get firstName {
    final parts = name.split(' ');
    return parts.length > 1 && parts.first.endsWith('.') ? '${parts[0]} ${parts[1]}' : parts.first;
  }
  String get avatar => online ? (me?['avatar_url'] ?? '') : MockData.meAvatar;
  String get city => online ? (me?['city'] ?? '') : 'Douala';
  bool get twoFaEnabled => online ? (me?['two_fa_enabled'] ?? false) : false;

  /// Profil pro de l'utilisateur connecté (ou pro de démo).
  Pro get mePro {
    if (online && me?['pro'] != null) return Mappers.pro(me!['pro'] as Map<String, dynamic>);
    return MockData.pros[0];
  }

  // ------------------------------------------------------------ auth

  /// Au lancement : restaure la session mémorisée si le jeton est valide.
  Future<bool> restore() async {
    await api.load();
    if (!api.hasSession) return false;
    try {
      me = await api.get('/auth/me');
      online = true;
      await bootstrap();
      return true;
    } catch (_) {
      await api.clearTokens();
      return false;
    }
  }

  Future<void> login(String login, String password, {String? otp}) async {
    try {
      final r = await api.post('/auth/login', {
        'login': login.trim(),
        'password': password,
        if (otp != null && otp.isNotEmpty) 'otp': otp.trim(),
      });
      await _open(r);
    } on ApiException catch (e) {
      if (e.status == 401 && e.body?['code'] == '2fa_required') {
        throw TwoFactorRequired(e.body?['dev_code']);
      }
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String login,
    required String password,
    required String role,
  }) async {
    final isEmail = login.contains('@');
    final r = await api.post('/auth/register', {
      'name': name.trim(),
      if (isEmail) 'email': login.trim() else 'phone': login.trim(),
      'password': password,
      'role': role,
      if (role == 'pro') 'job': 'Professionnel',
    });
    await _open(r);
  }

  Future<void> _open(dynamic r) async {
    await api.saveTokens(r['access_token'], r['refresh_token']);
    me = r['user'];
    online = true;
    await bootstrap();
  }

  void startDemo(String role) {
    online = false;
    demoRole = role;
    me = null;
    MockData.resetLive();
    notifyListeners();
  }

  Future<void> logout() async {
    await api.clearTokens();
    online = false;
    me = null;
    MockData.resetLive();
    notifyListeners();
  }

  Future<void> refreshMe() async {
    if (!online) return;
    me = await api.get('/auth/me');
    notifyListeners();
  }

  // ------------------------------------------------------------ données

  /// Charge tout ce dont les écrans ont besoin (appels en parallèle).
  Future<void> bootstrap() async {
    if (!online) return;
    loading = true;
    notifyListeners();
    await Future.wait([
      _safe(() async {
        final list = await api.get('/pros', query: {'limit': 100});
        MockData.pros = [for (final j in list) Mappers.pro(j)];
      }),
      _safe(_loadServices),
      _safe(refreshWallet),
    ]);
    // Dépendent des pros / services déjà chargés.
    await Future.wait([
      _safe(refreshFeed),
      _safe(refreshLives),
      _safe(refreshConversations),
      _safe(refreshOrders),
      _safe(refreshNotifications),
      if (isPro) _safe(refreshPro),
    ]);
    loading = false;
    notifyListeners();
  }

  Future<void> _loadServices() async {
    final list = await api.get('/services', query: {'limit': 100});
    final byPro = <String, List<Service>>{};
    for (final j in list) {
      byPro.putIfAbsent(j['pro_id'], () => []).add(Mappers.service(j));
    }
    if (isPro) {
      // Ses propres prestations, brouillons et pauses compris.
      final mine = await api.get('/pros/$userId/services');
      byPro[userId] = [for (final j in mine) Mappers.service(j)];
    }
    MockData.liveServices = byPro;
  }

  /// Mes prestations (brouillons et pauses compris) après une modification.
  Future<void> refreshMyServices() async {
    if (!online) return;
    final mine = await api.get('/pros/$userId/services');
    MockData.liveServices = {
      ...?MockData.liveServices,
      userId: [for (final j in mine) Mappers.service(j)],
    };
    notifyListeners();
  }

  Future<void> refreshFeed() async {
    final list = await api.get('/feed', query: {'limit': 50});
    MockData.liveFeed = [for (final j in list) Mappers.post(j)];
    notifyListeners();
  }

  Future<void> refreshLives() async {
    final list = await api.get('/lives', query: {'status': 'live,scheduled', 'limit': 50});
    MockData.liveLives = [for (final j in list) Mappers.live(j)];
    notifyListeners();
  }

  Future<void> refreshConversations() async {
    final active = await api.get('/chat/conversations');
    final archived = await api.get('/chat/conversations', query: {'archived': true});
    MockData.liveConversations = [
      for (final j in [...active, ...archived])
        if (Mappers.conversation(j, userId) case final c?) c,
    ];
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    final list = await api.get('/orders', query: {'limit': 100});
    MockData.liveOrders = [for (final j in list) Mappers.order(j)];
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    final list = await api.get('/notifications', query: {'limit': 50});
    MockData.liveNotifications = [for (final j in list) Mappers.notification(j)];
    notifyListeners();
  }

  Future<void> refreshWallet() async {
    final w = await api.get('/wallet');
    balanceXaf = w['balance_xaf'];
    escrowXaf = w['escrow_xaf'];
    withdrawableXaf = w['withdrawable_xaf'];
    twoFaRequired = w['two_fa_required'] ?? false;
    final tx = await api.get('/wallet/transactions', query: {'limit': 50});
    transactions = List<Map<String, dynamic>>.from(tx);
    notifyListeners();
  }

  Future<void> refreshPro() async {
    dashboard = await api.get('/pros/me/dashboard');
    quotes = List<Map<String, dynamic>>.from(await api.get('/quotes'));
    notifyListeners();
  }

  /// Rafraîchit ce qui a pu changer après une action (commande, paiement…).
  Future<void> afterMoneyAction() async {
    if (!online) return;
    await Future.wait([
      _safe(refreshWallet),
      _safe(refreshOrders),
      _safe(refreshNotifications),
      if (isPro) _safe(refreshPro),
    ]);
  }

  Future<void> _safe(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      debugPrint('Chargement partiel : $e');
    }
  }
}
