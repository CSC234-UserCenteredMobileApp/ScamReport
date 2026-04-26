import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Design tokens — translated from the Claude Design prototype's styles.css.
// See `docs/design-review.md` for the full token table and rationale.

const Color _brandPrimary = Color(0xFFF25F2A); // --brand-500

// Light surfaces
const Color _bgLight = Color(0xFFFAFAF7);
const Color _surfaceLight = Color(0xFFFFFFFF);
const Color _surface2Light = Color(0xFFF5F4EF);
const Color _borderLight = Color(0xFFEBE9E2);
const Color _inkLight = Color(0xFF1A1814);
const Color _inkSoftLight = Color(0xFF4B4842);
const Color _inkMutedLight = Color(0xFF847F74);

// Dark surfaces
const Color _bgDark = Color(0xFF14130F);
const Color _surfaceDark = Color(0xFF1D1C18);
const Color _surface2Dark = Color(0xFF26241F);
const Color _borderDark = Color(0xFF2E2C26);
const Color _inkDark = Color(0xFFF5F3EE);
const Color _inkSoftDark = Color(0xFFD6D2C8);
const Color _inkMutedDark = Color(0xFF9C978A);

// Verdict colours, light theme
const _scamLight = VerdictColors(
  bg: Color(0xFFFEF2F2),
  fg: Color(0xFFB91C1C),
  accent: Color(0xFFDC2626),
  soft: Color(0xFFFEE2E2),
);
const _suspiciousLight = VerdictColors(
  bg: Color(0xFFFFFBEB),
  fg: Color(0xFFB45309),
  accent: Color(0xFFF59E0B),
  soft: Color(0xFFFEF3C7),
);
const _safeLight = VerdictColors(
  bg: Color(0xFFF0FDF4),
  fg: Color(0xFF15803D),
  accent: Color(0xFF16A34A),
  soft: Color(0xFFDCFCE7),
);
const _unknownLight = VerdictColors(
  bg: Color(0xFFF8FAFC),
  fg: Color(0xFF475569),
  accent: Color(0xFF64748B),
  soft: Color(0xFFE2E8F0),
);

// Verdict colours, dark theme
const _scamDark = VerdictColors(
  bg: Color(0xFF2A1414),
  fg: Color(0xFFFCA5A5),
  accent: Color(0xFFDC2626),
  soft: Color(0xFF4A1F1F),
);
const _suspiciousDark = VerdictColors(
  bg: Color(0xFF2A1F0E),
  fg: Color(0xFFFBBF24),
  accent: Color(0xFFF59E0B),
  soft: Color(0xFF4A2F0E),
);
const _safeDark = VerdictColors(
  bg: Color(0xFF0F2419),
  fg: Color(0xFF86EFAC),
  accent: Color(0xFF16A34A),
  soft: Color(0xFF1A3A25),
);
const _unknownDark = VerdictColors(
  bg: Color(0xFF1F2024),
  fg: Color(0xFFCBD5E1),
  accent: Color(0xFF64748B),
  soft: Color(0xFF2D2F36),
);

ThemeData lightTheme() => _buildTheme(
      brightness: Brightness.light,
      bg: _bgLight,
      surface: _surfaceLight,
      surfaceContainer: _surface2Light,
      outline: _borderLight,
      onSurface: _inkLight,
      onSurfaceVariant: _inkSoftLight,
      mutedHint: _inkMutedLight,
      verdict: const VerdictPalette(
        scam: _scamLight,
        suspicious: _suspiciousLight,
        safe: _safeLight,
        unknown: _unknownLight,
      ),
    );

ThemeData darkTheme() => _buildTheme(
      brightness: Brightness.dark,
      bg: _bgDark,
      surface: _surfaceDark,
      surfaceContainer: _surface2Dark,
      outline: _borderDark,
      onSurface: _inkDark,
      onSurfaceVariant: _inkSoftDark,
      mutedHint: _inkMutedDark,
      verdict: const VerdictPalette(
        scam: _scamDark,
        suspicious: _suspiciousDark,
        safe: _safeDark,
        unknown: _unknownDark,
      ),
    );

