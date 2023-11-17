import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'third_screen.dart';
import 'first_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // 必要なimportを追加
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen>
    with SingleTickerProviderStateMixin {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  PanelController panelController = PanelController();
  // アニメーションコントローラーを宣言
  late AnimationController _markerBlinkController;

  CameraPosition? _initialPosition;
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.normal;
  List<Marker> markers = [];
  Position? _userPosition;
  Marker? selectedMarker; // 選択したマーカーを保持する変数

  // カテゴリーのリスト
  final List<String> categories = [
    "近い順",
    "遠い順",
    "投稿が新しい順",
    "投稿が古い順",
  ];
  final List<String> selectedValues = [
    "全表示",
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
  String selectedValue = "全表示"; // 最初の selectedValue を選択済みとして初期化
  void _onSelectedValueChanged(String? newValue) {
    setState(() {
      selectedValue = newValue ?? "全表示";
      // 選択された selectedValue に合わせて絞り込みを行う
      if (!_isSearching) {
        _fetchPostContents();
        if (selectedValue != "全表示") {
          // 絞り込んだ結果を一時的なリストに格納
          List<PostData> filteredPosts = _filterPostContents(selectedValue);
          // 一時的なリストを表示用のリストに設定
          postContents = filteredPosts;
        }
      }
    });
  }

  List<PostData> _filterPostContents(String selectedValue) {
    if (selectedValue == "全表示") {
      return postContents; // すべての投稿を返す
    } else {
      return postContents
          .where((data) => data.category == selectedValue)
          .toList(); // 選択されたカテゴリーに一致する投稿のみ返す
    }
  }

  String selectedCategory = "近い順"; // 最初のカテゴリーを選択済みとして初期化

  List<PostData> postContents = []; // Firestore から取得した投稿内容を格納

  List<PostData> _searchContents = []; // Add this line to store search results
  List<PostData> originalPostContents = []; // 1回目の選択内容を保持するリスト

  void _searchPosts(String query) {
    query = query.toLowerCase();
    setState(() {
      _searchContents = postContents.where((post) {
        return post.comment.toLowerCase().contains(query) ||
            post.category.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _reportPost(PostData reportedPost) async {
    // Firestoreに通報情報を保存
    await FirebaseFirestore.instance.collection('reported_posts').add({
      'comment': reportedPost.comment,
      'category': reportedPost.category,
      'imageUrl': reportedPost.imageUrl,
      'timestamp': reportedPost.timestamp,
      'latitude': reportedPost.latitude,
      'longitude': reportedPost.longitude,
    });

    String reportUrl =
        'https://docs.google.com/forms/d/e/1FAIpQLScjzHQ1cEOyEJbenpoS4fvpwCk5ms9O1mfe7be0dN_XsQr1bQ/viewform?usp=sf_link'; // Replace with your desired URL
    await launch(reportUrl);

    // 通報が成功した旨のメッセージを表示
    _showReportSuccessDialog();
  }

  _showReportConfirmationDialog(PostData reportedPost) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("通報の確認"),
          content: Text("本当に通報しますか？"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text("キャンセル"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                _reportPost(reportedPost); // 通報処理を実行
              },
              child: Text("通報"),
            ),
          ],
        );
      },
    );
  }

  void _showReportSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("通報成功"),
          content: Text("通報が正常に処理されました。"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchPostContents();

    // アニメーションコントローラーを初期化
    _markerBlinkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500), // アニメーションの時間を設定
    );

    // アニメーションが繰り返し実行されるように設定
    _markerBlinkController.repeat(reverse: true);

    // アニメーションの状態変化を監視し、setState()を呼んで再描画する
    _markerBlinkController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _markerBlinkController.dispose(); // アニメーションコントローラーを破棄
    super.dispose();
  }

  // 1. マップピンの点滅状態を管理するための変数を追加
  int selectedMarkerIndex = -1;
  bool isMarkerBlinking = false;

// 2. マーカーを作成するメソッド
  Marker _createMarker(PostData postData, int index) {
    return Marker(
      markerId: MarkerId(postData.timestamp.toString()),
      position: LatLng(postData.latitude, postData.longitude),
      icon: index == selectedMarkerIndex && isMarkerBlinking
          ? _createBlinkingMarkerIcon()
          : BitmapDescriptor.defaultMarker,
      onTap: () {
        // マーカーがタップされたときの処理
        _startBlinkingMarkerForIndex(index); // マーカー点滅を開始
      },
    );
  }

  final itemHeight = 200.0; // Set this to the height of each item in your list
