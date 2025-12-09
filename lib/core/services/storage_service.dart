import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class StorageService {
  late SharedPreferences _prefs;

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Core Methods ---

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clear() => _prefs.clear();

  bool containsKey(String key) => _prefs.containsKey(key);
}
