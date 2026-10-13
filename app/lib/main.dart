import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const FornalhaApp());

class FornalhaApp extends StatelessWidget {
  const FornalhaApp({super.key});

  /// Largura máxima do conteúdo na web, para parecer um celular.
  static const larguraMaxima = 480.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La Fornalha',
      debugShowCheckedModeBanner: false,
      theme: criarTema(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFE9E6E1),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: larguraMaxima),
            child: ClipRect(child: child),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
