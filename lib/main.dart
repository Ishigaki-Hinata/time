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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Baby Name Votes')),
        body: buildBody(context)
    );
  }

  Widget buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('baby').snapshots(),
      builder: (context, snapshot) {
        //読み込んでいる間の表示
        if (!snapshot.hasData) return LinearProgressIndicator();

        print("##################################################### Firestore Access start");
        snapshot.data!.docs.forEach((elem) {
          print(elem.get('name'));
          print(elem.get('votes'));
        });
        print("##################################################### Firestore Access end");
        return Column(
          children: [
            //Expanded 高さを最大限に広げる
            Expanded(
                child: Text("てすと")
            ),
            OutlinedButton(
              onPressed: () {
                snapshot.data!.docs[0].reference.update({'votes': FieldValue.increment(1)});
              },
              child: Text('ぼたん'),
            ),
          ],
        );
      },
    );
  }
}
