import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../data/providers/storage_service.dart';

class LocaleController extends GetxController {
  final StorageService _storage = StorageService();

  final _locale = const Locale('fr').obs;
  Locale get locale => _locale.value;

  @override
  void onInit() {
    super.onInit();
    loadLocale();
  }

  Future<void> loadLocale() async {
    final languageCode = await _storage.getLanguage();
    await setLocale(Locale(languageCode), save: false);
  }

  Future<void> setLocale(Locale newLocale, {bool save = true}) async {
    _locale.value = newLocale;

    if (save) {
      await _storage.saveLanguage(newLocale.languageCode);
    }

    if (newLocale.languageCode == 'fr') {
      timeago.setLocaleMessages('fr', timeago.FrMessages());
      timeago.setDefaultLocale('fr');
      Intl.defaultLocale = 'fr_FR';
      await initializeDateFormatting('fr_FR', null);
    } else {
      timeago.setDefaultLocale('en');
      Intl.defaultLocale = 'en_US';
      await initializeDateFormatting('en_US', null);
    }

    Get.updateLocale(newLocale);
  }
}
