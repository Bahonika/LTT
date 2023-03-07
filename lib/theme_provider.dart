import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'custom_theme.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeData> {
  ThemeNotifier() : super(CustomTheme.lightTheme);

  void setLight() {
    state = CustomTheme.lightTheme;
  }

  void setDark() {
    state = CustomTheme.darkTheme;
  }

  void setWarm() {
    state = CustomTheme.warmTheme;
  }
}