// 3. マーカー点滅を開始する関数
  void _startBlinkingMarkerForIndex(int index) {
    setState(() {
      selectedMarkerIndex = index;
      isMarkerBlinking = true;
      _startBlinkingMarker();
    });
    // 1. 選択されたマーカーのインデックスを保存
    selectedMarkerIndex = index;
    final scrollController = ScrollController();

    // 2. マップピンがタップされたときにリストビューをスクロールする
    final selectedPostData = postContents[index];
    final selectedIndex = postContents.indexOf(selectedPostData);
    if (selectedIndex != -1) {
      scrollController.animateTo(
        selectedIndex * itemHeight, // 一つのアイテムの高さを考慮してスクロール位置を計算
        duration: Duration(milliseconds: 500), // スクロールアニメーションの時間
        curve: Curves.easeOut, // アニメーションカーブ
      );
    }

    // 4. アニメーションを開始
    isMarkerBlinking = true;
    _startBlinkingMarker();
    // 1. 選択されたマーカーのインスタンスを取得
    Marker selectedMarker = markers[index];

    // 2. カメラを選択されたマーカーの位置に移動
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: selectedMarker.position,
          zoom: 35, // マーカーが拡大されて表示されるように設定
        ),
      ),
    );

    // 3. アニメーションを開始
    setState(() {
      selectedMarkerIndex = index;
      isMarkerBlinking = true;
      _startBlinkingMarker();
    });
  }

// 4. マーカー点滅を停止する関数
  void _stopBlinkingMarker() {
    setState(() {
      isMarkerBlinking = false;
      selectedMarkerIndex = -1;
    });
  }

