import 'package:flutter/material.dart';

class CountryCode {
  final String name;
  final String code;
  final String flag;
  final String isoCode;
  final int expectedLength;
  final String example;

  const CountryCode({
    required this.name,
    required this.code,
    required this.flag,
    required this.isoCode,
    required this.expectedLength,
    required this.example,
  });
}

class CountryCodeService {
  static const List<CountryCode> countries = [
    CountryCode(name: 'Türkiye', code: '+90', flag: '🇹🇷', isoCode: 'TR', expectedLength: 10, example: '543 123 45 67'),
    CountryCode(name: 'Azerbaycan', code: '+994', flag: '🇦🇿', isoCode: 'AZ', expectedLength: 9, example: '50 123 45 67'),
    CountryCode(name: 'Almanya', code: '+49', flag: '🇩🇪', isoCode: 'DE', expectedLength: 10, example: '151 12345678'),
    CountryCode(name: 'İngiltere', code: '+44', flag: '🇬🇧', isoCode: 'GB', expectedLength: 10, example: '7911 123456'),
    CountryCode(name: 'ABD / Kanada', code: '+1', flag: '🇺🇸', isoCode: 'US', expectedLength: 10, example: '202 555 0123'),
    CountryCode(name: 'Hollanda', code: '+31', flag: '🇳🇱', isoCode: 'NL', expectedLength: 9, example: '6 12345678'),
    CountryCode(name: 'Fransa', code: '+33', flag: '🇫🇷', isoCode: 'FR', expectedLength: 9, example: '6 12 34 56 78'),
    CountryCode(name: 'Avusturya', code: '+43', flag: '🇦🇹', isoCode: 'AT', expectedLength: 10, example: '664 1234567'),
    CountryCode(name: 'İsviçre', code: '+41', flag: '🇨🇭', isoCode: 'CH', expectedLength: 9, example: '79 123 45 67'),
    CountryCode(name: 'Belçika', code: '+32', flag: '🇧🇪', isoCode: 'BE', expectedLength: 9, example: '470 12 34 56'),
    CountryCode(name: 'Rusya', code: '+7', flag: '🇷🇺', isoCode: 'RU', expectedLength: 10, example: '912 123 45 67'),
    CountryCode(name: 'Ukrayna', code: '+380', flag: '🇺🇦', isoCode: 'UA', expectedLength: 9, example: '50 123 45 67'),
    CountryCode(name: 'Kazakistan', code: '+7', flag: '🇰🇿', isoCode: 'KZ', expectedLength: 10, example: '701 123 45 67'),
    CountryCode(name: 'Türkmenistan', code: '+993', flag: '🇹🇲', isoCode: 'TM', expectedLength: 8, example: '65 123456'),
    CountryCode(name: 'Özbekistan', code: '+998', flag: '🇺🇿', isoCode: 'UZ', expectedLength: 9, example: '90 123 45 67'),
    CountryCode(name: 'Kırgızistan', code: '+996', flag: '🇰🇬', isoCode: 'KG', expectedLength: 9, example: '555 123 456'),
    CountryCode(name: 'Suudi Arabistan', code: '+966', flag: '🇸🇦', isoCode: 'SA', expectedLength: 9, example: '50 123 4567'),
    CountryCode(name: 'BAE', code: '+971', flag: '🇦🇪', isoCode: 'AE', expectedLength: 9, example: '50 123 4567'),
  ];

  static CountryCode detectCountry(BuildContext context) {
    try {
      final locale = View.of(context).platformDispatcher.locale;
      final countryCodeStr = locale.countryCode?.toUpperCase();
      if (countryCodeStr != null && countryCodeStr.isNotEmpty) {
        final found = countries.firstWhere(
          (c) => c.isoCode == countryCodeStr,
          orElse: () => countries.first,
        );
        return found;
      }
    } catch (_) {}
    return countries.first; // Default TR (+90)
  }
}
