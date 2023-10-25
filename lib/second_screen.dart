import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'third_screen.dart';
import 'first_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  PanelController panelController = PanelController();

  CameraPosition? _initialPosition;
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.normal;

  // カテゴリーのリスト
  final List<String> categories = [
    "近い順",
    "遠い順",
    "投稿が新しい順",
    "投稿が古い順",
  ];

  String selectedCategory = "近い順"; // 最初のカテゴリーを選択済みとして初期化

  List<String> postContents = []; // Firestore から取得した投稿内容を格納

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchPostContents(); // Firestore から投稿内容を取得
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _initialPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        );
      });
    } catch (e) {
      print('位置情報の取得に失敗しました: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
      _mapController
          ?.animateCamera(CameraUpdate.newCameraPosition(_initialPosition!));
    });
  }

  void _moveToLocation(LatLng location) {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(location));
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType =
          _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  Future<void> _fetchPostContents() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('posts').get();
    postContents.clear(); // Clear the list first
    for (QueryDocumentSnapshot doc in snapshot.docs) {
      Map<String, dynamic>? data =
          doc.data() as Map<String, dynamic>?; // データをMapとしてキャスト
      if (data != null) {
        var content = data['content'] as String?;
        if (content != null) {
          postContents.add(content);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double mapWidth = MediaQuery.of(context).size.width * 1;
    final double mapHeight = MediaQuery.of(context).size.height * 0.775;
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '場所やキーワードを検索',
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white, fontSize: 18),
                autofocus: true,
              )
            : Text(
                '探す',
                style: TextStyle(
                  color: Colors.white, // タイトルの色を白に設定
                  fontSize: 22,
                ),
              ),
        backgroundColor: Colors.green, // AppBarの背景色を緑に設定
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
              });
            },
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // ドロップダウンボタンの高さ
            child: Container(
              width: mapWidth,
              height: mapHeight,
              child: GoogleMap(
                initialCameraPosition:
                    _initialPosition ?? CameraPosition(target: LatLng(0, 0)),
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                compassEnabled: true,
                mapType: _currentMapType,
              ),
            ),
          ),
          SlidingUpPanel(
            panel: Column(
              children: [
                SizedBox(height: 10),
                Icon(Icons.maximize, color: Colors.white, size: 40),

                ListTile(
                  title: Text(
                    '投稿一覧',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ), // ドラッグハンドルのアイコン
                SizedBox(height: 5),
                // カテゴリー選択用のドロップダウンメニュー
                Container(
                  width: 250, // ドロップダウンボタンの幅
                  height: 50, // ドロップダウンボタンの高さ
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                      });
                    },
                    style: TextStyle(
                      fontSize: 30, // ドロップダウンボタンの文字の大きさ
                      color: Colors.white, // ドロップダウンボタンの文字の色
                    ),
                    dropdownColor: Colors.green, // ドロップダウンメニューの背景色
                  ),
                ),
                // Firestore から取得したテキストをリストビューで表示
                Expanded(
                  child: ListView.builder(
                    itemCount: postContents.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          postContents[index],
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            color: Colors.green,
            borderRadius: radius,
          )
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.green,
          child: ListView(
            children: [
              ListTile(
                title: Text(
                  'メニュー一覧',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  'タイトルに戻る',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => FirstScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
              ListTile(
                title: Text(
                  '投稿する',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThirdScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(
                  '地図のスタイルを切り替える',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  _toggleMapType(); // 地図のスタイルを切り替えるメソッドを呼び出す
                  Navigator.pop(context); // Drawerを閉じる
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
