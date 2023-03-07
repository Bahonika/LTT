import 'package:flutter_riverpod/flutter_riverpod.dart';

final fontProvider = StateNotifierProvider<FontNotifier, String>((ref) {
  return FontNotifier();
});

class FontNotifier extends StateNotifier<String> {
  FontNotifier() : super('Montserrat');

  void setNew(String name) {
    state = name;
  }

}
