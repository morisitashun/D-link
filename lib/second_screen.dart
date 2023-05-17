import 'package:flutter/material.dart';
import 'third_screen.dart';

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isSearching = false; // 検索バーの表示状態を管理するフラグ
  TextEditingController _searchController =
      TextEditingController(); // 検索バーのテキスト入力を受け取るコントローラ

  @override
  void dispose() {
    _searchController.dispose(); // コントローラの解放
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '検索',
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white, fontSize: 18),
                autofocus: true, // キーボードを自動的に表示
              )
            : Text('探す'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          color: Colors.white, // ハンバーガーメニューのアイコン色を白に変更
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching; // 検索バーの表示状態を切り替える
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          '地図を表示',
          style: TextStyle(fontSize: 24),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.green, // メニュー全体の背景色を緑に変更
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
                  Navigator.popUntil(
                    context,
                    ModalRoute.withName('/'),
                  ); // 最初の画面に戻る処理
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
                  ); // 3つ目の画面に遷移
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
