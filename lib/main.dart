import 'package:flutter/material.dart';
import 'screens/transferencias/lista.dart';
import 'package:intl/intl.dart';

void main() => runApp(CafeteriaApp());

class CafeteriaApp extends StatelessWidget {
  const CafeteriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = "pt_BR";

    // Paleta da cafeteria: tons de café, do creme ao marrom.
    const Color corCafe = Color(0xFF6F4E37);
    const Color corCreme = Color(0xFFD7CCC8);

    return MaterialApp(
      title: 'Cafeteria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Ativa o estilo Material 3, mais atual e com suporte aos widgets modernos
        useMaterial3: true,

        // Define uma paleta de cores a partir de uma cor base (café, nesse caso)
        // O Flutter gera automaticamente variações coerentes (primary, secondary, etc.)
        colorScheme: ColorScheme.fromSeed(
          seedColor: corCafe,
        ),

        // Define a cor principal do aplicativo para widgets que ainda usam essa propriedade
        primaryColor: corCafe,

        // Cores de fundo dos cartões da lista de consumos
        cardColor: corCreme,

        // Tema para a AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: corCafe,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Tema para botões elevados (substitui o antigo buttonTheme)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: corCafe, // Cor de fundo do botão
            foregroundColor: Colors.white, // Cor do texto/ícones no botão
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Tema para o FloatingActionButton (FAB)
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: corCafe, // Cor do botão flutuante
          foregroundColor: Colors.white, // Cor do ícone
        ),

        // Tema para campos de texto (TextField, por exemplo)
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(), // Define borda padrão
        ),
      ),
      home: ListaTransferencias(),
    );
  }
}
