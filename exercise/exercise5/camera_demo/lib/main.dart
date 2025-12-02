import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraAccess(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CameraAccess extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return CameraAccessState();
  }
}

class CameraAccessState extends State<CameraAccess> {
  File? cameraFile; // Use nullable File as initially there's no image

  Future<void> selectFromCamera() async {
    final ImagePicker picker = ImagePicker();
    // Use the instance method pickImage from the ImagePicker instance
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        cameraFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Camera Access"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: <Widget>[
          Text("GFG", textScaleFactor: 3),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: Text('Select Image from Camera'),
              onPressed: selectFromCamera,
            ),
            SizedBox(
              height: 200.0,
              width: 300.0,
              child: cameraFile == null
                  ? Center(child: Text('Sorry, nothing selected!'))
                  : Center(child: Image.file(cameraFile!)),
            ),
          ],
        ),
      ),
    );
  }
}