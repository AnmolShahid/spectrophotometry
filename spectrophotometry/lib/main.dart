
// live camera value rgb
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RGB Color Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isInitialized = false;
  Color? _detectedColor;
  Offset? _pointerPosition;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller.initialize();
    if (!mounted) return;
    setState(() {
      _isInitialized = true;
    });
    _startColorPicker();
  }

  void _startColorPicker() {
    _controller.startImageStream((CameraImage image) {
      if (_pointerPosition != null) {
        _detectColor(image);
      }
    });
  }

  @override
  void dispose() {
    _controller.stopImageStream();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(); // You can show a loading indicator here
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('RGB Color Detector'),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
              _updatePointerPosition(details.localPosition);
            },
            child: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: CameraPreview(_controller),
              ),
            ),
          ),
          if (_pointerPosition != null) ...[
            CustomPaint(
              size: Size(300, 300),
              painter: PointerPainter(_pointerPosition!),
            ),
          ],
          if (_detectedColor != null) ...[
            Container(
              width: 100,
              height: 100,
              color: _detectedColor,
            )
          ]
        ],
      ),
    );
  }

  void _updatePointerPosition(Offset position) {
    setState(() {
      _pointerPosition = position;
    });
  }

  void _detectColor(CameraImage image) {
    final int x =
        (_pointerPosition!.dx * _controller.value.previewSize!.height / 300)
            .toInt();
    final int y =
        (_pointerPosition!.dy * _controller.value.previewSize!.width / 300)
            .toInt();

    final int uvRowStride = image.planes[0].bytesPerRow;
    final int uvPixelStride = image.planes[0].bytesPerPixel ?? 1;
    final int planeIndex = uvPixelStride * x ~/ image.width;
    final int uvIndex = uvRowStride * y ~/ image.height;

    final int yValue =
        image.planes[0].bytes[y * image.planes[0].bytesPerRow + x];
    final int uValue = image.planes[0].bytes[uvIndex + planeIndex];
    final int vValue = image.planes[0].bytes[uvIndex + planeIndex];

    final double yd = (yValue - 16).toDouble();
    final double ud = (uValue - 128).toDouble();
    final double vd = (vValue - 128).toDouble();

    final double r = (298.082 * yd + 408.583 * vd) / 256.0;
    final double g = (298.082 * yd - 100.291 * ud - 208.120 * vd) / 256.0;
    final double b = (298.082 * yd + 516.412 * ud) / 256.0;

    setState(() {
      _detectedColor = Color.fromRGBO(r.clamp(0, 255).toInt(),
          g.clamp(0, 255).toInt(), b.clamp(0, 255).toInt(), 1.0);
    });
    print(_detectedColor.toString());
  }
}

class PointerPainter extends CustomPainter {
  final Offset position;

  PointerPainter(this.position);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(position, 8, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}