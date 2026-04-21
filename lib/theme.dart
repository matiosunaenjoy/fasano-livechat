import 'package:flutter/material.dart';

final ThemeData whatsappTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF111B21),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1F2C34),
    elevation: 0,
    iconTheme: IconThemeData(color: Color(0xFF8696A0)),
  ),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF00A884),
    secondary: Color(0xFF00A884),
    surface: Color(0xFF1F2C34),
    onSurface: Color(0xFFE9EDEF),
    error: Color(0xFFFF4444),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF00A884),
    foregroundColor: Colors.white,
  ),
  dividerColor: const Color(0xFF2A3942),
  cardTheme: CardThemeData(
    color: const Color(0xFF1F2C34),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2A3942),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF00A884)),
    ),
    hintStyle: const TextStyle(color: Color(0xFF8696A0)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF00A884),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
);

class DeptColors {
  static const ventas = Color(0xFF3B82F6);
  static const ti = Color(0xFF8B5CF6);
  static const rrhh = Color(0xFFEC4899);
  static const finanzas = Color(0xFFF59E0B);
  static const marketing = Color(0xFF14B8A6);
  static const operaciones = Color(0xFFF97316);
  static const gerencia = Color(0xFFEF4444);
  static const general = Color(0xFF00A884);

  static Color forDepartment(String dept) {
    switch (dept.toLowerCase()) {
      case 'ventas':
        return ventas;
      case 'ti':
      case 'tecnología':
        return ti;
      case 'rrhh':
      case 'recursos humanos':
        return rrhh;
      case 'finanzas':
        return finanzas;
      case 'marketing':
        return marketing;
      case 'operaciones':
        return operaciones;
      case 'gerencia':
        return gerencia;
      default:
        return general;
    }
  }
}
