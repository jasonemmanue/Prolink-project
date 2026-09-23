import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _c = PageController();
  int _page = 0;
  final _pages = const [
    _P('Trouvez le bon pro', 'Avocats, chefs, développeurs, coachs — vérifiés et notés.',
        Icons.search),
    _P('Payez en toute sécurité', 'Séquestre (escrow) intégré + Mobile Money natif.',
        Icons.lock),
    _P('Suivez les lives', 'Masterclass, conseils et Q&A en direct.',
        Icons.podcasts),
    _P('Discutez et traduisez', 'Chat FR ⇄ EN traduit à la volée, à la Alibaba.',
        Icons.translate),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Align(
                  alignment: Alignment.centerLeft, child: AppLogo(size: 44)),
            ),
            Expanded(
              child: PageView.builder(
                controller: _c,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AuthScreen())),
                    child: const Text('Passer'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_page < _pages.length - 1) {
                        _c.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOut);
                      } else {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => const AuthScreen()));
                      }
                    },
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(_page < _pages.length - 1 ? 'Suivant' : 'Commencer'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _P extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _P(this.title, this.subtitle, this.icon);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 76, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4)),
        ],
      ),
    );
  }
}
