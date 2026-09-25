import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF00BFA5); // teal accent
  static const Color primaryDark = Color(0xFF009688);
  static const Color secondary = Color(0xFFFF6B6B); // coral for expense
  static const Color income = Color(0xFF4CAF50); // green for income
  static const Color expense = Color(0xFFFF5252); // red for expense
  static const Color surface = Color(0xFF1A1F2E); // dark blue-grey
  static const Color surfaceCard = Color(0xFF242938);
  static const Color surfaceCard2 = Color(0xFF2C3347);
  static const Color onSurface = Color(0xFFECEFF4);
  static const Color onSurfaceMuted = Color(0xFF8892A4);
  static const Color divider = Color(0xFF2C3347);

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: onSurface,
        outline: divider,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 36,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          color: onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        titleLarge: GoogleFonts.dmSans(
          color: onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: GoogleFonts.dmSans(
          color: onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.dmSans(
          color: onSurface,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.dmSans(
          color: onSurfaceMuted,
          fontSize: 13,
        ),
        labelLarge: GoogleFonts.dmSans(
          color: onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: expense),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: onSurfaceMuted),
        labelStyle: const TextStyle(color: onSurfaceMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceCard2,
        contentTextStyle: GoogleFonts.dmSans(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceCard2,
        selectedColor: primary.withOpacity(0.2),
        labelStyle: GoogleFonts.dmSans(fontSize: 12, color: onSurface),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: onSurfaceMuted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : onSurfaceMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? primary.withOpacity(0.3)
                : surfaceCard2),
      ),
    );
  }

  static ThemeData lightTheme() {
    const Color lSurface = Color(0xFFF4F6FA);
    const Color lCard = Color(0xFFFFFFFF);
    const Color lCard2 = Color(0xFFECEFF4);
    const Color lOnSurface = Color(0xFF1A1F2E);
    const Color lOnSurfaceMuted = Color(0xFF6B7280);
    const Color lDivider = Color(0xFFE0E4ED);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: lSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lOnSurface,
        outline: lDivider,
      ),
      scaffoldBackgroundColor: lSurface,
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        displaySmall: GoogleFonts.spaceGrotesk(
            color: lOnSurface, fontWeight: FontWeight.w700, fontSize: 22),
        titleLarge: GoogleFonts.dmSans(
            color: lOnSurface, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: GoogleFonts.dmSans(
            color: lOnSurface, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: GoogleFonts.dmSans(color: lOnSurface, fontSize: 15),
        bodyMedium: GoogleFonts.dmSans(color: lOnSurfaceMuted, fontSize: 13),
        labelLarge: GoogleFonts.dmSans(
            color: lOnSurface, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: lCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
            color: lOnSurface, fontWeight: FontWeight.w700, fontSize: 20),
        iconTheme: const IconThemeData(color: lOnSurface),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lCard,
        selectedItemColor: primary,
        unselectedItemColor: lOnSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lCard2,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: lDivider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: lDivider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: lOnSurfaceMuted),
        labelStyle: const TextStyle(color: lOnSurfaceMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary)),
      dialogTheme: DialogThemeData(
        backgroundColor: lCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.spaceGrotesk(
            color: lOnSurface, fontWeight: FontWeight.w700, fontSize: 18),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lOnSurface,
        contentTextStyle: GoogleFonts.dmSans(color: lCard),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      dividerTheme:
          const DividerThemeData(color: lDivider, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: lCard2,
        selectedColor: primary.withOpacity(0.15),
        labelStyle: GoogleFonts.dmSans(fontSize: 12, color: lOnSurface),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : lOnSurfaceMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? primary.withOpacity(0.3)
                : lCard2),
      ),
    );
  }

  /// Convert 'dark'|'light'|'system' string to Flutter ThemeMode
  static ThemeMode themeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }
}
