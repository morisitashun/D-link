import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'first_screen.dart';

class ForScreen extends StatefulWidget {
  const ForScreen({Key? key}) : super(key: key);

  @override
  _ForScreenState createState() => _ForScreenState();
}

class _ForScreenState extends State<ForScreen> {
  var selectedValue = "飲み物の自動販売機";
  final lists = <String>[
    "飲み物の自動販売機",
    "チェリオ",
    "面白い自動販売機",
    "変わったラインナップの自動販売機",
    "コーラ"
  ];
  Position? _currentPosition;
  final picker = ImagePicker();
  File? _image;
  TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Get the current location
  _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  // Method to select an image from camera or gallery
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
      body: SingleChildScrollView(
        // SingleChildScrollViewでラップ
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ListTile(
              title: Text(
                '位置を確認してください↓',
                textAlign: TextAlign.center, // テキストを中央に配置
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
              onTap: () {
                // アイテム2の処理
              },
            ),
            if (_currentPosition != null)
              Container(
                height: 350,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition?.latitude ?? 0.0,
                      _currentPosition?.longitude ?? 0.0,
                    ),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('currentLocation'),
                      position: LatLng(
                        _currentPosition?.latitude ?? 0.0,
                        _currentPosition?.longitude ?? 0.0,
                      ),
                    ),
                  },
                ),
              ),
            ListTile(
              title: Text(
                'コメントを入力してください↓',
                textAlign: TextAlign.center, // テキストを中央に配置
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
              onTap: () {
                // アイテム2の処理
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _textEditingController,
                decoration: InputDecoration(
                  hintText: '説明やコメントを入力してください',
                ),
              ),
            ),
            ListTile(
              title: Text(
                '投稿する写真をアップロードしてください↓',
                textAlign: TextAlign.center, // テキストを中央に配置
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
              onTap: () {
                // アイテム2の処理
              },
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    color: const Color(0x00000000),
                    border: Border.all(
                      color: Colors.green,
                      width: 10.0,
                    ),
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                  child: _image != null
                      ? Image.file(_image!)
                      : Center(
                          child: Text(
                            '写真を選択してください',
                            style: TextStyle(fontSize: 25),
                          ),
                        ),
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
              ],
            ),
            ListTile(
              title: Text(
                'カテゴリーを選択↓',
                textAlign: TextAlign.center, // テキストを中央に配置
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
              onTap: () {
                // アイテム2の処理
              },
            ),
            DropdownButton<String>(
              value: selectedValue,
              items: lists
                  .map((String list) => DropdownMenuItem<String>(
                        value: list,
                        child: Text(
                          list,
                          style: TextStyle(fontFamily: 'NotoSansJP'),
                        ),
                      ))
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedValue = value!;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                // Process when the post button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PostCompleteScreen()),
                );
              },
              child: Text('投稿する'),
            ),
            SizedBox(height: 100), // 空きスペースの追加
          ],
        ),
      ),
    );
  }
}

class PostCompleteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('投稿完了'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              '投稿が完了しました！',
              style: TextStyle(fontSize: 24),
            ),
            ElevatedButton(
              style: ButtonStyle(
                fixedSize: MaterialStateProperty.all<Size>(Size(200, 50)),
              ),
              child: Text(
                'タイトルに戻る',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => FirstScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ForScreen(),
  ));
}
