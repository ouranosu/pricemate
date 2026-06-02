import 'package:flutter/material.dart';

class AppThemePreset {
  const AppThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.seedColor,
    required this.scaffoldColor,
  });

  final String id;
  final String name;
  final String description;
  final Color seedColor;
  final Color scaffoldColor;
}

const themePresets = [
  AppThemePreset(
    id: 'fresh',
    name: 'Fresh Green',
    description: '落ち着いた食品アプリらしいグリーン',
    seedColor: Color(0xFF2F6F5E),
    scaffoldColor: Color(0xFFF8FAF8),
  ),
  AppThemePreset(
    id: 'market',
    name: 'Market Blue',
    description: '見やすく清潔感のあるブルー',
    seedColor: Color(0xFF2563A8),
    scaffoldColor: Color(0xFFF6F9FC),
  ),
  AppThemePreset(
    id: 'tomato',
    name: 'Tomato Red',
    description: '買い物メモが目に入りやすいレッド',
    seedColor: Color(0xFFC9493A),
    scaffoldColor: Color(0xFFFFF8F5),
  ),
  AppThemePreset(
    id: 'citrus',
    name: 'Citrus Yellow',
    description: '明るく親しみやすいイエロー',
    seedColor: Color(0xFFB7791F),
    scaffoldColor: Color(0xFFFFFBF0),
  ),
  AppThemePreset(
    id: 'mono',
    name: 'Calm Mono',
    description: '情報量が多くても読みやすいニュートラル',
    seedColor: Color(0xFF4B5563),
    scaffoldColor: Color(0xFFF8F8F7),
  ),
];
