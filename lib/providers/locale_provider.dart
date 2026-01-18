import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../services/storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  Locale _locale = const Locale('fr');
  Locale get locale => _locale;

  Future<void> loadLocale() async {
    final language = await _storage.getLanguage();
    await setLocale(Locale(language), save: false);
  }

  Future<void> setLocale(Locale locale, {bool save = true}) async {
    _locale = locale;

    if (save) {
      await _storage.saveLanguage(locale.languageCode);
    }

    if (locale.languageCode == 'fr') {
      timeago.setLocaleMessages('fr', timeago.FrMessages());
      timeago.setDefaultLocale('fr');
      Intl.defaultLocale = 'fr_FR';
      await initializeDateFormatting('fr_FR', null);
    } else {
      timeago.setDefaultLocale('en');
      Intl.defaultLocale = 'en_US';
      await initializeDateFormatting('en_US', null);
    }

    notifyListeners();
  }
}
