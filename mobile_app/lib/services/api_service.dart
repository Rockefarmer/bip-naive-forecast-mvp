import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/stock_data.dart';

class ApiService {
  String get baseUrl {
    // Web: browser connects to localhost directly
    if (kIsWeb) return 'http://127.0.0.1:8000';
    // Android emulator: 10.0.2.2 maps to the host machine
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    // iOS simulator / desktop: localhost works
    return 'http://127.0.0.1:8000';
  }

  /// Fetch live watchlist from the backend.
  Future<List<WatchlistItem>> fetchWatchlist() async {
    final url = Uri.parse('$baseUrl/v0/watchlist');
    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WatchlistItem.fromJson(e)).toList();
    } else {
      throw Exception('Watchlist request failed (${response.statusCode})');
    }
  }

  // --- Detail screen mock (will be wired to /v0/forecast/{ticker} later) ---
  static const Map<String, dynamic> mockAaplData = {
    "meta": { "ticker": "AAPL", "name": "Apple Inc." },
    "header_view": {
      "price_formatted": "\$255.41",
      "change_formatted": "+12.30 (+5.45%)",
      "is_positive": true
    },
    "chart_view": {
      "revenue_series": {
        "history": [{"period": "23 Q4", "value": 90.5}, {"period": "24 Q1", "value": 95.0}],
        "forecast": [{"period": "24 Q2", "value": 100.0}, {"period": "24 Q3", "value": 115.0}]
      },
      "net_income_series": {
        "history": [{"period": "23 Q4", "value": 30.0}, {"period": "24 Q1", "value": 32.0}],
        "forecast": [{"period": "24 Q2", "value": 35.0}, {"period": "24 Q3", "value": 42.0}]
      }
    },
    "forecast_summary": {
      "my_forecast": "\$115.0B",
      "delta_value": "+\$7.26B",
      "delta_percent": "+7%",
      "delta_is_positive": true,
      "wall_street": "\$107.7B"
    },
    "analysis_view": {
      "tailwinds": [{"claim": "Strong iPhone Cycle", "sentiment": "positive"}],
      "headwinds": [{"claim": "China Softness", "sentiment": "negative"}]
    }
  };

  Future<StockData> fetchStock(String ticker) async {
    await Future.delayed(const Duration(milliseconds: 500)); 
    return StockData.fromJson(mockAaplData);
  }
}