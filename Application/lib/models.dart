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
  const Post({
    required this.id,
    required this.author,
    required this.text,
    required this.images,
    required this.date,
    required this.likes,
    required this.comments,
    this.sponsored = false,
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
  const Service({
    required this.id,
    required this.title,
    required this.description,
    required this.priceXaf,
    required this.pricingType,
    required this.duration,
    required this.modality,
    required this.cancellation,
  });
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
  const Conversation({
    required this.id,
    required this.peer,
    required this.messages,
  });
}

/// Cycle de vie d'une commande escrow (cf. annexe C.1 du cahier des charges).
enum OrderStatus { pending, inProgress, delivered, completed, disputed }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'En attente',
    OrderStatus.inProgress => 'En cours',
    OrderStatus.delivered => 'Livrée',
    OrderStatus.completed => 'Terminée',
    OrderStatus.disputed => 'Litige',
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
  });

  /// Commission plateforme de 10 % sur les prestations.
  int get commissionXaf => (amountXaf * 0.10).round();
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