// 5. マーカー点滅を開始する関数
  void _startBlinkingMarker() {
    // マーカーを一定時間点滅させた後、点滅を停止する
    Future.delayed(Duration(seconds: 3), _stopBlinkingMarker);
  }

  // マーカーの色を変更するメソッド
  void _changeMarkerColor(Marker marker) {
    setState(() {
      selectedMarker = marker;
    });
  }

  BitmapDescriptor _createBlinkingMarkerIcon() {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  Marker _createMarkerWithBlinkEffect(PostData postData) {
    return _createMarker(postData, _markerBlinkController.value.toInt());
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
        _userPosition = position; // ユーザーの位置を保存
      });
    } catch (e) {
      print('位置情報の取得に失敗しました: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });

    if (_initialPosition != null) {
      // 初期カメラ位置を設定
      _mapController
          ?.animateCamera(CameraUpdate.newCameraPosition(_initialPosition!));
      // カメラのズームレベルを指定
      double zoomLevel = 15.0; // 例としてズームレベル 15 を指定
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          _initialPosition!.target, // 現在の位置を維持
          zoomLevel,
        ),
      );
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType =
          _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  Future<void> _fetchPostContents() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .get();

    // Clear the list first
    markers.clear();
    postContents.clear();

    for (int index = 0; index < snapshot.docs.length; index++) {
      DocumentSnapshot doc = snapshot.docs[index]; // ここで doc を初期化
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      if (data != null) {
        double latitude = data['latitude'] as double;
        double longitude = data['longitude'] as double;
        if (selectedValue == "全表示" || data['selectedValue'] == selectedValue) {
          markers.add(_createMarker(
            PostData(
              data['comment'] as String? ?? '',
              data['selectedValue'] as String? ?? '',
              data['image_url'] as String? ?? '',
              data['timestamp'] as Timestamp,
              latitude,
              longitude,
            ),
            index,
          ));

          postContents.add(PostData(
            data['comment'] as String? ?? '',
            data['selectedValue'] as String? ?? '',
            data['image_url'] as String? ?? '',
            data['timestamp'] as Timestamp,
            latitude,
            longitude,
          ));
        }
      }
    }
  }

  // カテゴリー変更時に呼ばれるメソッド
  void _onCategoryChanged(String? newValue) {
    setState(() {
      selectedCategory = newValue ?? "近い順";
      if (!_isSearching) {
        // ワード検索中でない場合のみパネルを操作
        if (selectedCategory == "投稿が新しい順") {
          // "投稿が新しい順" の場合はデータを新しい順に並び替え
          postContents.sort((a, b) {
            return b.timestamp.compareTo(a.timestamp);
          });
        } else if (selectedCategory == "投稿が古い順") {
          // "投稿が古い順" の場合はデータを古い順に並び替え
          postContents.sort((a, b) {
            return a.timestamp.compareTo(b.timestamp);
          });
        } else if (selectedCategory == "近い順" && _userPosition != null) {
          // "近い順" の場合、投稿を距離順に並び替え
          postContents.sort((a, b) {
            final double distanceToA = _calculateDistance(
              a.latitude,
              a.longitude,
              _userPosition!.latitude,
              _userPosition!.longitude,
            );
            final double distanceToB = _calculateDistance(
              b.latitude,
              b.longitude,
              _userPosition!.latitude,
              _userPosition!.longitude,
            );
            return distanceToA.compareTo(distanceToB);
          });
        } else if (selectedCategory == "遠い順" && _userPosition != null) {
          // "遠い順" の場合、投稿を距離順に逆順に並び替え
          postContents.sort((a, b) {
            final double distanceToA = _calculateDistance(
              a.latitude,
              a.longitude,
              _userPosition!.latitude,
              _userPosition!.longitude,
            );
            final double distanceToB = _calculateDistance(
              b.latitude,
              b.longitude,
              _userPosition!.latitude,
              _userPosition!.longitude,
            );
            return distanceToB.compareTo(distanceToA);
          });
        } else {
          // 他のカテゴリーの場合はデータを元の順序に戻す
          _fetchPostContents();
        }
      }
    });
  }

  // 2点間の距離を計算
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const int earthRadius = 6371; // 地球の半径 (km)
    final double lat1Rad = _degreesToRadians(lat1);
    final double lon1Rad = _degreesToRadians(lon1);
    final double lat2Rad = _degreesToRadians(lat2);
    final double lon2Rad = _degreesToRadians(lon2);

    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // 角度をラジアンに変換
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
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
      resizeToAvoidBottomInset: false, // この行を追加
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
                onChanged: _searchPosts, // テキストが変更されたときに検索機能を呼び出す
              )
            : Text(
                '探す',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: mapWidth,
              height: mapHeight,
              child: GoogleMap(
                initialCameraPosition: _initialPosition ??
                    CameraPosition(
                      target: LatLng(34, 135),
                      zoom: 5,
                    ),
                onMapCreated: _onMapCreated,
                markers: Set<Marker>.from(markers),
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
                ),
                SizedBox(height: 5),
                Container(
                  width: 350,
                  height: 45,
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Container(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _onCategoryChanged,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    dropdownColor: Colors.green,
                  ),
                ),
                Container(
                  width: 350,
                  height: 45,
                  child: DropdownButton<String>(
                    value: selectedValue,
                    items: selectedValues.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Container(
                          height: itemHeight, // 選択肢の高さを設定
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged:
                        // _onCategoryChanged メソッドを呼び出す
                        _onSelectedValueChanged,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    dropdownColor: Colors.green,
                    isExpanded: true, // Set this property to true
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _isSearching
                        ? _searchContents.length
                        : postContents.length,
                    itemBuilder: (context, index) {
                      String formattedTime = DateFormat('yyyy-MM-dd')
                          .format(postContents[index].timestamp.toDate());
                      return ListTile(
                        title: Row(
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: postContents[index].imageUrl.isNotEmpty
                                  ? Image.network(
                                      postContents[index].imageUrl,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    )
                                  : Text(
                                      '画像がありません',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    postContents[index].category,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Divider(
                                    color: Colors.white,
                                    thickness: 1,
                                    height: 20,
                                  ),
                                  Text(
                                    postContents[index].comment.isNotEmpty
                                        ? postContents[index].comment
                                        : "コメントはありません",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Divider(
                                    color: Colors.white,
                                    thickness: 1,
                                    height: 20,
                                  ),
                                  Text(
                                    "$formattedTime",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // 2. マップピン点滅用のボタン
                                  ListTile(
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end, // ボタンを右に寄せる
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            _startBlinkingMarkerForIndex(index);
                                            _changeMarkerColor(markers[index]);
                                          },
                                          child: Icon(Icons.search),
                                        ),
                                        SizedBox(width: 1.5), // ボタン間のスペースを調整
                                        ElevatedButton(
                                          onPressed: () {
                                            _showReportConfirmationDialog(
                                                postContents[index]);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            primary: Colors.white, // ボタンの背景色
                                            onPrimary:
                                                Colors.red, // テキストカラーを赤に変更
                                          ),
                                          child: Text("通報"),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
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
                  _toggleMapType();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostData {
  final String comment;
  final String category;
  final String imageUrl;
  final Timestamp timestamp;
  final double latitude;
  final double longitude;

  PostData(this.comment, this.category, this.imageUrl, this.timestamp,
      this.latitude, this.longitude);
}

void main() {
  runApp(MaterialApp(
    home: SecondScreen(),
  ));
}
