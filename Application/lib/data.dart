import 'models.dart';

/// Jeu de données de démonstration. Assez fourni pour que chaque écran
/// ressemble à une application en production (listes pleines, noms réels,
/// statuts variés). À remplacer par les appels HTTP vers `Api/`.
class MockData {
  // Portraits, couvertures et posts : Unsplash (CORS OK, web + mobile).
  static String _photo(String id) =>
      'https://images.unsplash.com/photo-$id?w=400&h=400&fit=crop&crop=faces';

  static const String _cov1 =
      'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200';
  static const String _cov2 =
      'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=1200';
  static const String _imgLaw =
      'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=900';
  static const String _imgFood1 =
      'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=900';
  static const String _imgFood2 =
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900';
  static const String _imgFood3 =
      'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?w=900';
  static const String _imgSport =
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=900';

  /// Avatar de l'utilisateur connecté (internaute de démo).
  static final String meAvatar = _photo('1500648767791-00dcc994a43e');

  static List<Pro> pros = List.of(_demoPros);

  static final List<Pro> _demoPros = [
    Pro(
      id: 'p1',
      name: 'Me. Aïcha Nkomo',
      job: 'Avocate d\'affaires',
      category: 'Droit & Justice',
      city: 'Douala',
      avatar: _photo('1573497019940-1c28c88b4f3e'),
      cover: _cov1,
      rating: 4.9,
      followers: 2431,
      verifiedLevel: 3,
      bio:
          'Avocate au barreau du Cameroun, 12 ans d\'expérience. Contrats commerciaux, création de SARL, contentieux.',
      languages: ['FR', 'EN'],
    ),
    Pro(
      id: 'p2',
      name: 'Chef Landry Mbappé',
      job: 'Chef cuisinier',
      category: 'Gastronomie & Événementiel',
      city: 'Yaoundé',
      avatar: _photo('1522529599102-193c0d76b5b6'),
      cover: _cov2,
      rating: 4.8,
      followers: 1820,
      verifiedLevel: 2,
      bio:
          'Chef spécialisé en cuisine fusion. Traiteur pour événements privés, mariages, séminaires.',
      languages: ['FR'],
    ),
    Pro(
      id: 'p3',
      name: 'Ing. Franck Talla',
      job: 'Développeur mobile',
      category: 'Digital & Tech',
      city: 'Douala',
      avatar: _photo('1531384441138-2736e62e0919'),
      cover: _cov1,
      rating: 4.7,
      followers: 987,
      verifiedLevel: 1,
      bio:
          'Développeur Flutter/React, 6 ans XP. Apps sur-mesure pour PME africaines.',
      languages: ['FR', 'EN'],
    ),
    Pro(
      id: 'p4',
      name: 'Dr. Muna Etienne',
      job: 'Coach sportif certifié',
      category: 'Santé & Bien-être',
      city: 'Yaoundé',
      avatar: _photo('1531123897727-8f129e1688ce'),
      cover: _cov2,
      rating: 5.0,
      followers: 3122,
      verifiedLevel: 2,
      bio:
          'Coach sportif diplômé. Programmes personnalisés en présentiel ou visio.',
      languages: ['FR', 'EN'],
    ),
    Pro(
      id: 'p5',
      name: 'Arch. Paul Essomba',
      job: 'Architecte DPLG',
      category: 'Ingénierie & Bâtiment',
      city: 'Douala',
      avatar: _photo('1560250097-0b93528c311a'),
      cover: _cov2,
      rating: 4.6,
      followers: 1204,
      verifiedLevel: 2,
      bio:
          'Plans de villas et immeubles R+4, permis de bâtir, suivi de chantier à Douala et Kribi.',
      languages: ['FR', 'EN'],
    ),
    Pro(
      id: 'p6',
      name: 'Nadège Fotso',
      job: 'Expert-comptable',
      category: 'Finance & Comptabilité',
      city: 'Yaoundé',
      avatar: _photo('1573496359142-b8d87734a5a2'),
      cover: _cov1,
      rating: 4.8,
      followers: 864,
      verifiedLevel: 1,
      bio:
          'Tenue comptable OHADA, déclarations DGI, business plans pour PME et startups.',
      languages: ['FR'],
    ),
    Pro(
      id: 'p7',
      name: 'Sandrine Mbida',
      job: 'Maquilleuse & coiffeuse',
      category: 'Beauté & Mode',
      city: 'Douala',
      avatar: _photo('1507152832244-10d45c7eda57'),
      cover: _cov2,
      rating: 4.9,
      followers: 4510,
      verifiedLevel: 2,
      bio:
          'Maquillage mariée, tresses et coiffures afro. Déplacement à domicile.',
      languages: ['FR', 'EN'],
    ),
    Pro(
      id: 'p8',
      name: 'Prof. Hervé Ngono',
      job: 'Professeur de mathématiques',
      category: 'Éducation & Formation',
      city: 'Bafoussam',
      avatar: _photo('1519085360753-af0119f7cbe7'),
      cover: _cov1,
      rating: 4.7,
      followers: 639,
      verifiedLevel: 1,
      bio:
          'Cours de maths et physique, préparation Probatoire, BAC et concours d\'entrée.',
      languages: ['FR', 'EN'],
    ),
    Pro(
      id: 'p9',
      name: 'Ibrahim Moussa',
      job: 'Menuisier ébéniste',
      category: 'Artisanat',
      city: 'Garoua',
      avatar: _photo('1506794778202-cad84cf45f1d'),
      cover: _cov2,
      rating: 4.5,
      followers: 412,
      verifiedLevel: 1,
      bio: 'Meubles sur mesure en bois massif (iroko, sapelli). Livraison.',
      languages: ['FR'],
    ),
    Pro(
      id: 'p10',
      name: 'Grace Eyenga',
      job: 'Consultante marketing',
      category: 'Conseil & Business',
      city: 'Douala',
      avatar: _photo('1494790108377-be9c29b29330'),
      cover: _cov1,
      rating: 4.8,
      followers: 1733,
      verifiedLevel: 3,
      bio:
          'Stratégie de marque, réseaux sociaux et lancement produit pour marques africaines.',
      languages: ['FR', 'EN'],
    ),
  ];

