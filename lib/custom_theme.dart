import 'package:flutter/material.dart';

import 'custom_colors.dart';

class CustomTheme with ChangeNotifier {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: CustomColors.lightThemeMenu,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Montserrat',
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        buttonColor: Colors.purple,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: CustomColors.darkThemeMenu,
      scaffoldBackgroundColor: Colors.grey,
      fontFamily: 'Montserrat',
      textTheme: ThemeData.dark().textTheme,
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        buttonColor: Colors.grey,
      ),
    );
  }

  static ThemeData get warmTheme {
    return ThemeData(
      primaryColor: CustomColors.warmThemeMenu,
      scaffoldBackgroundColor: Colors.greenAccent,
      fontFamily: 'Montserrat',
      textTheme: ThemeData.dark().textTheme,
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        buttonColor: Colors.green,
      ),
    );
  }

  static int themeID = 0;

  ThemeMode get currentTheme {
    if (themeID == 0) {
      return ThemeMode.light;
    } else if (themeID == 1) {
      return ThemeMode.dark;
    } else {
      return ThemeMode.light;
    }
  }

  void toggleLight() {
    if (themeID != 0) {
      themeID = 0;
      notifyListeners();
    }
  }

  void toggleDark() {
    if (themeID != 1) {
      themeID = 1;
      notifyListeners();
    }
  }

  void toggleWarm() {
    if (themeID != 3) {
      themeID = 3;
      notifyListeners();
    }
  }
}
