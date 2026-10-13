import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta do La Fornalha.
abstract final class Cores {
  static const fundo = Color(0xFFF5F4F1);
  static const texto = Color(0xFF1F1B18);
  static const primaria = Color(0xFFB4361B);
  static const primariaEscura = Color(0xFF8E2412);
  static const textoSecundario = Color(0xFF6B635C);
  static const bordaCard = Color(0xFFE4E0DA);
  static const bordaInput = Color(0xFFCFC9C1);
  static const trilho = Color(0xFFECE8E3);
  static const card = Colors.white;
  static const cardEscuro = Color(0xFF1F1B18);

  static const sucesso = Color(0xFF2E6B3F);
  static const sucessoFundo = Color(0xFFDDEEDF);
  static const criticoFundo = Color(0xFFF8DAD3);
}

abstract final class Raios {
  static const card = 16.0;
  static const botao = 14.0;
  static const chip = 20.0;
}

/// Títulos e números grandes: Bricolage Grotesque 700.
TextStyle estiloTitulo(double tamanho, {Color cor = Cores.texto}) =>
    GoogleFonts.bricolageGrotesque(fontSize: tamanho, fontWeight: FontWeight.w700, color: cor, height: 1.15);

ThemeData criarTema() {
  // Superfícies neutras (menus, dialogs, sheets) em vez dos tons derivados da semente.
  final esquema = ColorScheme.fromSeed(seedColor: Cores.primaria, brightness: Brightness.light).copyWith(
    primary: Cores.primaria,
    onPrimary: Colors.white,
    surface: Cores.fundo,
    onSurface: Cores.texto,
    onSurfaceVariant: Cores.textoSecundario,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Colors.white,
    surfaceContainerHigh: Cores.fundo,
    surfaceContainerHighest: Cores.trilho,
    outline: Cores.bordaInput,
    outlineVariant: Cores.bordaCard,
    error: Cores.primariaEscura,
  );
  // Montado a partir do esquema para que cores derivadas (canvas, hover, divisores) sigam a paleta.
  final base = ThemeData(useMaterial3: true, colorScheme: esquema);
  final corpo = GoogleFonts.dmSansTextTheme(base.textTheme).apply(bodyColor: Cores.texto, displayColor: Cores.texto);

  final formaBotao = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raios.botao));
  const tamanhoMinimoBotao = Size(64, 48);
  final textoBotao = GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700);

  OutlineInputBorder bordaInput(Color cor, [double largura = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: cor, width: largura),
  );

  return base.copyWith(
    scaffoldBackgroundColor: Cores.fundo,
    canvasColor: Colors.white,
    dividerColor: Cores.bordaCard,
    textTheme: corpo.copyWith(
      headlineMedium: estiloTitulo(28),
      headlineSmall: estiloTitulo(22),
      titleLarge: estiloTitulo(20),
      titleMedium: corpo.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Cores.fundo,
      foregroundColor: Cores.texto,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: estiloTitulo(20),
    ),
    cardTheme: CardThemeData(
      color: Cores.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Raios.card),
        side: const BorderSide(color: Cores.bordaCard),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            backgroundColor: Cores.primaria,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Cores.trilho,
            disabledForegroundColor: Cores.textoSecundario,
            minimumSize: tamanhoMinimoBotao,
            shape: formaBotao,
            textStyle: textoBotao,
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.pressed) ? Cores.primariaEscura : null,
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Cores.texto,
        minimumSize: tamanhoMinimoBotao,
        shape: formaBotao,
        side: const BorderSide(color: Cores.bordaInput),
        textStyle: textoBotao,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Cores.primaria,
        minimumSize: const Size(44, 44),
        shape: formaBotao,
        textStyle: textoBotao,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Cores.primaria,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raios.botao)),
      extendedTextStyle: textoBotao,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: Cores.textoSecundario),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (s) => TextStyle(
          color: s.contains(WidgetState.error)
              ? Cores.primariaEscura
              : s.contains(WidgetState.focused)
              ? Cores.primaria
              : Cores.textoSecundario,
        ),
      ),
      border: bordaInput(Cores.bordaInput),
      enabledBorder: bordaInput(Cores.bordaInput),
      focusedBorder: bordaInput(Cores.primaria, 2),
      errorBorder: bordaInput(Cores.primariaEscura),
      focusedErrorBorder: bordaInput(Cores.primariaEscura, 2),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: Cores.texto,
      side: const BorderSide(color: Cores.bordaInput),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raios.chip)),
      labelStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: Cores.texto),
      secondaryLabelStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Cores.criticoFundo,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? Cores.primaria : Cores.textoSecundario,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Cores.primaria : Cores.textoSecundario),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Cores.texto,
      contentTextStyle: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Cores.fundo,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raios.card)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: Cores.texto,
        selectedForegroundColor: Colors.white,
        side: const BorderSide(color: Cores.bordaInput),
        minimumSize: const Size(44, 48),
        textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Cores.primaria),
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}
