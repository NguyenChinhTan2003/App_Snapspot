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

  /// Lấy tên địa điểm từ tọa độ
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

  /// Lấy đường đi từ điểm A đến B
  static Future<Map<String, dynamic>?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String profile = "driving",
  }) async {
    if (_token == null) {
      await initialize();
    }

    if (_token == null) {
      debugPrint('Failed to initialize Mapbox token');
      return null;
    }

    try {
      final url = "https://api.mapbox.com/directions/v5/mapbox/$profile/"
          "$originLng,$originLat;$destLng,$destLat"
          "?geometries=geojson&overview=full&steps=true&access_token=$_token";

      debugPrint("Requesting directions: $url");
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["routes"] != null && data["routes"].isNotEmpty) {
          return {
            "geometry": data["routes"][0]["geometry"],
            "distance": data["routes"][0]["distance"],
            "duration": data["routes"][0]["duration"],
          };
        }
      } else {
        debugPrint(
            'Mapbox Directions API error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching route: $e");
      return null;
    }
  }
}
