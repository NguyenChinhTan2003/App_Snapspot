import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class CustomPointAnnotationClickListener extends OnPointAnnotationClickListener {
  final Map<String, String> annotationIdToCheckInId;
  final Future<void> Function(String checkInId) onMarkerTapped;

  CustomPointAnnotationClickListener({
    required this.annotationIdToCheckInId,
    required this.onMarkerTapped,
  });

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    final checkInId = annotationIdToCheckInId[annotation.id];
    if (checkInId != null) {
      if (kDebugMode) {
        print("👉 Marker tapped: $checkInId");
      }
      // Gọi hàm trong controller 
      onMarkerTapped(checkInId);
    }
    return true;
  }
}
