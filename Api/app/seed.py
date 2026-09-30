"""Données de démonstration (mêmes pros/services que l'app Flutter).

Idempotent : ne fait rien si des utilisateurs existent déjà.
Usage : python -m app.seed
"""
import logging
from datetime import timedelta

from sqlalchemy import func, select

from app.core.config import settings
from app.core.security import hash_password
from app.db import SessionLocal, utcnow
from app.models import (
    Category, Conversation, ConversationMember, Follow, Live, Message, Post, PostComment,
    ProProfile, Review, Service, User,
)
from app.services import ledger
from app.services import orders as order_svc
from app.services.notify import notify

log = logging.getLogger("prolink.seed")

DEMO_PASSWORD = "Demo1234!"
ADMIN_PASSWORD = "Admin1234!"

U = "https://images.unsplash.com/photo-{}?w=400&h=400&fit=crop&crop=faces"
IMG = "https://images.unsplash.com/photo-{}?w=900"
COV1, COV2 = IMG.format("1521737604893-d14cc237f11d"), IMG.format("1521791136064-7986c2920216")

CATEGORIES = [
    "Droit & Justice", "Ingénierie & Bâtiment", "Digital & Tech", "Santé & Bien-être",
    "Éducation & Formation", "Gastronomie & Événementiel", "Beauté & Mode",
    "Finance & Comptabilité", "Artisanat", "Conseil & Business", "Culture & Arts", "Autres services",
]

# (clé, nom, email, métier, catégorie, ville, avatar, couverture, note, abonnés, niveau, plan, bio, langues)
PROS = [
    ("p1", "Me. Aïcha Nkomo", "aicha@prolink.cm", "Avocate d'affaires", "Droit & Justice", "Douala",
     "1573497019940-1c28c88b4f3e", COV1, 4.9, 2431, 3, "premium",
     "Avocate au barreau du Cameroun, 12 ans d'expérience. Contrats commerciaux, création de SARL, contentieux.",
     ["FR", "EN"]),
    ("p2", "Chef Landry Mbappé", "landry@prolink.cm", "Chef cuisinier", "Gastronomie & Événementiel", "Yaoundé",
     "1522529599102-193c0d76b5b6", COV2, 4.8, 1820, 2, "premium",
     "Chef spécialisé en cuisine fusion. Traiteur pour événements privés, mariages, séminaires.", ["FR"]),
    ("p3", "Ing. Franck Talla", "franck@prolink.cm", "Développeur mobile", "Digital & Tech", "Douala",
     "1531384441138-2736e62e0919", COV1, 4.7, 987, 1, "free",
     "Développeur Flutter/React, 6 ans XP. Apps sur-mesure pour PME africaines.", ["FR", "EN"]),
    ("p4", "Dr. Muna Etienne", "muna@prolink.cm", "Coach sportif certifié", "Santé & Bien-être", "Yaoundé",
     "1531123897727-8f129e1688ce", COV2, 5.0, 3122, 2, "premium",
     "Coach sportif diplômé. Programmes personnalisés en présentiel ou visio.", ["FR", "EN"]),
    ("p5", "Arch. Paul Essomba", "paul@prolink.cm", "Architecte DPLG", "Ingénierie & Bâtiment", "Douala",
     "1560250097-0b93528c311a", COV2, 4.6, 1204, 2, "free",
     "Plans de villas et immeubles R+4, permis de bâtir, suivi de chantier à Douala et Kribi.", ["FR", "EN"]),
    ("p6", "Nadège Fotso", "nadege@prolink.cm", "Expert-comptable", "Finance & Comptabilité", "Yaoundé",
     "1573496359142-b8d87734a5a2", COV1, 4.8, 864, 1, "free",
     "Tenue comptable OHADA, déclarations DGI, business plans pour PME et startups.", ["FR"]),
    ("p7", "Sandrine Mbida", "sandrine@prolink.cm", "Maquilleuse & coiffeuse", "Beauté & Mode", "Douala",
     "1507152832244-10d45c7eda57", COV2, 4.9, 4510, 2, "premium",
     "Maquillage mariée, tresses et coiffures afro. Déplacement à domicile.", ["FR", "EN"]),
    ("p8", "Prof. Hervé Ngono", "herve@prolink.cm", "Professeur de mathématiques", "Éducation & Formation",
     "Bafoussam", "1519085360753-af0119f7cbe7", COV1, 4.7, 639, 1, "premium",
     "Cours de maths et physique, préparation Probatoire, BAC et concours d'entrée.", ["FR", "EN"]),
    ("p9", "Ibrahim Moussa", "ibrahim@prolink.cm", "Menuisier ébéniste", "Artisanat", "Garoua",
     "1506794778202-cad84cf45f1d", COV2, 4.5, 412, 1, "free",
     "Meubles sur mesure en bois massif (iroko, sapelli). Livraison.", ["FR"]),
    ("p10", "Grace Eyenga", "grace@prolink.cm", "Consultante marketing", "Conseil & Business", "Douala",
     "1494790108377-be9c29b29330", COV1, 4.8, 1733, 3, "business",
     "Stratégie de marque, réseaux sociaux et lancement produit pour marques africaines.", ["FR", "EN"]),
]

