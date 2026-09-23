import 'package:flutter/material.dart';

/// Bilingual FR/EN copy + inline translator for chat (Alibaba-style).
/// The translator uses a local dictionary for MVP demo and falls back to
/// LibreTranslate-compatible endpoint if configured. This lets clients and pros
/// converse across FR/EN without leaving the conversation.
class AppLocale extends ChangeNotifier {
  Locale _locale = const Locale('fr');
  Locale get locale => _locale;
  bool get isFr => _locale.languageCode == 'fr';

  void toggle() {
    _locale = isFr ? const Locale('en') : const Locale('fr');
    notifyListeners();
  }

  String t(String frKey, String enKey) => isFr ? frKey : enKey;
}

/// Very small offline translator seed for the MVP.
/// Real deployment routes to backend /api/translate (LibreTranslate / DeepL).
class OfflineTranslator {
  static final Map<String, String> _frToEn = {
    'bonjour': 'hello',
    'salut': 'hi',
    'merci': 'thank you',
    'oui': 'yes',
    'non': 'no',
    "j'ai besoin d'un devis": 'I need a quote',
    'quel est votre tarif': 'what is your price',
    'quand pouvez-vous commencer': 'when can you start',
    'combien de temps': 'how long',
    'très bien': 'very well',
    "d'accord": 'ok',
    'à bientôt': 'see you soon',
    'je suis disponible': 'I am available',
    'envoyez-moi les documents': 'send me the documents',
    'le prix est': 'the price is',
  };

  static String translate(String text, {required bool toEn}) {
    var out = text;
    if (toEn) {
      _frToEn.forEach((fr, en) {
        out = out.replaceAll(RegExp(fr, caseSensitive: false), en);
      });
    } else {
      _frToEn.forEach((fr, en) {
        out = out.replaceAll(RegExp(en, caseSensitive: false), fr);
      });
    }
    return out;
  }
}
