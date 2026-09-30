class Pro {
  final String id;
  final String name;
  final String job;
  final String category;
  final String city;
  final String avatar;
  final String cover;
  final double rating;
  final int followers;
  final int verifiedLevel; // 0..3
  final String bio;
  final List<String> languages;
  const Pro({
    required this.id,
    required this.name,
    required this.job,
    required this.category,
    required this.city,
    required this.avatar,
    required this.cover,
    required this.rating,
    required this.followers,
    required this.verifiedLevel,
    required this.bio,
    required this.languages,
  });
}

class Post {
  final String id;
  final Pro author;
  final String text;
  final List<String> images;
  final DateTime date;
  final int likes;
  final int comments;
  final bool sponsored;
  final bool liked;
  final bool saved;
  final String kind;
  const Post({
    required this.id,
    required this.author,
    required this.text,
    required this.images,
    required this.date,
    required this.likes,
    required this.comments,
    this.sponsored = false,
    this.liked = false,
    this.saved = false,
    this.kind = 'text',
  });
}

class Service {
  final String id;
  final String title;
  final String description;
  final int priceXaf;
  final String pricingType; // fixed, from, quote, hourly, monthly
  final String duration;
  final String modality; // remote, on-site, mixed
  final String cancellation; // flexible, standard, strict
  final List<ServiceVariant> variants; // Basic / Standard / Premium
  final List<String> deliverables;
  final String status; // active, draft, paused
  final String proId;
  const Service({
    required this.id,
    required this.title,
    required this.description,
    required this.priceXaf,
    required this.pricingType,
    required this.duration,
    required this.modality,
    required this.cancellation,
    this.variants = const [],
    this.deliverables = const [],
    this.status = 'active',
    this.proId = '',
  });
}

class ServiceVariant {
  final String name;
  final int priceXaf;
  const ServiceVariant(this.name, this.priceXaf);
}

class LiveEvent {
  final String id;
  final String title;
  final String pro;
  final String cover;
  final bool isLive;
  final bool paying;
  final int priceXaf;
  final int viewers;
  final DateTime startAt;
  final String proId;
  final String mode; // free, followers, paid, tips
  final String status; // scheduled, live, ended
  final bool hasAccess;
  const LiveEvent({
    required this.id,
    required this.title,
    required this.pro,
    required this.cover,
    required this.isLive,
    required this.paying,
    required this.priceXaf,
    required this.viewers,
    required this.startAt,
    this.proId = '',
    this.mode = 'free',
    this.status = 'scheduled',
    this.hasAccess = true,
  });
}

class ChatMessage {
  final String id;
  final String authorId;
  final String text;
  final DateTime at;
  final String? translated;
  final bool fromMe;
  const ChatMessage({
    required this.id,
    required this.authorId,
    required this.text,
    required this.at,
    this.translated,
    this.fromMe = false,
  });
}

class Conversation {
  final String id;
  final Pro peer;
  final List<ChatMessage> messages;
  final int unread;
  final bool online;
  final bool archived;
  const Conversation({
    required this.id,
    required this.peer,
    required this.messages,
    this.unread = 0,
    this.online = false,
    this.archived = false,
  });
}

/// Cycle de vie d'une commande escrow (cf. annexe C.1 du cahier des charges).
enum OrderStatus { pending, inProgress, delivered, completed, disputed, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'En attente',
    OrderStatus.inProgress => 'En cours',
    OrderStatus.delivered => 'Livrée',
    OrderStatus.completed => 'Terminée',
    OrderStatus.disputed => 'Litige',
    OrderStatus.cancelled => 'Annulée',
  };
}

class Order {
  final String id;
  final Pro pro;
  final String clientName;
  final Service service;
  final String variant;
  final int amountXaf;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime deadline;
  final String? _code;
  final int? _commission;
  final String? brief;
  final String? deliveryMessage;
  final bool reviewed;
  final String paymentMethod; // wallet | mtn | orange | card
  const Order({
    required this.id,
    required this.pro,
    required this.clientName,
    required this.service,
    required this.variant,
    required this.amountXaf,
    required this.status,
    required this.createdAt,
    required this.deadline,
    String? code,
    int? commissionXaf,
    this.brief,
    this.deliveryMessage,
    this.reviewed = false,
    this.paymentMethod = 'mtn',
  })  : _code = code,
        _commission = commissionXaf;

  /// Numéro lisible (PL-xxxxx). En démo, l'id sert de numéro.
  String get code => _code ?? id;

  /// Commission plateforme (10 % par défaut, valeur serveur si connue).
  int get commissionXaf => _commission ?? (amountXaf * 0.10).round();
  int get netXaf => amountXaf - commissionXaf;
}

class AppNotification {
  final String id;
  final String kind; // order, live, message, follow, payment, review, system
  final String title;
  final String body;
  final DateTime at;
  final bool read;
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.read = false,
  });
}