  static Pro proById(String id) => pros.firstWhere((p) => p.id == id);

  // ------------------------------------------------------------------
  // Données chargées depuis l'API (null = mode démo, données ci-dessous).
  static List<Post>? liveFeed;
  static Map<String, List<Service>>? liveServices;
  static List<LiveEvent>? liveLives;
  static List<Conversation>? liveConversations;
  static List<Order>? liveOrders;
  static List<AppNotification>? liveNotifications;

  static void resetLive() {
    pros = List.of(_demoPros);
    liveFeed = null;
    liveServices = null;
    liveLives = null;
    liveConversations = null;
    liveOrders = null;
    liveNotifications = null;
  }

  static Service? serviceById(String? id) {
    if (id == null) return null;
    final all = liveServices?.values ?? _services.values;
    for (final list in all) {
      for (final s in list) {
        if (s.id == id) return s;
      }
    }
    return null;
  }

  /// Pro de repli quand un auteur n'est pas encore chargé.
  static final Pro unknownPro = Pro(
    id: '',
    name: 'Utilisateur ProLink',
    job: '',
    category: '',
    city: '',
    avatar: '',
    cover: _cov1,
    rating: 0,
    followers: 0,
    verifiedLevel: 0,
    bio: '',
    languages: const ['FR'],
  );

  static List<Post> feed() => liveFeed ?? _demoFeed();