# clé pro → [(titre, description, prix, type, durée, modalité, annulation, formules?)]
SERVICES = {
    "p1": [
        ("Consultation juridique 30 min", "Entretien téléphonique ou en visio pour analyser votre situation.",
         15000, "fixed", "30 min", "À distance", "Flexible", True),
        ("Création de SARL — Pack complet", "Statuts, immatriculation, ouverture bancaire.",
         250000, "from", "2 semaines", "Mixte", "Standard", True),
        ("Contentieux commercial", "Assistance juridique et représentation.",
         0, "quote", "Variable", "Mixte", "Stricte", False),
        ("Rédaction de contrat commercial", "Contrat de prestation, bail, CGV ou pacte d'associés.",
         75000, "fixed", "5 jours", "À distance", "Standard", True),
        ("Conseil juridique mensuel", "Abonnement PME : questions illimitées + 1 RDV/mois.",
         60000, "monthly", "Mensuel", "À distance", "Flexible", False),
    ],
    "p2": [
        ("Cours particulier de cuisine", "1h30 chez vous, 4 plats emblématiques.",
         25000, "fixed", "1h30", "Sur site", "Standard", True),
        ("Traiteur événement 50 personnes", "Menu 3 services, service inclus.",
         750000, "from", "1 journée", "Sur site", "Stricte", False),
    ],
    "p3": [
        ("App mobile MVP Flutter", "4 écrans, backend simple, publication stores.",
         900000, "from", "4 semaines", "À distance", "Standard", False),
        ("Audit d'application existante", "Performance, sécurité et qualité du code. Rapport PDF.",
         150000, "fixed", "1 semaine", "À distance", "Flexible", False),
    ],
    "p4": [
        ("Coaching HIIT 4 semaines", "Programme + 4 séances live/mois.",
         30000, "fixed", "4 semaines", "À distance", "Flexible", True),
        ("Séance individuelle à domicile", "1 h de coaching personnalisé, matériel fourni.",
         10000, "hourly", "1 h", "Sur site", "Flexible", False),
    ],
    "p5": [
        ("Plans de villa + permis de bâtir", "Esquisse, plans d'exécution, dossier de permis.",
         1200000, "from", "6 semaines", "Mixte", "Standard", False),
        ("Visite conseil de terrain", "Étude de faisabilité sur site avant achat ou construction.",
         50000, "fixed", "½ journée", "Sur site", "Flexible", False),
    ],
    "p6": [
        ("Tenue comptable PME", "Saisie, rapprochements, états financiers OHADA.",
         80000, "monthly", "Mensuel", "À distance", "Standard", False),
        ("Business plan bancable", "Étude de marché, prévisionnel 3 ans, pitch deck.",
         200000, "fixed", "2 semaines", "À distance", "Standard", True),
    ],
    "p7": [
        ("Maquillage mariée", "Essai + jour J, retouches incluses.",
         60000, "fixed", "3 h", "Sur site", "Stricte", True),
        ("Tresses & coiffure afro", "Knotless, nattes collées, vanilles.",
         15000, "from", "2 à 5 h", "Sur site", "Flexible", False),
    ],
    "p8": [("Cours de maths — niveau lycée", "Séances de 2 h, exercices corrigés, suivi des notes.",
            5000, "hourly", "2 h", "Mixte", "Flexible", False)],
    "p9": [("Meuble sur mesure", "Dressing, cuisine, bibliothèque en bois massif.",
            0, "quote", "3 à 6 semaines", "Sur site", "Standard", False)],
    "p10": [
        ("Stratégie réseaux sociaux", "Audit, ligne éditoriale, calendrier 3 mois.",
         180000, "fixed", "10 jours", "À distance", "Standard", True),
        ("Community management", "12 publications/mois + modération + reporting.",
         120000, "monthly", "Mensuel", "À distance", "Flexible", False),
    ],
}

