import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class CustomPointAnnotationClickListener
    extends OnPointAnnotationClickListener {
  final Map<String, String> annotationIdToSpotId;
  final Future<void> Function(String spotId) onMarkerTapped;

  CustomPointAnnotationClickListener({
    required this.annotationIdToSpotId,
    required this.onMarkerTapped,
  });

  @override
  Future<bool> onPointAnnotationClick(PointAnnotation annotation) async {
    final spotId = annotationIdToSpotId[annotation.id];
    if (spotId != null) {
      if (kDebugMode) {
        print("Marker tapped: $spotId");
      }
      await onMarkerTapped(spotId);
    }
    return true;
  }
}
