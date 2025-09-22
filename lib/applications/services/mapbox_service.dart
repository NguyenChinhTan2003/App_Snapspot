import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class MapboxService {
  static String? _token;

  static Future<void> initialize() async {
    try {
      const channel = MethodChannel('com.example.app_snapspot/mapbox');
      _token = await channel.invokeMethod('getMapboxToken');
      debugPrint('Mapbox token retrieved: $_token');
    } catch (e) {
      debugPrint('Error retrieving Mapbox token: $e');
      _token = null;
    }
  }

  static Future<String> getPlaceName(double lat, double lng) async {
    if (_token == null) {
      await initialize();
    }

    if (_token == null) {
      debugPrint('Failed to initialize Mapbox token');
      return "Lỗi: Không thể lấy Mapbox token";
    }

    try {
      final url =
          "https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json"
          "?access_token=$_token&language=vi";

      debugPrint('Requesting Mapbox API: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          return data['features'][0]['place_name'] ?? "Không rõ địa chỉ";
        }
      } else {
        debugPrint(
            'Mapbox API error: ${response.statusCode} - ${response.body}');
      }
      return "Không rõ địa chỉ";
    } catch (e) {
      debugPrint('Error fetching place name: $e');
      return "Lỗi lấy địa chỉ: $e";
    }
  }
}