# (pro, texte, images, heures, likes, commentaires, sponsorisé, type)
POSTS = [
    ("p1", "Nouveau : accompagnement complet pour la création d'une SARL au Cameroun. 3 formules, prix affichés.",
     [IMG.format("1450101499163-c8848c66ca85")], 2, 128, 14, True, "photo"),
    ("p2", "Retour sur le buffet du mariage Kono ce week-end. Merci aux mariés pour leur confiance !",
     [IMG.format("1555939594-58d7cb561ad1"), IMG.format("1504674900247-0877df9cc836")], 5, 302, 41, False, "portfolio"),
    ("p7", "Maquillage mariée + coiffure pour Estelle samedi à Bonapriso 💄 Il me reste 2 dates libres en décembre !",
     [], 7, 518, 63, False, "text"),
    ("p3", "Astuce du jour : 3 erreurs à éviter quand on publie sa première app sur le Play Store.\n\n"
           "1. Oublier la politique de confidentialité\n2. Des captures d'écran floues\n3. Ne pas tester sur un petit téléphone",
     [], 11, 91, 22, False, "article"),
    ("p4", "Live demain à 18h : « Le HIIT à la maison — 20 min chrono ». Cloche activée = notification.",
     [IMG.format("1571019614242-c5c5dee9f50b")], 16, 210, 33, False, "live_announce"),
    ("p6", "Rappel : la déclaration statistique et fiscale (DSF) est due au 15 mars. Je prends encore 5 PME ce trimestre.",
     [], 20, 76, 9, False, "text"),
    ("p2", "Masterclass cuisine fusion ce samedi en live payant : ndolé revisité et plantain caramélisé.",
     [IMG.format("1504754524776-8f4f37790ca0")], 27, 187, 27, False, "live_announce"),
    ("p5", "Livraison d'une villa R+1 à Kribi : 4 chambres, toiture végétalisée, 7 mois de chantier. Merci à toute l'équipe !",
     [COV2], 48, 344, 38, False, "portfolio"),
]


def _variants(price: int) -> list[dict]:
    return [{"name": "Basic", "price_xaf": price}, {"name": "Standard", "price_xaf": price * 2},
            {"name": "Premium", "price_xaf": price * 3}]


