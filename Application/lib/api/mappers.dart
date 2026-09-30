import '../data.dart';
import '../models.dart';

/// Conversion JSON (API FastAPI) → modèles de l'app.
class Mappers {
  static const _defaultCover =
      'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200';

  static DateTime date(dynamic v) =>
      v == null ? DateTime.now() : DateTime.parse(v as String).toLocal();

  static Pro pro(Map<String, dynamic> j) => Pro(
    id: j['id'],
    name: j['name'] ?? '',
    job: j['job'] ?? '',
    category: j['category'] ?? '',
    city: j['city'] ?? '',
    avatar: j['avatar_url'] ?? '',
    cover: j['cover_url'] ?? _defaultCover,
    rating: (j['rating'] as num?)?.toDouble() ?? 0,
    followers: j['followers_count'] ?? 0,
    verifiedLevel: j['verified_level'] ?? 0,
    bio: j['bio'] ?? '',
    languages: List<String>.from(j['languages'] ?? const ['FR']),
  );

  /// Résumé d'utilisateur (auteur, pair de conversation) → Pro complet si connu.
  static Pro user(Map<String, dynamic>? j) {
    if (j == null) return MockData.unknownPro;
    final known = MockData.pros.where((p) => p.id == j['id']);
    if (known.isNotEmpty) return known.first;
    return Pro(
      id: j['id'],
      name: j['name'] ?? '',
      job: j['job'] ?? (j['role'] == 'client' ? 'Internaute' : ''),
      category: '',
      city: j['city'] ?? '',
      avatar: j['avatar_url'] ?? '',
      cover: _defaultCover,
      rating: 0,
      followers: 0,
      verifiedLevel: j['verified_level'] ?? 0,
      bio: '',
      languages: const ['FR'],
    );
  }

  static Post post(Map<String, dynamic> j) => Post(
    id: j['id'],
    author: user(j['author']),
    text: j['text'] ?? '',
    images: List<String>.from(j['images'] ?? const []),
    date: date(j['created_at']),
    likes: j['likes_count'] ?? 0,
    comments: j['comments_count'] ?? 0,
    sponsored: j['sponsored'] ?? false,
    liked: j['liked'] ?? false,
    saved: j['saved'] ?? false,
    kind: j['kind'] ?? 'text',
  );

  static Service service(Map<String, dynamic> j) => Service(
    id: j['id'],
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    priceXaf: j['price_xaf'] ?? 0,
    pricingType: j['pricing_type'] ?? 'fixed',
    duration: j['duration'] ?? '',
    modality: j['modality'] ?? '',
    cancellation: j['cancellation'] ?? 'Standard',
    variants: [
      for (final v in (j['variants'] as List? ?? const []))
        ServiceVariant(v['name'], v['price_xaf'] ?? 0),
    ],
    deliverables: List<String>.from(j['deliverables'] ?? const []),
    status: j['status'] ?? 'active',
    proId: j['pro_id'] ?? '',
  );

  static LiveEvent live(Map<String, dynamic> j) => LiveEvent(
    id: j['id'],
    title: j['title'] ?? '',
    pro: (j['pro'] as Map?)?['name'] ?? '',
    proId: (j['pro'] as Map?)?['id'] ?? '',
    cover: j['cover_url'] ?? _defaultCover,
    isLive: j['status'] == 'live',
    paying: j['paying'] ?? false,
    priceXaf: j['price_xaf'] ?? 0,
    viewers: j['viewers'] ?? 0,
    startAt: date(j['started_at'] ?? j['scheduled_at']),
    mode: j['mode'] ?? 'free',
    status: j['status'] ?? 'scheduled',
    hasAccess: j['has_access'] ?? false,
  );

  static OrderStatus orderStatus(String s) => switch (s) {
    'in_progress' => OrderStatus.inProgress,
    'delivered' => OrderStatus.delivered,
    'completed' => OrderStatus.completed,
    'disputed' => OrderStatus.disputed,
    'cancelled' => OrderStatus.cancelled,
    _ => OrderStatus.pending, // pending | awaiting_payment
  };

  static Order order(Map<String, dynamic> j) {
    final amount = j['amount_xaf'] as int? ?? 0;
    final svc = MockData.serviceById(j['service_id']) ??
        Service(
          id: j['service_id'] ?? j['id'],
          title: j['title'] ?? 'Prestation',
          description: j['brief'] ?? '',
          priceXaf: amount,
          pricingType: 'fixed',
          duration: '',
          modality: '',
          cancellation: 'Standard',
        );
    final created = date(j['created_at']);
    return Order(
      id: j['id'],
      code: j['code'],
      pro: user(j['pro']),
      clientName: (j['client'] as Map?)?['name'] ?? '',
      service: svc,
      variant: j['variant'] ?? 'Standard',
      amountXaf: amount,
      commissionXaf: j['commission_xaf'],
      status: orderStatus(j['status'] ?? 'pending'),
      createdAt: created,
      deadline: j['deadline'] == null
          ? created.add(const Duration(days: 14))
          : date(j['deadline']),
      brief: j['brief'],
      deliveryMessage: j['delivery_message'],
      reviewed: j['reviewed'] ?? false,
      paymentMethod: j['payment_method'] ?? 'wallet',
    );
  }

  static ChatMessage message(Map<String, dynamic> j, String meId) => ChatMessage(
    id: j['id'],
    authorId: j['author_id'],
    text: j['text'] ?? '',
    at: date(j['created_at']),
    fromMe: j['author_id'] == meId,
  );

  static Conversation? conversation(Map<String, dynamic> j, String meId) {
    if (j['kind'] != 'direct' || j['peer'] == null) return null;
    final last = j['last_message'] as Map<String, dynamic>?;
    return Conversation(
      id: j['id'],
      peer: user(j['peer']),
      messages: [
        if (last != null) message(last, meId)
        else ChatMessage(id: 'empty', authorId: '', text: 'Nouvelle conversation', at: date(j['created_at'])),
      ],
      unread: j['unread'] ?? 0,
      online: j['online'] ?? false,
      archived: j['archived'] ?? false,
    );
  }

  static AppNotification notification(Map<String, dynamic> j) => AppNotification(
    id: j['id'],
    kind: j['kind'] ?? 'system',
    title: j['title'] ?? '',
    body: j['body'] ?? '',
    at: date(j['created_at']),
    read: j['read'] ?? false,
  );
}
