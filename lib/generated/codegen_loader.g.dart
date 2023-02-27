// DO NOT EDIT. This is code generated via package:easy_localization/generate.dart

// ignore_for_file: prefer_single_quotes

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' show AssetLoader;

class CodegenLoader extends AssetLoader{
  const CodegenLoader();

  @override
  Future<Map<String, dynamic>> load(String fullPath, Locale locale ) {
    return Future.value(mapLocales[locale.toString()]);
  }

  static const Map<String,dynamic> en = {
  "file": "File",
  "new_1": "New",
  "open": "Open",
  "close": "Close",
  "save": "Save",
  "save_as": "Save as",
  "exit": "Exit",
  "edit": "Edit",
  "select_all": "Select all",
  "cut": "Cut",
  "copy": "Copy",
  "paste": "Paste",
  "view": "View",
  "font": "Font",
  "design_theme": "Design theme",
  "search": "Search",
  "find": "Find",
  "replace": "Replace",
  "help": "Help",
  "reference": "Reference",
  "about_program": "About program",
  "what_to_find": "What to find?",
  "what_to_replace": "What to replace it with?"
};
static const Map<String,dynamic> ru = {
  "file": "Файл",
  "new_1": "Новый",
  "open": "Открыть",
  "close": "Закрыть",
  "save": "Сохранить",
  "save_as": "Сохранить как",
  "exit": "Выход",
  "edit": "Правка",
  "select_all": "Выделить все",
  "cut": "Вырезать",
  "copy": "Копировать",
  "paste": "Вставить",
  "view": "Вид",
  "font": "Шрифт",
  "design_theme": "Тема оформления",
  "search": "Поиск",
  "find": "Найти",
  "replace": "Заменить",
  "help": "Справка",
  "reference": "Справка",
  "about_program": "О программе",
  "what_to_find": "Что найти?",
  "what_to_replace": "На что заменить?"
};
static const Map<String, Map<String,dynamic>> mapLocales = {"en": en, "ru": ru};
}
