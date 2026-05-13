//character_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CharacterProvider extends ChangeNotifier {
  String _character = 'assets/char1.png'; // 캐릭터를 저장할 변수

  String get selectedCharacter => _character;

  CharacterProvider() {
    _loadCharacter(); // 앱 실행 시 캐릭터 로드
  }

  // 캐릭터 로드 (앱 실행 시 저장된 캐릭터를 불러옴)
  Future<void> _loadCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    _character =
        prefs.getString('selected_character') ?? 'assets/char1.png'; // 기본값 설정
    notifyListeners();
  }

  // 캐릭터 변경 (선택한 캐릭터를 저장)
  Future<void> setCharacter(String characterPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_character', characterPath);
    _character = characterPath;
    notifyListeners();
  }
}
