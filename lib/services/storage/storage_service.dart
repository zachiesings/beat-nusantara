import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin persistence wrapper over SharedPreferences. GameState owns the keys and
/// the meaning; this just handles get/set + JSON encode/decode and never throws.
class StorageService {
  late final SharedPreferences _p;

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  String getString(String k, String def) => _p.getString(k) ?? def;
  Future<void> setString(String k, String v) => _p.setString(k, v);

  bool getBool(String k, bool def) => _p.getBool(k) ?? def;
  Future<void> setBool(String k, bool v) => _p.setBool(k, v);

  int getInt(String k, int def) => _p.getInt(k) ?? def;
  Future<void> setInt(String k, int v) => _p.setInt(k, v);

  double getDouble(String k, double def) => _p.getDouble(k) ?? def;
  Future<void> setDouble(String k, double v) => _p.setDouble(k, v);

  Set<String> getStringSet(String k) => _p.getStringList(k)?.toSet() ?? <String>{};
  Future<void> setStringSet(String k, Set<String> v) =>
      _p.setStringList(k, v.toList());

  Map<String, dynamic> getJson(String k) {
    final raw = _p.getString(k);
    if (raw == null) return {};
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> setJson(String k, Map<String, dynamic> v) =>
      _p.setString(k, json.encode(v));
}