  static List<Post> _demoFeed() {
    final now = DateTime.now();
    return [
      Post(
        id: 'po1',
        author: pros[0],
        text:
            'Nouveau : accompagnement complet pour la création d\'une SARL au Cameroun. 3 formules, prix affichés.',
        images: const [_imgLaw],
        date: now.subtract(const Duration(hours: 2)),
        likes: 128,
        comments: 14,
        sponsored: true,
      ),
      Post(
        id: 'po2',
        author: pros[1],
        text:
            'Retour sur le buffet du mariage Kono ce week-end. Merci aux mariés pour leur confiance !',
        images: const [_imgFood1, _imgFood2],
        date: now.subtract(const Duration(hours: 5)),
        likes: 302,
        comments: 41,
      ),
      Post(
        id: 'po3',
        author: pros[6],
        text:
            'Maquillage mariée + coiffure pour Estelle samedi à Bonapriso 💄 Il me reste 2 dates libres en décembre, réservez vite !',
        images: const [],
        date: now.subtract(const Duration(hours: 7)),
        likes: 518,
        comments: 63,
      ),
      Post(
        id: 'po4',
        author: pros[2],
        text:
            'Astuce du jour : 3 erreurs à éviter quand on publie sa première app sur le Play Store.\n\n1. Oublier la politique de confidentialité\n2. Des captures d\'écran floues\n3. Ne pas tester sur un petit téléphone',
        images: const [],
        date: now.subtract(const Duration(hours: 11)),
        likes: 91,
        comments: 22,
      ),
      Post(
        id: 'po5',
        author: pros[3],
        text:
            'Live demain à 18h : « Le HIIT à la maison — 20 min chrono ». Cloche activée = notification.',
        images: const [_imgSport],
        date: now.subtract(const Duration(hours: 16)),
        likes: 210,
        comments: 33,
      ),
      Post(
        id: 'po6',
        author: pros[5],
        text:
            'Rappel : la déclaration statistique et fiscale (DSF) est due au 15 mars. Je prends encore 5 PME ce trimestre.',
        images: const [],
        date: now.subtract(const Duration(hours: 20)),
        likes: 76,
        comments: 9,
      ),
      Post(
        id: 'po7',
        author: pros[1],
        text:
            'Masterclass cuisine fusion ce samedi en live payant : ndolé revisité et plantain caramélisé.',
        images: const [_imgFood3],
        date: now.subtract(const Duration(days: 1, hours: 3)),
        likes: 187,
        comments: 27,
      ),
      Post(
        id: 'po8',
        author: pros[4],
        text:
            'Livraison d\'une villa R+1 à Kribi : 4 chambres, toiture végétalisée, 7 mois de chantier. Merci à toute l\'équipe !',
        images: const [_cov2],
        date: now.subtract(const Duration(days: 2)),
        likes: 344,
        comments: 38,
      ),
    ];
  }

