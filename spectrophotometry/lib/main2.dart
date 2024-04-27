import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

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
  }

  @override
  void dispose() {
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
              _detectColorFromPoint(details.localPosition);
            },
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: CameraPreview(_controller),
              ),
            ),
          ),
          if (_pointerPosition != null) ...[
            CustomPaint(
              size: Size(
                _controller.value.previewSize!.height,
                _controller.value.previewSize!.width,
              ),
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

  void _detectColorFromPoint(Offset position) async {
    if (!_controller.value.isInitialized) return;

    final xScale = _controller.value.previewSize!.height /
        MediaQuery.of(context).size.height;
    final yScale = _controller.value.previewSize!.width /
        MediaQuery.of(context).size.width;

    final x = (position.dy * xScale).toInt();
    final y = (position.dx * yScale).toInt();

    if (x < 0 ||
        y < 0 ||
        x >= _controller.value.previewSize!.height ||
        y >= _controller.value.previewSize!.width) {
      return;
    }

    final XFile imageFile = await _controller.takePicture();
    final Uint8List bytes = await imageFile.readAsBytes();
    final img.Image image = img.decodeImage(bytes)!;

    final img.Pixel pixel =
        image.getPixel(y, x); // Note the reversed order due to different axis

    setState(() {
      _detectedColor = Color(pixel as int);
      _pointerPosition = position;
    });
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


