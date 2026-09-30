import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'order_flow.dart';
import 'my_orders.dart';

class ServiceDetailScreen extends StatefulWidget {
  final Pro pro;
  final Service service;
  const ServiceDetailScreen({
    super.key,
    required this.pro,
    required this.service,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  int _variant = 1;

  /// Formules du serveur, ou Basic/Standard/Premium en démo.
  List<ServiceVariant> get _variants {
    final s = widget.service;
    if (s.variants.isNotEmpty) return s.variants;
    if (s.proId.isNotEmpty) return const []; // service API sans formules
    return [
      ServiceVariant('Basic', s.priceXaf),
      ServiceVariant('Standard', s.priceXaf * 2),
      ServiceVariant('Premium', s.priceXaf * 3),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final variants = _variants;
    if (_variant >= variants.length) _variant = variants.isEmpty ? 0 : variants.length - 1;
    final isQuote = widget.service.pricingType == 'quote';
    return Scaffold(
      appBar: AppBar(title: Text(widget.service.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Avatar(url: widget.pro.avatar, size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.pro.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              VerifiedBadge(level: widget.pro.verifiedLevel),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.service.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            widget.service.description,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(
                icon: Icons.timer,
                label: 'Durée : ${widget.service.duration}',
              ),
              Pill(icon: Icons.place, label: widget.service.modality),
              Pill(
                icon: Icons.policy,
                label: 'Annulation : ${widget.service.cancellation}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (variants.isEmpty)
            Row(children: [
              Text(
                isQuote ? 'Tarif sur devis' : 'Prix',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              if (!isQuote)
                Text(
                  formatXaf(widget.service.priceXaf),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
            ])
          else ...[
          const Text(
            'Choisissez votre formule',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(variants.length, (i) {
              final selected = _variant == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < variants.length - 1 ? 8 : 0),
                  child: InkWell(
                    onTap: () => setState(() => _variant = i),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.divider,
                          width: selected ? 2 : 1,
                        ),
                        color: selected
                            ? AppColors.primary.withOpacity(0.06)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            variants[i].name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatXaf(variants[i].priceXaf),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          ],
          const SizedBox(height: 24),
          _Section(
            title: 'Livrables',
            items: widget.service.deliverables.isNotEmpty
                ? widget.service.deliverables
                : const [
                    '3 versions du document',
                    'Support pendant 30 jours',
                    'Consultation de suivi',
                  ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Avis (24)',
            items: const [
              '★★★★★ — Rapide et professionnel',
              '★★★★★ — Excellent rapport qualité/prix',
              '★★★★☆ — Très bien, quelques petits détails',
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
      bottomSheet: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => pushScreen(
                    context,
                    QuoteRequestScreen(
                      pro: widget.pro,
                      service: widget.service,
                    ),
                  ),
                  icon: const Icon(Icons.request_quote_outlined),
                  label: const Text('Demander un devis'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isQuote
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderFlowScreen(
                              pro: widget.pro,
                              service: widget.service,
                              variant: variants.isEmpty ? null : variants[_variant],
                            ),
                          ),
                        ),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Commander'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> items;
  const _Section({required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 6),
        ...items.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                const Icon(Icons.check, size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(child: Text(e)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
