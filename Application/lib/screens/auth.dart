import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_shell.dart';
import 'pro_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = true;
  String _role = 'client'; // client | pro
  bool _busy = false;
  final _name = TextEditingController();
  final _login = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  void _enter() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            Session.instance.isPro ? const ProShell() : const HomeShell(),
      ),
    );
  }

  Future<void> _submit({String? otp}) async {
    final login = _login.text.trim();
    final pwd = _password.text;
    if (login.isEmpty ||
        pwd.isEmpty ||
        (_isSignUp && _name.text.trim().length < 2)) {
      showInfo(context, 'Complétez tous les champs');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_isSignUp) {
        await Session.instance.register(
          name: _name.text,
          login: login,
          password: pwd,
          role: _role,
        );
      } else {
        await Session.instance.login(login, pwd, otp: otp);
      }
      if (mounted) _enter();
    } on TwoFactorRequired catch (e) {
      if (!mounted) return;
      final code = await _askOtp(e.devCode);
      if (code != null) return _submit(otp: code);
    } on ApiException catch (e) {
      if (mounted) _offerDemo(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askOtp(String? devCode) {
    final c = TextEditingController(text: devCode ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Double authentification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Saisissez le code à 6 chiffres reçu par SMS.'),
            if (devCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Mode développement : code pré-rempli',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 8),
              decoration: const InputDecoration(counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  /// Erreur réseau → proposer le mode démo ; erreur métier → message serveur.
  void _offerDemo(ApiException e) {
    if (e.status != 0) {
      showInfo(context, e.message);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Serveur injoignable'),
        content: Text(
          "${e.message}.\n\nVérifiez l'adresse du serveur ou continuez en "
          "mode démo (données d'exemple, rien n'est enregistré).",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _serverDialog();
            },
            child: const Text('Serveur…'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _demo();
            },
            child: const Text('Mode démo'),
          ),
        ],
      ),
    );
  }

  void _demo() {
    Session.instance.startDemo(_role);
    _enter();
  }

  Future<void> _serverDialog() async {
    final api = ApiClient.instance;
    final c = TextEditingController(text: api.baseUrl);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adresse du serveur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: c,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: "URL de l'API",
                hintText: 'http://192.168.1.10:8000',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Émulateur Android : http://10.0.2.2:8000\n'
              'Téléphone : adresse IP du PC sur le même Wi-Fi.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await api.setBaseUrl(c.text);
              final ok = await api.ping();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              showInfo(
                context,
                ok ? 'Serveur connecté ✔' : 'Serveur injoignable : ${api.baseUrl}',
              );
            },
            child: const Text('Tester & enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const AppLogo(size: 48),
              const SizedBox(height: 32),
              Text(
                _isSignUp ? 'Créer votre compte' : 'Bon retour',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Rejoignez la 1ʳᵉ marketplace sociale panafricaine des pros.'
                    : 'Ravi de vous revoir sur ProLink.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              if (_isSignUp) ...[
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        label: 'Je cherche',
                        subtitle: 'Internaute / Client',
                        icon: Icons.search,
                        selected: _role == 'client',
                        onTap: () => setState(() => _role = 'client'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        label: 'Je propose',
                        subtitle: 'Professionnel',
                        icon: Icons.work_outline,
                        selected: _role == 'pro',
                        onTap: () => setState(() => _role = 'pro'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _Field(
                  label: 'Nom complet',
                  icon: Icons.person_outline,
                  controller: _name,
                ),
              ],
              _Field(
                label: 'Email ou téléphone',
                icon: Icons.mail_outline,
                controller: _login,
                keyboard: TextInputType.emailAddress,
              ),
              _Field(
                label: 'Mot de passe',
                icon: Icons.lock_outline,
                obscure: true,
                controller: _password,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _submit(),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isSignUp ? 'Créer mon compte' : 'Se connecter'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('ou'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              _SocialButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Continuer avec Google',
                color: Colors.red,
              ),
              const SizedBox(height: 10),
              _SocialButton(
                icon: Icons.facebook,
                label: 'Continuer avec Facebook',
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp ? 'Déjà un compte ?' : 'Nouveau sur ProLink ?',
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(_isSignUp ? 'Se connecter' : "S'inscrire"),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _serverDialog,
                    icon: const Icon(Icons.dns_outlined, size: 18),
                    label: const Text('Serveur'),
                  ),
                  TextButton.icon(
                    onPressed: _demo,
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: const Text('Mode démo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? AppColors.primary.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboard;
  const _Field({
    required this.label,
    required this.icon,
    this.obscure = false,
    this.controller,
    this.keyboard,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connexion $label bientôt disponible')),
      ),
      icon: Icon(icon, color: color, size: 22),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
