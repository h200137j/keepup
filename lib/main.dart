import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: KColors.ink,
    ),
  );
  runApp(const ProviderScope(child: KeepUpApp()));
}

class KeepUpApp extends StatelessWidget {
  const KeepUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keep Up',
      debugShowCheckedModeBanner: false,
      theme: buildKeepUpTheme(),
      home: const DashboardScreen(),
    );
  }
}