def seed() -> bool:
    db = SessionLocal()
    try:
        if db.scalar(select(func.count(User.id))):
            log.info("Base déjà peuplée — seed ignoré")
            return False
        now = utcnow()
        pwd = hash_password(DEMO_PASSWORD)

        cats = {}
        for i, name in enumerate(CATEGORIES):
            c = Category(name=name, position=i)
            db.add(c)
            cats[name] = c
        db.flush()

        admin = User(name="Admin ProLink", email="admin@prolink.cm", phone="+237690000001",
                     password_hash=hash_password(ADMIN_PASSWORD), role="admin", city="Douala",
                     two_fa_enabled=False)
        client = User(name="Emmanuel Sakam", email="client@prolink.cm", phone="+237690000042",
                      password_hash=pwd, role="client", city="Douala", address="Akwa, rue Joss",
                      avatar_url=U.format("1500648767791-00dcc994a43e"), languages=["FR", "EN"],
                      phone_verified=True)
        extra_clients = [
            User(name=n, email=f"{n.split()[0].lower()}@exemple.cm", password_hash=pwd, role="client", city=c)
            for n, c in [("Grace Fotso", "Douala"), ("Paul Ndongo", "Yaoundé"), ("Brice Ewane", "Douala"),
                         ("Estelle Kamga", "Douala"), ("Yannick Onana", "Yaoundé")]
        ]
        db.add_all([admin, client, *extra_clients])

        pros: dict[str, User] = {}
        for key, name, email, job, cat, city, av, cov, rating, fol, lvl, plan, bio, langs in PROS:
            u = User(name=name, email=email, password_hash=pwd, role="pro", city=city,
                     avatar_url=U.format(av), languages=langs, phone_verified=True)
            db.add(u)
            db.flush()
            db.add(ProProfile(user_id=u.id, job=job, category_id=cats[cat].id, bio=bio, cover_url=cov,
                              rating=rating, reviews_count=max(3, fol // 60),
                              followers_count=fol, verified_level=lvl,
                              kyc_status="approved", plan=plan,
                              plan_until=now + timedelta(days=180) if plan != "free" else None,
                              service_area=city))
            pros[key] = u
        db.flush()

        services: dict[str, list[Service]] = {}
        for key, rows in SERVICES.items():
            services[key] = []
            for i, (title, desc, price, ptype, dur, mod, canc, var) in enumerate(rows):
                s = Service(pro_id=pros[key].id, title=title, description=desc, price_xaf=price,
                            pricing_type=ptype, duration=dur, modality=mod, cancellation=canc,
                            category=pros[key].pro.category.name if pros[key].pro.category else None,
                            variants=_variants(price) if var else [], position=i,
                            deliverables=["Compte rendu écrit", "Suivi 30 jours"])
                db.add(s)
                services[key].append(s)
        db.flush()

        for key, text, images, hours, likes, comments, sponsored, kind in POSTS:
            p = Post(author_id=pros[key].id, text=text, images=images, likes_count=likes,
                     comments_count=comments, sponsored=sponsored, kind=kind,
                     created_at=now - timedelta(hours=hours))
            db.add(p)
            db.flush()
            db.add(PostComment(post_id=p.id, author_id=client.id, text="Très utile, merci pour le partage !"))

        for key in ("p1", "p2", "p4", "p7"):
            db.add(Follow(follower_id=client.id, pro_id=pros[key].id, notify=key in ("p1", "p4")))

        lives = [
            Live(pro_id=pros["p1"].id, title="Créer sa SARL en 3 étapes", cover_url=COV1, mode="paid",
                 price_xaf=2000, status="live", scheduled_at=now - timedelta(minutes=20),
                 started_at=now - timedelta(minutes=20), viewers=143, peak_viewers=150),
            Live(pro_id=pros["p7"].id, title="Tresses knotless : tuto pas à pas", cover_url=COV2,
                 mode="tips", status="live", scheduled_at=now - timedelta(minutes=35),
                 started_at=now - timedelta(minutes=35), viewers=612, peak_viewers=640),
            Live(pro_id=pros["p2"].id, title="Masterclass cuisine fusion",
                 cover_url=IMG.format("1504754524776-8f4f37790ca0"), mode="paid", price_xaf=5000,
                 scheduled_at=now + timedelta(days=1, hours=4)),
            Live(pro_id=pros["p4"].id, title="HIIT à la maison — 20 min",
                 cover_url=IMG.format("1571019614242-c5c5dee9f50b"), mode="free",
                 scheduled_at=now + timedelta(hours=18)),
            Live(pro_id=pros["p8"].id, title="Préparer le BAC : méthode en 30 jours", cover_url=COV1,
                 mode="paid", price_xaf=1500, scheduled_at=now + timedelta(days=3)),
        ]
        db.add_all(lives)
        db.flush()

        # Conversations (FR + EN pour la démo de traduction).
        convs = [
            ("p1", [("p", "Bonjour, comment puis-je vous aider ?", 45),
                    ("c", "Hello, I need a quote for creating a SARL.", 40),
                    ("p", "Je vous envoie le pack complet en pièce jointe.", 30)]),
            ("p7", [("p", "Samedi 14h c'est bon pour l'essai maquillage ✨", 60)]),
            ("p3", [("p", "Ok, on part sur 4 écrans + auth Firebase ?", 180)]),
            ("p2", [("c", "Parfait, 50 couverts pour le 12 décembre.", 360)]),
            ("p6", [("p", "Il me manque vos relevés bancaires d'octobre.", 540)]),
        ]
        for key, msgs in convs:
            c = Conversation(kind="direct", last_message_at=now - timedelta(minutes=msgs[-1][2]))
            db.add(c)
            db.flush()
            db.add_all([ConversationMember(conversation_id=c.id, user_id=client.id),
                        ConversationMember(conversation_id=c.id, user_id=pros[key].id)])
            for who, text, ago in msgs:
                db.add(Message(conversation_id=c.id, author_id=(pros[key] if who == "p" else client).id,
                               text=text, lang="en" if text.startswith("Hello") else "fr",
                               created_at=now - timedelta(minutes=ago)))
        groups = [
            ("Entrepreneurs Douala — Droit des affaires", "p1", "public", 0,
             "Questions juridiques du quotidien pour TPE/PME. Animé chaque mardi."),
            ("Club HIIT 30 jours", "p4", "paid", 5000,
             "Programme collectif, séances live réservées et suivi personnalisé."),
            ("Flutter Cameroun", "p3", "private", 0, "Entraide entre développeurs mobiles. Sur invitation."),
        ]
        for title, key, access, price, desc in groups:
            g = Conversation(kind="group", title=title, host_id=pros[key].id, access=access,
                             price_xaf=price, description=desc, last_message_at=now - timedelta(hours=5))
            db.add(g)
            db.flush()
            db.add(ConversationMember(conversation_id=g.id, user_id=pros[key].id))
            db.add(Message(conversation_id=g.id, author_id=pros[key].id,
                           text="Bienvenue à tous ! Règles du groupe et planning épinglés.", lang="fr"))
        db.commit()

        # Portefeuilles et commandes via le vrai grand livre (soldes cohérents).
        for u in (client, *extra_clients):
            ledger.credit(db, u.id, 1_500_000, "topup", "Rechargement MTN Mobile Money", method="mtn")
        client.two_fa_enabled = True  # volume de démo > 100 000 XAF / 30 j
        for u in extra_clients:
            u.two_fa_enabled = True
        db.commit()

        def order(buyer: User, key: str, idx: int, variant: str | None, *steps: str) -> None:
            s = services[key][idx]
            o = order_svc.create_order(db, buyer, s.pro_id, s.title, s.price_for(variant), service_id=s.id,
                                       variant=variant, brief="Commande de démonstration", slot=None,
                                       method="wallet", phone=None)
            for step in steps:
                if step == "confirm":
                    o.status, o.confirmed_at = "in_progress", utcnow()
                elif step == "deliver":
                    o.status, o.delivered_at = "delivered", utcnow()
                    o.delivery_message = "Livrables envoyés, bonne réception !"
                elif step == "complete":
                    order_svc.complete(db, o)
                elif step == "review":
                    db.add(Review(order_id=o.id, author_id=buyer.id, pro_id=o.pro_id, stars=5,
                                  text="Très professionnelle, livrables rendus en avance.",
                                  tags=["Ponctuel", "Professionnel"]))
            db.flush()

        order(client, "p1", 0, "Standard")
        order(extra_clients[3], "p1", 3, "Premium")
        order(extra_clients[0], "p1", 1, "Premium", "confirm")
        order(extra_clients[4], "p1", 0, "Basic", "confirm")
        order(client, "p2", 0, "Basic", "confirm", "deliver")
        order(extra_clients[1], "p1", 3, "Standard", "confirm", "deliver")
        order(extra_clients[1], "p4", 0, "Standard", "confirm", "deliver", "complete", "review")
        order(extra_clients[0], "p1", 0, "Standard", "confirm", "deliver", "complete", "review")
        order(client, "p3", 1, None, "confirm", "deliver", "complete")
        db.commit()

        notify(db, client.id, "system", "Bienvenue sur ProLink 👋",
               "Suivez des pros, commandez en toute sécurité grâce au séquestre.")
        db.commit()
        log.info("Seed terminé : %d pros, client=%s, admin=%s", len(pros), client.email, admin.email)
        return True
    finally:
        db.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    if settings.seed_demo:
        seed()
    else:
        log.info("SEED_DEMO=false — aucune donnée de démo chargée")
