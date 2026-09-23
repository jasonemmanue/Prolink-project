import 'models.dart';

class MockData {
  static const String _av1 =
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400';
  static const String _av2 =
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400';
  static const String _av3 =
      'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400';
  static const String _av4 =
      'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=400';
  static const String _cov1 =
      'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200';
  static const String _cov2 =
      'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=1200';

  static final List<Pro> pros = [
    Pro(
      id: 'p1',
      name: 'Me. Aïcha Nkomo',
      job: 'Avocate d\'affaires',
      category: 'Droit & Justice',
      city: 'Douala',
      avatar: _av1,
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
      avatar: _av2,
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
      avatar: _av3,
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
      avatar: _av4,
      cover: _cov2,
      rating: 5.0,
      followers: 3122,
      verifiedLevel: 2,
      bio:
          'Coach sportif diplômé. Programmes personnalisés en présentiel ou visio.',
      languages: ['FR', 'EN'],
    ),
  ];

  static Pro proById(String id) => pros.firstWhere((p) => p.id == id);

  static List<Post> feed() => [
        Post(
          id: 'po1',
          author: pros[0],
          text:
              'Nouveau : accompagnement complet pour la création d\'une SARL au Cameroun. 3 formules, prix affichés.',
          images: [
            'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=900'
          ],
          date: DateTime.now().subtract(const Duration(hours: 2)),
          likes: 128,
          comments: 14,
          sponsored: true,
        ),
        Post(
          id: 'po2',
          author: pros[1],
          text:
              'Retour sur le buffet du mariage Kono ce week-end. Merci aux mariés pour leur confiance !',
          images: [
            'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=900',
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900',
          ],
          date: DateTime.now().subtract(const Duration(hours: 8)),
          likes: 302,
          comments: 41,
        ),
        Post(
          id: 'po3',
          author: pros[2],
          text:
              'Astuce du jour : 3 erreurs à éviter quand on publie sa première app sur le Play Store.',
          images: const [],
          date: DateTime.now().subtract(const Duration(hours: 14)),
          likes: 91,
          comments: 22,
        ),
        Post(
          id: 'po4',
          author: pros[3],
          text: 'Live demain à 18h : "Le HIIT à la maison — 20 min chrono". Cloche activée = notification.',
          images: [
            'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=900'
          ],
          date: DateTime.now().subtract(const Duration(hours: 22)),
          likes: 210,
          comments: 33,
        ),
      ];

  static List<Service> servicesOf(Pro p) {
    if (p.id == 'p1') {
      return const [
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
      ];
    }
    if (p.id == 'p2') {
      return const [
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
      ];
    }
    if (p.id == 'p3') {
      return const [
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
      ];
    }
    return const [
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
    ];
  }

  static List<LiveEvent> lives() => [
        LiveEvent(
          id: 'l1',
          title: 'Créer sa SARL en 3 étapes',
          pro: pros[0].name,
          cover:
              'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=900',
          isLive: true,
          paying: true,
          priceXaf: 2000,
          viewers: 143,
          startAt: DateTime.now(),
        ),
        LiveEvent(
          id: 'l2',
          title: 'Masterclass cuisine fusion',
          pro: pros[1].name,
          cover:
              'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?w=900',
          isLive: false,
          paying: true,
          priceXaf: 5000,
          viewers: 0,
          startAt: DateTime.now().add(const Duration(days: 1, hours: 4)),
        ),
        LiveEvent(
          id: 'l3',
          title: 'HIIT à la maison — 20 min',
          pro: pros[3].name,
          cover:
              'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=900',
          isLive: false,
          paying: false,
          priceXaf: 0,
          viewers: 0,
          startAt: DateTime.now().add(const Duration(hours: 18)),
        ),
      ];

  static List<Conversation> conversations() => [
        Conversation(
          id: 'c1',
          peer: pros[0],
          messages: [
            ChatMessage(
              id: 'm1',
              authorId: 'p1',
              text: 'Bonjour, comment puis-je vous aider ?',
              at: DateTime.now().subtract(const Duration(minutes: 45)),
            ),
            ChatMessage(
              id: 'm2',
              authorId: 'me',
              fromMe: true,
              text: "Hello, I need a quote for creating a SARL.",
              at: DateTime.now().subtract(const Duration(minutes: 40)),
            ),
            ChatMessage(
              id: 'm3',
              authorId: 'p1',
              text: 'Je vous envoie le pack complet en pièce jointe.',
              at: DateTime.now().subtract(const Duration(minutes: 30)),
            ),
          ],
        ),
        Conversation(
          id: 'c2',
          peer: pros[2],
          messages: [
            ChatMessage(
              id: 'm4',
              authorId: 'p3',
              text: 'Ok, on part sur 4 écrans + auth Firebase ?',
              at: DateTime.now().subtract(const Duration(hours: 3)),
            ),
          ],
        ),
      ];

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
}