  static const Map<String, List<Service>> _services = {
    'p1': [
      Service(
        id: 's1',
        title: 'Consultation juridique 30 min',
        description:
            'Entretien téléphonique ou en visio pour analyser votre situation.',
        priceXaf: 15000,
        pricingType: 'fixed',
        duration: '30 min',
        modality: 'À distance',
        cancellation: 'Flexible',
      ),
      Service(
        id: 's2',
        title: 'Création de SARL — Pack complet',
        description: 'Statuts, immatriculation, ouverture bancaire.',
        priceXaf: 250000,
        pricingType: 'from',
        duration: '2 semaines',
        modality: 'Mixte',
        cancellation: 'Standard',
      ),
      Service(
        id: 's3',
        title: 'Contentieux commercial',
        description: 'Assistance juridique et représentation.',
        priceXaf: 0,
        pricingType: 'quote',
        duration: 'Variable',
        modality: 'Mixte',
        cancellation: 'Stricte',
      ),
      Service(
        id: 's3b',
        title: 'Rédaction de contrat commercial',
        description: 'Contrat de prestation, bail, CGV ou pacte d\'associés.',
        priceXaf: 75000,
        pricingType: 'fixed',
        duration: '5 jours',
        modality: 'À distance',
        cancellation: 'Standard',
      ),
      Service(
        id: 's3c',
        title: 'Conseil juridique mensuel',
        description: 'Abonnement PME : questions illimitées + 1 RDV/mois.',
        priceXaf: 60000,
        pricingType: 'monthly',
        duration: 'Mensuel',
        modality: 'À distance',
        cancellation: 'Flexible',
      ),
    ],
    'p2': [
      Service(
        id: 's4',
        title: 'Cours particulier de cuisine',
        description: '1h30 chez vous, 4 plats emblématiques.',
        priceXaf: 25000,
        pricingType: 'fixed',
        duration: '1h30',
        modality: 'Sur site',
        cancellation: 'Standard',
      ),
      Service(
        id: 's5',
        title: 'Traiteur événement 50 personnes',
        description: 'Menu 3 services, service inclus.',
        priceXaf: 750000,
        pricingType: 'from',
        duration: '1 journée',
        modality: 'Sur site',
        cancellation: 'Stricte',
      ),
    ],
    'p3': [
      Service(
        id: 's6',
        title: 'App mobile MVP Flutter',
        description: '4 écrans, backend simple, publication stores.',
        priceXaf: 900000,
        pricingType: 'from',
        duration: '4 semaines',
        modality: 'À distance',
        cancellation: 'Standard',
      ),
      Service(
        id: 's6b',
        title: 'Audit d\'application existante',
        description: 'Performance, sécurité et qualité du code. Rapport PDF.',
        priceXaf: 150000,
        pricingType: 'fixed',
        duration: '1 semaine',
        modality: 'À distance',
        cancellation: 'Flexible',
      ),
    ],
    'p4': [
      Service(
        id: 's7',
        title: 'Coaching HIIT 4 semaines',
        description: 'Programme + 4 séances live/mois.',
        priceXaf: 30000,
        pricingType: 'fixed',
        duration: '4 semaines',
        modality: 'À distance',
        cancellation: 'Flexible',
      ),
      Service(
        id: 's7b',
        title: 'Séance individuelle à domicile',
        description: '1 h de coaching personnalisé, matériel fourni.',
        priceXaf: 10000,
        pricingType: 'hourly',
        duration: '1 h',
        modality: 'Sur site',
        cancellation: 'Flexible',
      ),
    ],
    'p5': [
      Service(
        id: 's8',
        title: 'Plans de villa + permis de bâtir',
        description: 'Esquisse, plans d\'exécution, dossier de permis.',
        priceXaf: 1200000,
        pricingType: 'from',
        duration: '6 semaines',
        modality: 'Mixte',
        cancellation: 'Standard',
      ),
      Service(
        id: 's8b',
        title: 'Visite conseil de terrain',
        description: 'Étude de faisabilité sur site avant achat ou construction.',
        priceXaf: 50000,
        pricingType: 'fixed',
        duration: '½ journée',
        modality: 'Sur site',
        cancellation: 'Flexible',
      ),
    ],
    'p6': [
      Service(
        id: 's9',
        title: 'Tenue comptable PME',
        description: 'Saisie, rapprochements, états financiers OHADA.',
        priceXaf: 80000,
        pricingType: 'monthly',
        duration: 'Mensuel',
        modality: 'À distance',
        cancellation: 'Standard',
      ),
      Service(
        id: 's9b',
        title: 'Business plan bancable',
        description: 'Étude de marché, prévisionnel 3 ans, pitch deck.',
        priceXaf: 200000,
        pricingType: 'fixed',
        duration: '2 semaines',
        modality: 'À distance',
        cancellation: 'Standard',
      ),
    ],
    'p7': [
      Service(
        id: 's10',
        title: 'Maquillage mariée',
        description: 'Essai + jour J, retouches incluses.',
        priceXaf: 60000,
        pricingType: 'fixed',
        duration: '3 h',
        modality: 'Sur site',
        cancellation: 'Stricte',
      ),
      Service(
        id: 's10b',
        title: 'Tresses & coiffure afro',
        description: 'Knotless, nattes collées, vanilles.',
        priceXaf: 15000,
        pricingType: 'from',
        duration: '2 à 5 h',
        modality: 'Sur site',
        cancellation: 'Flexible',
      ),
    ],
    'p8': [
      Service(
        id: 's11',
        title: 'Cours de maths — niveau lycée',
        description: 'Séances de 2 h, exercices corrigés, suivi des notes.',
        priceXaf: 5000,
        pricingType: 'hourly',
        duration: '2 h',
        modality: 'Mixte',
        cancellation: 'Flexible',
      ),
    ],
    'p9': [
      Service(
        id: 's12',
        title: 'Meuble sur mesure',
        description: 'Dressing, cuisine, bibliothèque en bois massif.',
        priceXaf: 0,
        pricingType: 'quote',
        duration: '3 à 6 semaines',
        modality: 'Sur site',
        cancellation: 'Standard',
      ),
    ],
    'p10': [
      Service(
        id: 's13',
        title: 'Stratégie réseaux sociaux',
        description: 'Audit, ligne éditoriale, calendrier 3 mois.',
        priceXaf: 180000,
        pricingType: 'fixed',
        duration: '10 jours',
        modality: 'À distance',
        cancellation: 'Standard',
      ),
      Service(
        id: 's13b',
        title: 'Community management',
        description: '12 publications/mois + modération + reporting.',
        priceXaf: 120000,
        pricingType: 'monthly',
        duration: 'Mensuel',
        modality: 'À distance',
        cancellation: 'Flexible',
      ),
    ],
  };

  static List<Service> servicesOf(Pro p) => liveServices != null
      ? (liveServices![p.id] ?? const [])
      : (_services[p.id] ?? _services['p1']!);

  static List<LiveEvent> lives() => liveLives ?? _demoLives();

