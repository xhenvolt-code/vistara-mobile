import 'package:flutter/material.dart';

import 'services/vistara_api.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const VistaraApp());
}

class VistaraApp extends StatelessWidget {
  const VistaraApp({super.key, this.api});

  final VistaraApi? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vistara',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      darkTheme: AppTheme.dark,
      theme: AppTheme.light,
      home: AppShell(api: api),
    );
  }
}
