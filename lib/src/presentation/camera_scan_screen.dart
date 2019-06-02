import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:unknown_app/src/data/api/api.dart';
import 'package:unknown_app/src/domain/profile.dart';

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

  Rectangle<int> textBoxPosition;
  List<Point<int>> cornerPoints;
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
      appBar: AppBar(title: Text('Unknown App')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: <Widget>[
                CameraPreview(_controller),
                createTextBox(),
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

    for (final TextBlock block in visionText.blocks) {
      setState(() {
        textBoxPosition = block.boundingBox;
        cornerPoints = block.cornerPoints;
      });

      for (TextLine line in block.lines) {
        if (_regEx.hasMatch(line.text)) {
          if (profileRequest == null) {
            print("Fetch request ....");
            setState(() {
              profileRequest = _api.getProfile(line.text);
              // _controller.stopImageStream();
            });
          }
        }
      }
    }
  }

  FutureBuilder<Profile> createFutureBuilder() {
    return FutureBuilder<Profile>(
      future: profileRequest,
      builder: (context, snapshot) {
        print("profileRequest = $profileRequest");
        print("snapshot = $snapshot");
        print("snapshot = ${snapshot.hasData}");
        //print("snapshot = ${snapshot.data.name}");

        if (snapshot.hasData) {
          profileRequest = null;
          //_controller.stopImageStream();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Opacity(
                opacity: 0.9,
                child: new Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 250.0,
                      height: 250.0,
                      child: new Column(
                        children: <Widget>[
                          new Container(
                              width: 80.0,
                              height: 80.0,
                              decoration: new BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: new DecorationImage(
                                      fit: BoxFit.fill,
                                      image: new NetworkImage(
                                          snapshot.data.img)))),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              snapshot.data.name,
                              style: TextStyle(
                                  color: Colors.black, fontSize: 24.0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              snapshot.data.profile,
                              style:
                                  TextStyle(color: Colors.red, fontSize: 20.0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              snapshot.data.company,
                              style: TextStyle(
                                  color: Colors.green, fontSize: 20.0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              snapshot.data.mail,
                              style: TextStyle(
                                  color: Colors.black, fontSize: 18.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  elevation: 5.0,
                ),
              ),
            ],
          );
          ;
        } else if (snapshot.hasError) {
          profileRequest = null;
          return Text("${snapshot.error}");
        }
        return new Container(width: 0.0, height: 0.0);
      },
    );
  }

  Positioned createTextBox() {
    if (textBoxPosition != null) {
      print("textBoxPosition = $textBoxPosition");
      print("cornerPoints = $cornerPoints");

      return new Positioned(
        right: textBoxPosition.right.toDouble(),
        top: textBoxPosition.top.toDouble(),
        child: new Container(
          height: 50.0,
          width: 50.0,
          child: new DecoratedBox(
            decoration:
                new BoxDecoration(border: new Border.all(color: Colors.red)),
          ),
        ),
      );
    }

    return Positioned(
      child: new Container(
        height: 0.0,
        width: 0.0,
      ),
    );
  }
}
