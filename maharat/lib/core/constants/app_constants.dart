import 'package:flutter/material.dart';

class TradeCategoryInfo {
  final String id;
  final String nameEn;
  final String nameUrdu;
  final IconData icon;
  final String description;
  final Color color;

  const TradeCategoryInfo({
    required this.id,
    required this.nameEn,
    required this.nameUrdu,
    required this.icon,
    required this.description,
    required this.color,
  });
}

class AppConstants {
  static const int maxWorkPhotos = 12;

  static const String appNameEn = 'Maharat';
  static const String appNameUrdu = 'مہارت';
  static const String taglineEn =
      'Verified local tradespeople. Free for everyone.';
  static const String taglineUrdu = 'تصدیق شدہ مقامی کاریگر۔ سب کے لیے مفت۔';

  static const List<String> bahawalpurNeighbourhoods = [
    'Model Town A',
    'Model Town B',
    'Satellite Town',
    'One Unit Staff Colony',
    'Dubai Mahal Road',
    'University Town',
    'Cantonment',
    'Farid Gate',
    'Trust Colony',
    'Commercial Area',
  ];

  static const List<TradeCategoryInfo> categories = [
    TradeCategoryInfo(
      id: 'electrician',
      nameEn: 'Electrician',
      nameUrdu: 'الیکٹریشن',
      icon: Icons.electrical_services_rounded,
      description: 'Wiring, switches, UPS, fan & lighting repairs',
      color: Color(0xFFEAB308),
    ),
    TradeCategoryInfo(
      id: 'plumber',
      nameEn: 'Plumber',
      nameUrdu: 'پلمبر',
      icon: Icons.plumbing_rounded,
      description: 'Pipe leaks, taps, bathroom fitting, water motors',
      color: Color(0xFF0284C7),
    ),
    TradeCategoryInfo(
      id: 'mason',
      nameEn: 'Mason',
      nameUrdu: 'راج مستری',
      icon: Icons.foundation_rounded,
      description: 'Brickwork, plaster, tiles, concrete work',
      color: Color(0xFFD97706),
    ),
    TradeCategoryInfo(
      id: 'carpenter',
      nameEn: 'Carpenter',
      nameUrdu: 'کارپینٹر',
      icon: Icons.handyman_rounded,
      description: 'Doors, windows, furniture repair & custom woodwork',
      color: Color(0xFF854D0E),
    ),
    TradeCategoryInfo(
      id: 'painter',
      nameEn: 'Painter',
      nameUrdu: 'پینٹر',
      icon: Icons.format_paint_rounded,
      description: 'House painting, distemper, wall putty, weather sheet',
      color: Color(0xFF9333EA),
    ),
    TradeCategoryInfo(
      id: 'ac_technician',
      nameEn: 'AC Technician',
      nameUrdu: 'اے سی ٹیکنیشن',
      icon: Icons.ac_unit_rounded,
      description: 'AC installation, servicing, gas refilling & repair',
      color: Color(0xFF06B6D4),
    ),
  ];

  static const List<String> reviewTags = [
    'On time',
    'Clean work',
    'Fair price',
    'Polite',
    'Skilled',
    'Explained well',
  ];
}
