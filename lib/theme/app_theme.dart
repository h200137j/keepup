import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Dusk palette: an indigo evening sky with a single warm "sodium lamp"
/// accent reserved for *now* — the time rail's live marker and the primary
/// action. Category hues live in media_placeholder_art.dart.
abstract final class KColors {
  static const inkDeep = Color(0xff0f0c20);
  static const ink = Color(0xff15122a);
  static const raised = Color(0xff1e1a38);
  static const raisedHi = Color(0xff27224a);
  static const line = Color(0xff2e2950);
  static const text = Color(0xfff1eeff);
  static const muted = Color(0xff8e88b5);
  static const faint = Color(0xff5c5680);
  static const sodium = Color(0xffffb547);
  static const danger = Color(0xffff6b6b);
}

/// Two families, clearly distinct: Big Shoulders (condensed marquee
/// display) carries numbers and titles; Instrument Sans carries everything
/// people read in sentences.
abstract final class KType {
  static const display = 'BigShoulders';
  static const body = 'InstrumentSans';

  static TextStyle numerals(double size, {Color color = KColors.text}) => TextStyle(
    fontFamily: display,
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 0.9,
    letterSpacing: -0.5,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle headline(double size, {Color color = KColors.text}) =>
      TextStyle(fontFamily: display, fontSize: size, fontWeight: FontWeight.w700, height: 1.0, color: color);

  static const title = TextStyle(
    fontFamily: body,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: KColors.text,
  );

  static const bodyText = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: KColors.text,
  );

  static const meta = TextStyle(
    fontFamily: body,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: KColors.muted,
  );

  static const small = TextStyle(
    fontFamily: body,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: KColors.muted,
  );
}

ThemeData buildKeepUpTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: KColors.sodium, brightness: Brightness.dark).copyWith(
    primary: KColors.sodium,
    onPrimary: KColors.inkDeep,
    surface: KColors.ink,
    onSurface: KColors.text,
    surfaceContainerHigh: KColors.raised,
    surfaceContainerHighest: KColors.raisedHi,
    outline: KColors.line,
    error: KColors.danger,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: w),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: KType.body,
    colorScheme: scheme,
    scaffoldBackgroundColor: KColors.ink,
    splashFactory: InkSparkle.splashFactory,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: KColors.sodium,
      selectionColor: Color(0x55ffb547),
      selectionHandleColor: KColors.sodium,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: KColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: KType.headline(26),
      iconTheme: const IconThemeData(color: KColors.text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KColors.raised,
      labelStyle: KType.meta,
      floatingLabelStyle: KType.meta.copyWith(color: KColors.sodium),
      hintStyle: KType.meta.copyWith(color: KColors.faint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(KColors.sodium, 1.5),
      errorBorder: border(KColors.danger),
      focusedErrorBorder: border(KColors.danger, 1.5),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(KColors.raisedHi)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KColors.sodium,
        foregroundColor: KColors.inkDeep,
        disabledBackgroundColor: KColors.sodium.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontFamily: KType.body, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: KColors.text,
        textStyle: const TextStyle(fontFamily: KType.body, fontWeight: FontWeight.w600),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: KColors.raised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: KType.headline(26),
      contentTextStyle: KType.bodyText.copyWith(color: KColors.muted),
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: KColors.raised,
      headerBackgroundColor: KColors.raisedHi,
    ),
    timePickerTheme: const TimePickerThemeData(backgroundColor: KColors.raised),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: KColors.raised,
      showDragHandle: true,
      dragHandleColor: KColors.faint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: KColors.raisedHi,
      contentTextStyle: KType.bodyText,
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: KColors.sodium),
    dividerTheme: const DividerThemeData(color: KColors.line, thickness: 1, space: 1),
  );
}
