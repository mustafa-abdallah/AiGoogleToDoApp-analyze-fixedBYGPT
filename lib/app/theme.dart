import 'package:flutter/material.dart';

// ألوان التصميم الحديثة - متطابقة مع تصميم الويب والفيجما
const kAmber = Color(0xFFF59E0B); // Amber 500
const kAmberLight = Color(0xFFFDE68A); // Amber 200
const kAmberDark = Color(0xFFD97706); // Amber 600

const kEmerald = Color(0xFF10B981); // Emerald 500 (للمهام المكتملة)
const kRose = Color(0xFFF43F5E); // Rose 500 (لحالات التنبيه)
const kOrange = Color(0xFFF97316); // Orange 500 (لشعلة العادات)
const kSky = Color(0xFF0EA5E9); // Sky 500

// ألوان الوضع الداكن الحديث (Deep Modern Dark)
const _darkBg = Color(0xFF0F1117); // خلفية عميقة وراقية
const _darkSurface = Color(0xFF181B26); // بطاقات ناعمة
const _darkCard = Color(0xFF1E2230); // أسطح متقدمة
const _darkBorder = Color(0xFF282D3F); // حواف ناعمة

// ألوان الوضع الفاتح
const _lightBg = Color(0xFFF8FAFC);
const _lightSurface = Color(0xFFFFFFFF);
const _lightBorder = Color(0xFFE2E8F0);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: kAmber,
    brightness: b,
  ).copyWith(
    primary: kAmber,
    onPrimary: const Color(0xFF1A1608),
    secondary: kOrange,
    surface: dark ? _darkSurface : _lightSurface,
    onSurface: dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
    outline: dark ? _darkBorder : _lightBorder,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: dark ? _darkBg : _lightBg,
    
    // تصميم شريط التطبيق العلوي
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? _darkBg.withAlpha(230) : _lightBg.withAlpha(230),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: dark ? Colors.white : const Color(0xFF0F172A),
      ),
      iconTheme: IconThemeData(
        color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
      ),
    ),

    // تصميم البطاقات الحديثة بزوايا دائرية 20 بكسل
    cardTheme: CardThemeData(
      color: dark ? _darkSurface : _lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dark ? _darkBorder : _lightBorder,
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),

    // شريط التنقل السفلي
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? _darkSurface : _lightSurface,
      indicatorColor: kAmber.withAlpha(45),
      elevation: 0,
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: kAmber, size: 24);
        }
        return IconThemeData(
          color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          size: 22,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: kAmber,
          );
        }
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        );
      }),
    ),

    // حقول الإدخال
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? _darkCard : const Color(0xFFF1F5F9),
      hintStyle: TextStyle(
        color: dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: dark ? _darkBorder : _lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: dark ? _darkBorder : _lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kAmber, width: 1.5),
      ),
    ),

    // الزر العائم
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kAmber,
      foregroundColor: const Color(0xFF1A1608),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),

    // الأزرار المعبأة
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),

    // الخطوط والفواصل
    dividerTheme: DividerThemeData(
      color: dark ? _darkBorder : _lightBorder,
      thickness: 1,
      space: 1,
    ),
  );
}
