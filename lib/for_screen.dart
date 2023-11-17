import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'first_screen.dart';
import 'third_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: ForScreen(),
  ));
}

class ForScreen extends StatefulWidget {
  const ForScreen({Key? key}) : super(key: key);

  @override
  _ForScreenState createState() => _ForScreenState();
}

class _ForScreenState extends State<ForScreen> {
  var selectedValue = "コカコーラ";
  final lists = <String>[
    "コカコーラ",
    "チェリオ",
    "ダイオー",
    "BOSS",
    "アサヒ",
    "キリン",
    "100円〜",
    "食べ物系",
    "酒、タバコ",
    "アイス（１７など）",
    "その他（面白い系など）",
  ];
  Position? _currentPosition;
  final picker = ImagePicker();
  File? _image; // null安全にする
  TextEditingController _textEditingController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _mapLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Get the current location
  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _mapLoading = false;
    });
  }

  // Method to select an image from camera or gallery
  _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    } else {
      print('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '投稿画面',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ListTile(
              title: Text(
                '位置を確認してください↓',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
              onTap: () {},
            ),
            if (_mapLoading)
              CircularProgressIndicator() // Show loading indicator while waiting for the map.
            else if (_currentPosition != null)
              Container(
                height: 350,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('currentLocation'),
                      position: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                    ),
                  },
                ),
              ),
            ListTile(
              title: Text(
                'コメントを入力してください↓',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
              onTap: () {},
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
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
              onTap: () {},
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
                      ? Image.file(
                          _image!,
                        )
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
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
              onTap: () {},
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
                _savePostToFirestore();
              },
              child: Text('投稿する'),
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> _savePostToFirestore() async {
    if (_image == null || _currentPosition == null) {
      print('Error: File or location information is missing.');
      return;
    }

    try {
      final Reference storageReference =
          _storage.ref().child('images/${DateTime.now()}.jpg');
      UploadTask uploadTask = storageReference.putFile(_image!);

      await uploadTask;

      final imageUrl = await storageReference.getDownloadURL();

      await _firestore.collection('posts').add({
        'selectedValue': selectedValue,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'comment': _textEditingController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'image_url': imageUrl,
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PostCompleteScreen()),
      );
    } catch (e) {
      print('Error saving data to Firestore: $e');
    }
  }
}

class PostCompleteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '投稿完了',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '投稿が完了しました！',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 200),
            Container(
              child: ElevatedButton(
                style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all<Size>(Size(200, 50)),
                ),
                child: Text(
                  '続けて投稿する',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => ThirdScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ),
            SizedBox(height: 50),
            Container(
              child: ElevatedButton(
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
            ),
          ],
        ),
      ),
    );
  }
}
