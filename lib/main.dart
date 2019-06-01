import 'dart:async';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:unknown_app/src/data/api/api.dart';
import 'package:unknown_app/src/domain/profile.dart';

Future<void> main() async {
  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: CameraScanScreen(
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera
class CameraScanScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScanScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  CameraScanScreenState createState() => CameraScanScreenState();
}

class CameraScanScreenState extends State<CameraScanScreen> {
  Future<Profile> profileRequest;
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  final String _namePattern = r"^[a-zA-Z]+(([',. -][a-zA-Z ])?[a-zA-Z]*)*$";
  RegExp _regEx;
  Api _api;

  @override
  void initState() {
    super.initState();
    _regEx = RegExp(_namePattern);
    _api = Api();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    // Next, you need to initialize the controller. This returns a Future
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: <Widget>[
                CameraPreview(_controller),
                createFutureBuilder(),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5.0),
            child: FloatingActionButton(
              child: Icon(Icons.camera_alt),
              onPressed: () async {
                try {
                  // Ensure the camera is initialized
                  await _initializeControllerFuture;
                  _controller.startImageStream((CameraImage availableImage) {
                    _scanText(availableImage);
                  });
                } catch (e) {
                  print(e);
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5.0),
            child: FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () async {
                try {
                  // Ensure the camera is initialized
                  await _initializeControllerFuture;
                  _controller.stopImageStream();
                } catch (e) {
                  print(e);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _scanText(CameraImage availableImage) async {
    final FirebaseVisionImageMetadata metadata = FirebaseVisionImageMetadata(
        rawFormat: availableImage.format.raw,
        size: Size(
            availableImage.width.toDouble(), availableImage.height.toDouble()),
        planeData: availableImage.planes
            .map((currentPlane) => FirebaseVisionImagePlaneMetadata(
                bytesPerRow: currentPlane.bytesPerRow,
                height: currentPlane.height,
                width: currentPlane.width))
            .toList(),
        rotation: ImageRotation.rotation90);

    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromBytes(availableImage.planes[0].bytes, metadata);
    final TextRecognizer textRecognizer =
        FirebaseVision.instance.textRecognizer();
    final VisionText visionText =
        await textRecognizer.processImage(visionImage);

    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        if (_regEx.hasMatch(line.text)) {
          //print(line.text);
          if (profileRequest == null) {
            profileRequest = _api.getProfile(line.text);
          }
        }
      }
    }
  }

  FutureBuilder<Profile> createFutureBuilder(){
    return FutureBuilder<Profile>(
      future: profileRequest,
      builder: (context, snapshot) {

        print("snapshot = $snapshot");
        if (snapshot.hasData) {
          return Text(snapshot.data.name);
        } else if (snapshot.hasError) {
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
