import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2383E2),
          brightness: Brightness.light,
        ).copyWith(
          surface: Colors.white,
          onSurface: const Color(0xFF37352F),
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: const Color(0xFF37352F),
          displayColor: const Color(0xFF37352F),
        ),
        dividerColor: const Color(0xFFE9E9E7),
        cardColor: Colors.white,
        hoverColor: const Color(0xFFF1F1EF),
        focusColor: const Color(0xFFEEEEEE),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2383E2),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF191919),
          onSurface: const Color(0xFFCFCFCF),
        ),
        scaffoldBackgroundColor: const Color(0xFF191919),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: const Color(0xFFCFCFCF),
          displayColor: const Color(0xFFCFCFCF),
        ),
        dividerColor: const Color(0xFF2D2D2D),
        cardColor: const Color(0xFF202020),
        hoverColor: const Color(0xFF262626),
        focusColor: const Color(0xFF2D2D2D),
      );

  // Notion sidebar colors
  static const sidebarLight = Color(0xFFF7F7F5);
  static const sidebarDark = Color(0xFF111111);

  static const notionBlue = Color(0xFF2383E2);
  static const notionGray = Color(0xFF9B9A97);
  static const notionRed = Color(0xFFE03E3E);
  static const notionYellow = Color(0xFFDFAB01);
  static const notionGreen = Color(0xFF0F7B6C);
  static const notionPink = Color(0xFFAD1A72);
  static const notionPurple = Color(0xFF6940A5);
  static const notionOrange = Color(0xFFD9730D);

  static const blockColors = [
    Color(0xFFFFF9C4), // yellow
    Color(0xFFE8F5E9), // green
    Color(0xFFE3F2FD), // blue
    Color(0xFFFCE4EC), // pink
    Color(0xFFF3E5F5), // purple
    Color(0xFFFFF3E0), // orange
    Color(0xFFECEFF1), // gray
  ];
}
