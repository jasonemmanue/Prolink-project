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
