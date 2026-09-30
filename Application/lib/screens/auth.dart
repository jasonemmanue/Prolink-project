import 'package:flutter/material.dart';
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
                const _Field(label: 'Nom complet', icon: Icons.person_outline),
              ],
              const _Field(
                label: 'Email ou téléphone',
                icon: Icons.mail_outline,
              ),
              const _Field(
                label: 'Mot de passe',
                icon: Icons.lock_outline,
                obscure: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => _role == 'pro'
                            ? const ProShell()
                            : const HomeShell(),
                      ),
                    );
                  },
                  child: Text(_isSignUp ? 'Créer mon compte' : 'Se connecter'),
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
  const _Field({required this.label, required this.icon, this.obscure = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
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
