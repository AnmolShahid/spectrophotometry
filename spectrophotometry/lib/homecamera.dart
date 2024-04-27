import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as Path;
import 'package:spectrophotometry/imagepage.dart';
import 'package:path_provider/path_provider.dart';


class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    CameraDescription description = await availableCameras().then((cameras) => cameras[0]);
    _controller = CameraController(description, ResolutionPreset.medium);
    await _controller!.initialize();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

@override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Container();
    }
    return Scaffold(
      body: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: CameraPreview(_controller!),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: Icon(Icons.camera_alt),
      ),
    );
  }

 void _takePicture() async {
    final path = Path.join(
      (await getTemporaryDirectory()).path,
      '${DateTime.now()}.jpg',
    );
    await _controller!.takePicture();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageScreen(imagePath: path),
      ),
    );
  }
}