ThemeData _buildTheme({
  required Brightness brightness,
  required Color bg,
  required Color surface,
  required Color surfaceContainer,
  required Color outline,
  required Color onSurface,
  required Color onSurfaceVariant,
  required Color mutedHint,
  required VerdictPalette verdict,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _brandPrimary,
    brightness: brightness,
  ).copyWith(
    primary: _brandPrimary,
    surface: surface,
    surfaceContainerHighest: surfaceContainer,
    outline: outline,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
  );

  final baseTextTheme = brightness == Brightness.light
      ? Typography.material2021().black
      : Typography.material2021().white;
  final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).apply(
    bodyColor: onSurface,
    displayColor: onSurface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    textTheme: textTheme,

    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01,
      ),
    ),

    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: outline),
      ),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outline, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outline, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _brandPrimary, width: 1.5),
      ),
      hintStyle: TextStyle(color: mutedHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _brandPrimary,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        minimumSize: const Size(0, 48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onSurface,
        side: BorderSide(color: outline, width: 1.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        minimumSize: const Size(0, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _brandPrimary,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: surfaceContainer,
      labelStyle: TextStyle(
        color: onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      shape: const StadiumBorder(),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: _brandPrimary,
      unselectedItemColor: mutedHint,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),

    dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),

    extensions: [verdict],
  );
}

// =============================================================================
// VerdictPalette ThemeExtension
// Lets widgets read verdict colours via:
//   final verdict = Theme.of(context).extension<VerdictPalette>()!;
//   Container(color: verdict.scam.bg, child: Text('Scam', style: TextStyle(color: verdict.scam.fg)));
// =============================================================================

@immutable
class VerdictColors {
  const VerdictColors({
    required this.bg,
    required this.fg,
    required this.accent,
    required this.soft,
  });

  final Color bg;
  final Color fg;
  final Color accent;
  final Color soft;

  VerdictColors copyWith({Color? bg, Color? fg, Color? accent, Color? soft}) {
    return VerdictColors(
      bg: bg ?? this.bg,
      fg: fg ?? this.fg,
      accent: accent ?? this.accent,
      soft: soft ?? this.soft,
    );
  }

  static VerdictColors lerp(VerdictColors a, VerdictColors b, double t) {
    return VerdictColors(
      bg: Color.lerp(a.bg, b.bg, t)!,
      fg: Color.lerp(a.fg, b.fg, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      soft: Color.lerp(a.soft, b.soft, t)!,
    );
  }
}

@immutable
class VerdictPalette extends ThemeExtension<VerdictPalette> {
  const VerdictPalette({
    required this.scam,
    required this.suspicious,
    required this.safe,
    required this.unknown,
  });

  final VerdictColors scam;
  final VerdictColors suspicious;
  final VerdictColors safe;
  final VerdictColors unknown;

  @override
  VerdictPalette copyWith({
    VerdictColors? scam,
    VerdictColors? suspicious,
    VerdictColors? safe,
    VerdictColors? unknown,
  }) {
    return VerdictPalette(
      scam: scam ?? this.scam,
      suspicious: suspicious ?? this.suspicious,
      safe: safe ?? this.safe,
      unknown: unknown ?? this.unknown,
    );
  }

  @override
  VerdictPalette lerp(ThemeExtension<VerdictPalette>? other, double t) {
    if (other is! VerdictPalette) return this;
    return VerdictPalette(
      scam: VerdictColors.lerp(scam, other.scam, t),
      suspicious: VerdictColors.lerp(suspicious, other.suspicious, t),
      safe: VerdictColors.lerp(safe, other.safe, t),
      unknown: VerdictColors.lerp(unknown, other.unknown, t),
    );
  }
}