  static List<LiveEvent> _demoLives() {
    final now = DateTime.now();
    return [
      LiveEvent(
        id: 'l1',
        title: 'Créer sa SARL en 3 étapes',
        pro: pros[0].name,
        cover: _cov1,
        isLive: true,
        paying: true,
        priceXaf: 2000,
        viewers: 143,
        startAt: now,
      ),
      LiveEvent(
        id: 'l4',
        title: 'Tresses knotless : tuto pas à pas',
        pro: pros[6].name,
        cover: _cov2,
        isLive: true,
        paying: false,
        priceXaf: 0,
        viewers: 612,
        startAt: now,
      ),
      LiveEvent(
        id: 'l2',
        title: 'Masterclass cuisine fusion',
        pro: pros[1].name,
        cover: _imgFood3,
        isLive: false,
        paying: true,
        priceXaf: 5000,
        viewers: 0,
        startAt: now.add(const Duration(days: 1, hours: 4)),
      ),
      LiveEvent(
        id: 'l3',
        title: 'HIIT à la maison — 20 min',
        pro: pros[3].name,
        cover: _imgSport,
        isLive: false,
        paying: false,
        priceXaf: 0,
        viewers: 0,
        startAt: now.add(const Duration(hours: 18)),
      ),
      LiveEvent(
        id: 'l5',
        title: 'Préparer le BAC : méthode en 30 jours',
        pro: pros[7].name,
        cover: _cov1,
        isLive: false,
        paying: true,
        priceXaf: 1500,
        viewers: 0,
        startAt: now.add(const Duration(days: 3)),
      ),
    ];
  }

  static List<Conversation> conversations() =>
      liveConversations ?? _demoConversations();

  static List<Conversation> _demoConversations() {
    final now = DateTime.now();
    ChatMessage m(String id, String author, String text, Duration ago,
            {bool me = false}) =>
        ChatMessage(
            id: id,
            authorId: author,
            text: text,
            at: now.subtract(ago),
            fromMe: me);
    return [
      Conversation(
        id: 'c1',
        peer: pros[0],
        unread: 2,
        online: true,
        messages: [
          m('m1', 'p1', 'Bonjour, comment puis-je vous aider ?',
              const Duration(minutes: 45)),
          m('m2', 'me', 'Hello, I need a quote for creating a SARL.',
              const Duration(minutes: 40),
              me: true),
          m('m3', 'p1', 'Je vous envoie le pack complet en pièce jointe.',
              const Duration(minutes: 30)),
        ],
      ),
      Conversation(
        id: 'c2',
        peer: pros[6],
        unread: 1,
        online: true,
        messages: [
          m('m5', 'p7', 'Samedi 14h c\'est bon pour l\'essai maquillage ✨',
              const Duration(hours: 1)),
        ],
      ),
      Conversation(
        id: 'c3',
        peer: pros[2],
        messages: [
          m('m4', 'p3', 'Ok, on part sur 4 écrans + auth Firebase ?',
              const Duration(hours: 3)),
        ],
      ),
      Conversation(
        id: 'c4',
        peer: pros[1],
        online: true,
        messages: [
          m('m6', 'me', 'Parfait, 50 couverts pour le 12 décembre.',
              const Duration(hours: 6),
              me: true),
        ],
      ),
      Conversation(
        id: 'c5',
        peer: pros[5],
        unread: 3,
        messages: [
          m('m7', 'p6', 'Il me manque vos relevés bancaires d\'octobre.',
              const Duration(hours: 9)),
        ],
      ),
      Conversation(
        id: 'c6',
        peer: pros[4],
        messages: [
          m('m8', 'p5', 'Les plans modifiés sont prêts, on valide jeudi ?',
              const Duration(days: 1)),
        ],
      ),
      Conversation(
        id: 'c7',
        peer: pros[3],
        messages: [
          m('m9', 'me', 'Merci coach, séance top aujourd\'hui 💪',
              const Duration(days: 2),
              me: true),
        ],
      ),
      Conversation(
        id: 'c8',
        peer: pros[8],
        archived: true,
        messages: [
          m('m10', 'p9', 'Le dressing a été livré, bonne installation !',
              const Duration(days: 12)),
        ],
      ),
    ];
  }

  static const List<String> categories = [
    'Droit & Justice',
    'Ingénierie & Bâtiment',
    'Digital & Tech',
    'Santé & Bien-être',
    'Éducation & Formation',
    'Gastronomie & Événementiel',
    'Beauté & Mode',
    'Finance & Comptabilité',
    'Artisanat',
    'Conseil & Business',
    'Culture & Arts',
    'Autres services',
  ];

  /// Clients de démo (côté pro) : noms réalistes pour l'historique.
  static const List<String> clients = [
    'Emmanuel Sakam',
    'Grace Fotso',
    'Paul Ndongo',
    'Brice Ewane',
    'Estelle Kamga',
    'Yannick Onana',
    'Mireille Tchoupo',
    'Serge Abena',
  ];

