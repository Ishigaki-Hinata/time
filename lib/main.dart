import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:googleapis/calendar/v3.dart' hide Colors;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

void main() async {
  //アプリ実行前にFlutterアプリの機能を利用する場合に宣言(初期化のような動き)
  WidgetsFlutterBinding.ensureInitialized();
  //Firebaseのパッケージを呼び出し
  FirebaseOptions options = FirebaseOptions(
      apiKey: "AIzaSyClDcqanRgHlkHY6WZ86KaUw5U9Kj9TJAs",
      appId: "1:734117201517:android:3d50954b0277906877a164",
      messagingSenderId: "734117201517",
      projectId: "sukima-time-a6d70");

  //await ・・・非同期処理が完了するまで待ち、その非同期処理の結果を取り出してくれる
  //awaitを付与したら asyncも付与する
  await Firebase.initializeApp(options: options);
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
      title: 'カレンダー',
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
  late AppointmentDataSource dataSource;
  late CollectionReference cref;
  final calendarController = CalendarController();
  GoogleSignInAccount? currentUser;
  List<MaterialColor> eventColor = [Colors.red, Colors.green, Colors.yellow];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      CalendarApi.calendarScope,
    ],
  );

  @override
  void initState() {
    super.initState();
    dataSource = getCalendarDataSource();
    cref = FirebaseFirestore.instance.collection('calendar');

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        currentUser = account;
        print('########## currentUser ' + currentUser.toString() ?? 'NULL');
      });
    });
    _googleSignIn.signInSilently();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('カレンダー')), body: buildBody(context));
  }

  Widget buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: cref.snapshots(),
      builder: (context, snapshot) {
        //読み込んでいる間の表示
        if (!snapshot.hasData) return LinearProgressIndicator();

        print(
            "##################################################### Firestore Access start");
        snapshot.data!.docs.forEach((elem) {
          print(elem.get('email').toString());
          print(elem.get('start-time').toDate().toLocal().toString());
          print(elem.get('end-time').toDate().toLocal().toString());
          print(elem.get('subject').toString());
        });
        print(
            "##################################################### Firestore Access end");

        dataSource.appointments!.clear();

        // cref.orderBy('email').snapshots().forEach((element) {
        //   print('#####'+element.get('email'));
        // });

        snapshot.data!.docs.forEach((elem) {
          final int index = 0;
          print('#####'+elem.get('email'));
          dataSource.appointments!.add(Appointment(
            startTime: elem.get('start-time').toDate().toLocal(),
            endTime: elem.get('end-time').toDate().toLocal(),
            //subject: elem.get('subject'),
            startTimeZone: '',
            endTimeZone: '',
            color: eventColor[index % eventColor.length],
          ));
        });

        dataSource.notifyListeners(
            CalendarDataSourceAction.reset, dataSource.appointments!);

        return Column(
          children: [
            //Expanded 高さを最大限に広げる
            Expanded(
              child: SfCalendar(
                dataSource: dataSource,
                view: CalendarView.week,
                showNavigationArrow: true,
                initialSelectedDate: DateTime.now(),
                controller: calendarController,
              ),
            ),

            Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                      onPressed: () {
                        if (calendarController.view == CalendarView.month) {
                          calendarController.view = CalendarView.day;
                        } else if(calendarController.view == CalendarView.day) {
                          calendarController.view = CalendarView.week;
                        }else if(calendarController.view == CalendarView.week){
                          calendarController.view = CalendarView.month;
                        }
                      },
                      child: const Text("表示切替")),
            OutlinedButton(
              onPressed: () async {
                List<Event> events = await getGoogleEventsData();

                if (currentUser == null) return;

                final QuerySnapshot userEvents = await cref
                    .where('email', isEqualTo: currentUser!.email)
                    .get();
                userEvents.docs.forEach((element) {
                  cref.doc(element.id).delete();
                });

                events.forEach((element) {
                  cref.add({
                    'email': (currentUser!.email),
                    'start-time': (element.start!.date ??
                        element.start!.dateTime!.toLocal()),
                    'end-time':
                        (element.end!.date ?? element.end!.dateTime!.toLocal()),
                    'subject': (element.summary),
                  });
                });
              },
              child: Text('予定登録'),
            ),
        ]),
          ],
        );
      },
    );
  }

  AppointmentDataSource getCalendarDataSource() {
    List<Appointment> appointments = <Appointment>[];
    return AppointmentDataSource(appointments);
  }

  Future<List<Event>> getGoogleEventsData() async {
    //Googleサインイン1人目処理→同じような処理をすると2人目が出来そう
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    print('#################################googleUser');
    final GoogleAPIClient httpClient =
        GoogleAPIClient(await googleUser!.authHeaders);
    print('#################################httpClient');
    final CalendarApi calendarAPI = CalendarApi(httpClient);
    print('#################################calendarAPI');
    final Events calEvents = await calendarAPI.events.list(
      "primary",
    );
    print('#################################calEvents');
    final List<Event> appointments = <Event>[];
    if (calEvents != null) {
      for (int i = 0; i < calEvents.items!.length; i++) {
        final Event event = calEvents.items![i];
        if (event.start == null) {
          continue;
        }

        appointments.add(event);
        print('#################################email---' +
            (googleUser.email).toString());
        print('#################################start-time---' +
            (event.start!.date ?? event.start!.dateTime!.toLocal()).toString());
        print('#################################end-time---' +
            (event.end!.date ?? event.end!.dateTime!.toLocal()).toString());
        print('#################################subject---' +
            (event.summary).toString());
      }
    }
    return appointments;
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class GoogleAPIClient extends IOClient {
  final Map<String, String> _headers;

  GoogleAPIClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(BaseRequest request) =>
      super.send(request..headers.addAll(_headers));

  @override
  Future<Response> head(Uri url, {Map<String, String>? headers}) =>
      super.head(url,
          headers: (headers != null ? (headers..addAll(_headers)) : headers));
}
