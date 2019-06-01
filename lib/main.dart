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
      appBar: AppBar(title: Text('Unknown App')),
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
                                      image:
                                          new NetworkImage(snapshot.data.img)))),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              snapshot.data.name,
                              style:
                                  TextStyle(color: Colors.black, fontSize: 24.0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              snapshot.data.profile,
                              style: TextStyle(color: Colors.red, fontSize: 20.0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              snapshot.data.company,
                              style:
                                  TextStyle(color: Colors.green, fontSize: 20.0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              snapshot.data.mail,
                              style:
                                  TextStyle(color: Colors.black, fontSize: 18.0),
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
        } else if (false) {
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
                                          "https://media.licdn.com/dms/image/C5603AQE3K06LRFN3JQ/profile-displayphoto-shrink_200_200/0?e=1564617600&v=beta&t=Yv3XKKHR8aiqLwYDAr6PEn3L-0wUs_m79kBmISA4GSU")))),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Nicolás Jara",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 24.0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "Desarrollador Mobile",
                              style: TextStyle(color: Colors.red, fontSize: 20.0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Unknown ltda",
                              style:
                                  TextStyle(color: Colors.green, fontSize: 20.0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "nicolas_jara_rojas@hotmail.com",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 18.0),
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
          return Text("nulo");
        }

        return new Container(width: 0.0, height: 0.0);
      },
    );
  }
}
