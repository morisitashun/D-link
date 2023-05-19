import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class forScreen extends StatefulWidget {
  const forScreen({Key? key}) : super(key: key);

  @override
  _forScreenState createState() => _forScreenState();
}

class _forScreenState extends State<forScreen> {
  Position? _currentPosition;
  final picker = ImagePicker();
  File? _image;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // 現在地を取得するメソッド
  _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  // カメラまたはギャラリーから画像を選択するメソッド
  _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('投稿画面'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_currentPosition != null)
            Text(
              '現在地の緯度： ${_currentPosition?.latitude}',
              style: TextStyle(fontSize: 24),
            ),
          if (_currentPosition != null)
            Text(
              '現在地の経度： ${_currentPosition?.longitude}',
              style: TextStyle(fontSize: 24),
            ),
          if (_image != null)
            Image.file(
              _image!,
              width: 300,
              height: 300,
            ),
          ElevatedButton(
            onPressed: () {
              _getImage(ImageSource.camera);
            },
            child: Text('カメラで撮影'),
          ),
          ElevatedButton(
            onPressed: () {
              _getImage(ImageSource.gallery);
            },
            child: Text('ギャラリーから選択'),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '説明やコメントを入力してください',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
