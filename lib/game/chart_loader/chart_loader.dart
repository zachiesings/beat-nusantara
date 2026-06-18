import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/chart.dart';

/// Loads beatmap JSON from bundled assets. Returns null (never throws) when a
/// chart is missing so the UI can fall back gracefully.
class ChartLoader {
  static final _cache = <String, Chart>{};

  static Future<Chart?> load(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath];
    try {
      final raw = await rootBundle.loadString(assetPath);
      final chart = Chart.fromJson(json.decode(raw) as Map<String, dynamic>);
      _cache[assetPath] = chart;
      return chart;
    } catch (_) {
      return null;
    }
  }
}
