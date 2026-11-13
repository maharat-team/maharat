import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle screenTitle({
    Color color = AppColors.primaryText,
    bool isUrdu = false,
  }) {
    if (isUrdu) {
      return GoogleFonts.notoSansArabic(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
        height: 1.3,
      );
    }
    return GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle sectionHeading({
    Color color = AppColors.primaryText,
    bool isUrdu = false,
  }) {
    if (isUrdu) {
      return GoogleFonts.notoSansArabic(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );
    }
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle cardTitle({
    Color color = AppColors.primaryText,
    bool isUrdu = false,
  }) {
    if (isUrdu) {
      return GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );
    }
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle body({
    Color color = AppColors.primaryText,
    bool isUrdu = false,
  }) {
    if (isUrdu) {
      return GoogleFonts.notoSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );
    }
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle caption({
    Color color = AppColors.secondaryText,
    bool isUrdu = false,
  }) {
    if (isUrdu) {
      return GoogleFonts.notoSansArabic(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );
    }
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle button({
    Color color = AppColors.white,
    bool isUrdu = false,
  }) {
    if (isUrdu) {
      return GoogleFonts.notoSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );
    }
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}
