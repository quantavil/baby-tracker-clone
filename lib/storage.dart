import 'package:shared_preferences/shared_preferences.dart';

abstract interface class TrackerStorage {
  Future<String?> read();
  Future<void> write(String json);
}

class PreferenceStorage implements TrackerStorage {
  static const _key = 'baby_tracker_local_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  @override
  Future<String?> read() => _preferences.getString(_key);
  @override
  Future<void> write(String json) => _preferences.setString(_key, json);
}
