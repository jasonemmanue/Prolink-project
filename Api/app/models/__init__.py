"""Modèles SQLAlchemy. Tout est importé ici pour Alembic (autogenerate)."""
from app.models.user import User, ProProfile, Category, KycDocument, Follow, OtpCode, DeviceToken
from app.models.social import Post, PostLike, PostComment, PostSave, Report
from app.models.catalog import Service, QuoteRequest
from app.models.orders import Order, Dispute, Review
from app.models.wallet import Wallet, Transaction
from app.models.chat import Conversation, ConversationMember, Message
from app.models.lives import Live, LiveTicket
from app.models.platform import Notification, Campaign, AuditLog, PlatformSetting, BannedKeyword

__all__ = [
    "User", "ProProfile", "Category", "KycDocument", "Follow", "OtpCode", "DeviceToken",
    "Post", "PostLike", "PostComment", "PostSave", "Report",
    "Service", "QuoteRequest",
    "Order", "Dispute", "Review",
    "Wallet", "Transaction",
    "Conversation", "ConversationMember", "Message",
    "Live", "LiveTicket",
    "Notification", "Campaign", "AuditLog", "PlatformSetting", "BannedKeyword",
]
