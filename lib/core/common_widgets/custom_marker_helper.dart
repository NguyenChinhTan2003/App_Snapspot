import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CustomMarkerHelper {
  static Future<Uint8List> createGoogleStyleMarker(
    String iconUrl, {
    Color backgroundColor = Colors.yellow,
    Color iconColor = Colors.white,
    double size = 120,
  }) async {
    final ui.Image iconImage = await _loadUiImage(iconUrl);

    final intSize = size.toInt();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Shadow circle
    canvas.drawCircle(
      Offset(intSize / 2 + 2, intSize * 0.35 + 3),
      intSize * 0.3,
      shadowPaint,
    );

    // Shadow tail
    final shadowTailPath = Path();
    shadowTailPath.moveTo(intSize * 0.45 + 2, intSize * 0.65 + 3);
    shadowTailPath.lineTo(intSize * 0.55 + 2, intSize * 0.65 + 3);
    shadowTailPath.lineTo(intSize / 2 + 2, intSize * 0.85 + 3);
    shadowTailPath.close();
    canvas.drawPath(shadowTailPath, shadowPaint);

    // Marker body
    final markerPaint = Paint()..color = backgroundColor;
    canvas.drawCircle(
      Offset(intSize / 2, intSize * 0.35),
      intSize * 0.3,
      markerPaint,
    );

    // Tail
    final tailPath = Path();
    tailPath.moveTo(intSize * 0.45, intSize * 0.65);
    tailPath.lineTo(intSize * 0.55, intSize * 0.65);
    tailPath.lineTo(intSize / 2, intSize * 0.85);
    tailPath.close();
    canvas.drawPath(tailPath, markerPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(
      Offset(intSize / 2, intSize * 0.35),
      intSize * 0.3 - 2,
      borderPaint,
    );

    // Icon
    final iconSize = intSize * 0.6;
    final iconDisplaySize = iconSize * 0.95;

    final src = Rect.fromLTWH(
      0,
      0,
      iconImage.width.toDouble(),
      iconImage.height.toDouble(),
    );

    final dst = Rect.fromCenter(
      center: Offset(intSize / 2, intSize * 0.35),
      width: iconDisplaySize,
      height: iconDisplaySize,
    );

    final iconPaint = Paint();
    if (iconColor != Colors.white) {
      iconPaint.colorFilter = ColorFilter.mode(iconColor, BlendMode.srcIn);
    }

    canvas.drawImageRect(iconImage, src, dst, iconPaint);

    // Export image
    final picture = recorder.endRecording();
    final image = await picture.toImage(intSize, intSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Load UI Image từ network
static Future<ui.Image> _loadUiImage(String url) async {
  final completer = Completer<ui.Image>();
  final imageStream = NetworkImage(url).resolve(const ImageConfiguration());

  imageStream.addListener(
    ImageStreamListener(
      (info, _) {
        completer.complete(info.image);
      },
      onError: (error, stackTrace) async {
        debugPrint("⚠️ Lỗi load ảnh marker: $error");

        // fallback: vẽ 1 hình tròn đỏ có icon 📍
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint()..color = Colors.red;

        canvas.drawCircle(const Offset(50, 50), 40, paint);

        final textPainter = TextPainter(
          text: const TextSpan(
            text: "📍",
            style: TextStyle(fontSize: 40),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, const Offset(30, 30));

        final picture = recorder.endRecording();
        final image = await picture.toImage(100, 100);
        completer.complete(image);
      },
    ),
  );

  return completer.future;
}

}
