import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bn_bd.dart';
import 'en_us.dart';

class AppTranslations extends Translations {
  static const Locale defaultLocale = Locale('bn', 'BD');
  static const Locale fallbackLocale = Locale('en', 'US');

  static const List<Locale> supportedLocales = [
    Locale('bn', 'BD'),
    Locale('en', 'US'),
  ];

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'bn_BD': bnBD,
      };
}
