import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

void main() async {
  //アプリ実行前にFlutterアプリの機能を利用する場合に宣言(初期化のような動き)
  WidgetsFlutterBinding.ensureInitialized();
  //Firebaseのパッケージを呼び出し

  //await ・・・非同期処理が完了するまで待ち、その非同期処理の結果を取り出してくれる
  //awaitを付与したら asyncも付与する
  await Firebase.initializeApp();
  runApp(MyApp());
}

//Stateless ・・・状態を保持する（動的に変化しない）
// Stateful  ・・・状態を保持しない（変化する）
// overrride ・・・上書き


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // アイコンやタスクバーの時の表示
      title: 'Baby Names',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  //createState()でState（Stateを継承したクラス）を返す
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

//Stateをextendsしたクラスを作る
class _MyHomePageState extends State<MyHomePage> {
  //ドキュメント情報を入れる箱を用意
  List<DocumentSnapshot> documentList = [];
  // List<String> name = [];
  // List<int> votes = [];

  @override
  Widget build(BuildContext context) {
    //デザインWidget
    return Scaffold(
      appBar: AppBar(title: Text('Baby Name Votes')),
      //非同期処理でWigetを生成
      body: Column(

        children: [
          SfCalendar(
            view: CalendarView.month,
            allowedViews: [
              CalendarView.month,
              CalendarView.week,
              CalendarView.day
            ],
          ),

          StreamBuilder(
            stream: initialize(),
            builder: (context, snapshot) {
              // 通信中はスピナーを表示
              if (snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              }

              // // エラー発生時はエラーメッセージを表示
              // if (snapshot.hasError) {
              //   return Text(snapshot.error.toString());
              // }

              // // データがnullでないかチェック
              // if (!snapshot.hasData) {
              //   return Text("データが存在しません");
              // }

              // documentList.forEach((elem) {
              //   name.add(elem.get('name'));
              //   votes.add(elem.get('votes'));
              // });
              // return Column(
              //   children: <Widget> [
              //     Text(name[0] + ':' + votes[0].toString()),
              //     Text(name[1] + ':' + votes[1].toString()),
              //   ],

              return Column(
                  // map ・・・要素それぞれに対して、渡した関数の処理を加えて新しく繰り返し処理する
                  // データを取得（名前と数）してテキストとしてColumnに書き出す
                //children: documentList.map((data) => Text(data.get('name') + ' : ' + data.get('votes').toString())).toList(),
              );
            },
          ),

        ],
      ),
    );
  }

  Stream<void> initialize() async* {
    final snapshot = await FirebaseFirestore.instance.collection('calendar').get();
    documentList = snapshot.docs;

    print("##################################################### initialize()");
    documentList.forEach((elem) {
      print(elem.get('start_time').toString());
      print(elem.get('start_time').toDate().toLocal().toString());
      print(elem.get('votes'));
    });
    print("##################################################### initialize()");
  }

  //getDateSource
}
//class AppointmentDataSource ex