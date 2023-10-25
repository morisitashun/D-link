import 'package:flutter/material.dart';
import 'second_screen.dart';
import 'third_screen.dart';

class FirstScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'D・link',
          style: TextStyle(
            fontSize: 30,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green, // AppBarの背景色を緑色に設定
      ),
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/00.png'),
              ElevatedButton(
                style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all<Size>(Size(200, 50)),
                ),
                child: Text(
                  '探す',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SecondScreen()),
                  );
                },
              ),
              SizedBox(
                height: 25,
              ),
              ElevatedButton(
                style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all<Size>(Size(200, 50)),
                ),
                child: Text(
                  '投稿する',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ThirdScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