  static List<Order> orders() => liveOrders ?? _demoOrders();

  static List<Order> _demoOrders() {
    final now = DateTime.now();
    Order o(String id, int pro, int svc, String variant, int amount,
            OrderStatus st, int ageDays, int dueDays,
            {String client = 'Emmanuel Sakam'}) =>
        Order(
          id: id,
          pro: pros[pro],
          clientName: client,
          service: servicesOf(pros[pro])[svc],
          variant: variant,
          amountXaf: amount,
          status: st,
          createdAt: now.subtract(Duration(days: ageDays)),
          deadline: now.add(Duration(days: dueDays)),
        );
    return [
      o('PL-10421', 0, 0, 'Standard', 15000, OrderStatus.pending, 0, 2),
      o('PL-10420', 0, 3, 'Premium', 75000, OrderStatus.pending, 1, 5,
          client: 'Estelle Kamga'),
      o('PL-10418', 0, 1, 'Premium', 250000, OrderStatus.inProgress, 3, 11,
          client: 'Grace Fotso'),
      o('PL-10416', 0, 4, 'Standard', 60000, OrderStatus.inProgress, 4, 26,
          client: 'Yannick Onana'),
      o('PL-10412', 0, 0, 'Basic', 15000, OrderStatus.inProgress, 2, 1,
          client: 'Mireille Tchoupo'),
      o('PL-10405', 1, 0, 'Basic', 25000, OrderStatus.delivered, 6, -1),
      o('PL-10399', 0, 3, 'Standard', 75000, OrderStatus.delivered, 8, -2,
          client: 'Serge Abena'),
      o('PL-10388', 3, 0, 'Standard', 30000, OrderStatus.completed, 20, -10,
          client: 'Paul Ndongo'),
      o('PL-10381', 0, 0, 'Standard', 15000, OrderStatus.completed, 25, -20,
          client: 'Grace Fotso'),
      o('PL-10377', 0, 1, 'Standard', 250000, OrderStatus.disputed, 28, -3,
          client: 'Brice Ewane'),
      o('PL-10370', 2, 0, 'Basic', 900000, OrderStatus.completed, 40, -15),
    ];
  }

  static List<AppNotification> notifications() =>
      liveNotifications ?? _demoNotifications();

  static List<AppNotification> _demoNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
          id: 'n1',
          kind: 'live',
          title: 'Me. Aïcha Nkomo est en direct',
          body: '« Créer sa SARL en 3 étapes » — 143 spectateurs',
          at: now.subtract(const Duration(minutes: 4))),
      AppNotification(
          id: 'n2',
          kind: 'order',
          title: 'Commande PL-10405 livrée',
          body: 'Validez la prestation pour libérer le séquestre.',
          at: now.subtract(const Duration(hours: 1))),
      AppNotification(
          id: 'n3',
          kind: 'message',
          title: 'Nouveau message de Sandrine Mbida',
          body: 'Samedi 14h c\'est bon pour l\'essai maquillage ✨',
          at: now.subtract(const Duration(hours: 1))),
      AppNotification(
          id: 'n4',
          kind: 'payment',
          title: 'Rechargement réussi',
          body: '+ 20 000 XAF via MTN Mobile Money',
          at: now.subtract(const Duration(hours: 9)),
          read: true),
      AppNotification(
          id: 'n5',
          kind: 'follow',
          title: 'Chef Landry a publié',
          body: 'Retour sur le buffet du mariage Kono ce week-end.',
          at: now.subtract(const Duration(days: 1)),
          read: true),
      AppNotification(
          id: 'n6',
          kind: 'review',
          title: 'Laissez un avis',
          body: "Comment s'est passé votre coaching HIIT avec Dr. Muna ?",
          at: now.subtract(const Duration(days: 2)),
          read: true),
      AppNotification(
          id: 'n7',
          kind: 'system',
          title: 'Sécurité du compte',
          body: 'Activez la 2FA : obligatoire au-delà de 100 000 XAF/mois.',
          at: now.subtract(const Duration(days: 3)),
          read: true),
      AppNotification(
          id: 'n8',
          kind: 'live',
          title: 'Rappel : masterclass demain',
          body: 'Chef Landry — « Masterclass cuisine fusion » à 18 h.',
          at: now.subtract(const Duration(days: 3, hours: 4)),
          read: true),
    ];
  }
}
