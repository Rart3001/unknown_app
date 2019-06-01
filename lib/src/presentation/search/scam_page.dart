/*import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';



class ScanPage extends StatefulWidget {
  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {

  List<CameraDescription> _cameras;
  CameraController _controller;

  @override
  void initState() async {
    super.initState();
    List<CameraDescription> _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
         /* child: CameraMlVision<List<FirebaseVisionImage>>(
            detector: FirebaseVision.instance.textRecognizer().processImage(visionImage),
            onResult: (List<FirebaseVisionImage> firebaseVisionImage) {
              if (!mounted || resultSent) {
                return;
              }
              resultSent = true;
              //Navigator.of(context).pop<Barcode>(barcodes.first);
            },
          ),*/
        ),
      ),
    );
  }
}*/