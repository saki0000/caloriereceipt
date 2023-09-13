import 'dart:async';
import 'dart:io';

import 'package:caloriereceipt/foods_page.dart';
import 'package:caloriereceipt/result_pge.dart';
import 'package:caloriereceipt/time_zone_calorie_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'analyse_page.dart';
import 'firebase_options.dart';

// main　最初の画面
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // firebaseの設定
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class AnalysePageArg {
  final File? image;
  final String? timeZone;
  final DateTime? selectedDate;

  AnalysePageArg(this.image, this.timeZone, this.selectedDate);
}

class ResultPageArg {
  final List<String> receipt;
  final String timeZone;
  final DateTime selectedDate;

  ResultPageArg(this.receipt, this.timeZone, this.selectedDate);
}

class FoodsPageArg {
  final DateTime selectedDate;
  final String timeZone;
  FoodsPageArg(this.selectedDate, this.timeZone);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
        onGenerateRoute: (settings) {
          if (settings.name == '/result-page') {
            final arg = settings.arguments as ResultPageArg;
            return MaterialPageRoute(
              builder: (context) => ResultPage(
                receipt: arg.receipt,
                timeZone: arg.timeZone,
                selectedDate: arg.selectedDate,
              ),
            );
          } else if (settings.name == '/analyse-page') {
            final arg = settings.arguments as AnalysePageArg;
            return MaterialPageRoute(
                builder: (context) => AnalysePage(
                      image: arg.image,
                      timeZone: arg.timeZone,
                      selectedDate: arg.selectedDate,
                    ));
          } else if (settings.name == '/home') {
            final arg = settings.arguments as DateTime;
            return MaterialPageRoute(
                builder: (context) => MyHomePage(
                      selectedDate: arg,
                    ));
          } else if (settings.name == "/foods-page") {
            final arg = settings.arguments as FoodsPageArg;
            return MaterialPageRoute(
                builder: (context) => FoodsPage(
                      selectedDate: arg.selectedDate,
                      timeZone: arg.timeZone,
                    ));
          }
          ;
          return null;
        });
  }
}

// home page
class MyHomePage extends StatefulWidget {
  final DateTime? selectedDate;
  const MyHomePage({super.key, this.selectedDate});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 画像
  File? _image;
  // 選択した日付
  DateTime? _selectedDate;
  // 選択した日付の週
  List<DateTime>? _weekArray;
  // ご飯の時間
  String? _timeZone;
  // カレンダーで使うやつ
  DateTime? _selectedModalDate;

  @override
  // 関数
  void initState() {
    super.initState();

    // 今日の日付を取得
    DateTime today = DateTime.now();

    setState(() {
      _selectedDate = widget.selectedDate ?? today;
      _selectedModalDate = widget.selectedDate ?? today;

      // 週の日付をリストに追加
      List<DateTime> weekArray = [];

      DateTime? startWeek = _selectedDate!.weekday == 7
          ? _selectedDate
          : _selectedDate!.subtract(Duration(days: _selectedDate!.weekday));
      for (var i = 0; i < 7; i++) {
        DateTime addDate = startWeek!.add(Duration(days: i));
        weekArray.add(addDate);
      }
      _weekArray = weekArray;
    });

    _signIn();
  }

  void _signIn() async {
    await FirebaseAuth.instance.signInAnonymously();
  }

  // 画像をライブラリから選択して画面遷移を関数
  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final imageTemp = File(image.path);
      setState(() => _image = imageTemp);
      route();
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  // カメラを使い画面遷移を関数
  Future pickImageC() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      // 画像がnullの場合戻る
      if (image == null) return;

      final imageTemp = File(image.path);

      setState(() => _image = imageTemp);
      route();
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  // 画面遷移をする関数
  void route() async {
    if (context.mounted) {
      await Navigator.of(context).pushNamed('/analyse-page',
          arguments: AnalysePageArg(_image!, _timeZone!, _selectedDate!));
    }
  }

  // firestoreから選択した日付のデータを取得する関数
  Future _fetchCalories() async {
    final date = DateFormat("y-MM-dd").format(_selectedDate!);
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection("calories")
        .where("date", isEqualTo: date)
        .get();
    final calories =
        snapshot.docs.map((doc) => Calorie.fromMap(doc.data())).toList();
    return calories;
  }

  // 下から出てくるモーダル カメラかライブラリを選ぶ
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final String title = DateFormat("y/MM/dd").format(_selectedDate!);
    final List<String> weeks = ["s", "m", "t", "w", "t", "f", "s"];

    void routeCameraModal() {
      Navigator.of(context).pop();
      showModalBottomSheet(
          context: context,
          builder: (context) => Container(
              padding: EdgeInsets.all(20),
              height: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.photo,
                          size: 30,
                        ),
                        onPressed: pickImage,
                      ),
                      Text("ライブラリから選択")
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                          onPressed: pickImageC,
                          icon: Icon(
                            Icons.camera,
                            size: 30,
                          )),
                      Text("カメラで写真を撮る")
                    ],
                  )
                ],
              )));
    }

    return FutureBuilder(
        future: _fetchCalories(),
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // エラー
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // home画面で使うデータ
          final calories = snapshot.data!;
          num todayCalorie = 0;
          // 朝昼晩のデータを入れる
          Map<String, Map<String, dynamic>> timeZoneCalorieData = {
            "breakfast": {"calorie": 0, "foods": []},
            "lunch": {"calorie": 0, "foods": []},
            "dinner": {"calorie": 0, "foods": []},
            "snack": {"calorie": 0, "foods": []},
          };
          for (var c in calories) {
            todayCalorie += c.calorie;
            switch (c.timeZone) {
              case "breakfast":
                final breakfastMap = timeZoneCalorieData["breakfast"];
                breakfastMap!["foods"].add(c);
                breakfastMap["calorie"] += c.calorie;
                break;
              case "lunch":
                final lunchMap = timeZoneCalorieData["lunch"];
                lunchMap!["foods"].add(c);
                lunchMap["calorie"] += c.calorie;
                break;
              case "dinner":
                final dinnerMap = timeZoneCalorieData["dinner"];
                dinnerMap!["foods"].add(c);
                dinnerMap["calorie"] += c.calorie;
                break;
              case "snack":
                final snackMap = timeZoneCalorieData["snack"];
                snackMap!["foods"].add(c);
                snackMap["calorie"] += c.calorie;
                break;
            }
          }

          return Scaffold(
              backgroundColor: Colors.blueGrey[50],
              // 一番上のやつ
              appBar: AppBar(
                title: Text(title),
                backgroundColor: Colors.blueGrey[50],
                actions: [
                  // カレンダーボタン
                  IconButton(
                    icon: Icon(Icons.calendar_month),
                    onPressed: () {
                      showModalBottomSheet(
                          context: context,
                          builder: (context) => StatefulBuilder(
                              builder: (context, StateSetter setModalState) =>
                                  Container(
                                    height: 800,
                                    margin: EdgeInsets.all(16),
                                    child: Column(children: [
                                      TableCalendar(
                                        firstDay:
                                            DateTime(DateTime.now().year, 1, 1),
                                        lastDay: DateTime(
                                            DateTime.now().year, 12, 31),
                                        focusedDay: DateTime.now(),
                                        selectedDayPredicate: (day) {
                                          return isSameDay(
                                              _selectedModalDate, day);
                                        },
                                        onDaySelected:
                                            (selectedDay, focusedDay) {
                                          print(_selectedDate);
                                          setModalState(() {
                                            _selectedModalDate = selectedDay;
                                          });
                                          setState(() {
                                            _selectedDate = selectedDay;
                                            List<DateTime> weekArray = [];

                                            DateTime? startWeek =
                                                _selectedDate!.weekday == 7
                                                    ? _selectedDate
                                                    : _selectedDate!.subtract(
                                                        Duration(
                                                            days: _selectedDate!
                                                                .weekday));
                                            for (var i = 0; i < 7; i++) {
                                              DateTime addDate = startWeek!
                                                  .add(Duration(days: i));
                                              weekArray.add(addDate);
                                            }
                                            _weekArray = weekArray;
                                          });
                                        },
                                      )
                                    ]),
                                  )));
                    },
                  )
                ],
              ),
              // body
              body: SingleChildScrollView(
                  child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (int i = 0; i < 7; i++)
                        Column(
                          children: [
                            Text(weeks[i],
                                style: const TextStyle(color: Colors.black38)),
                            GestureDetector(
                              onTap: () => setState(() {
                                _selectedDate = _weekArray![i];
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: (_selectedDate == _weekArray![i])
                                    ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        border:
                                            Border.all(color: Colors.black45))
                                    : const BoxDecoration(),
                                child: Text(
                                  "${_weekArray![i].day}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                    ],
                  ),
                  Container(
                      width: size.width * 0.6,
                      height: size.width * 0.6,
                      alignment: const Alignment(0.0, 0.0),
                      margin: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(size.width * 0.3),
                          color: Colors.blueGrey),
                      child: Text('${todayCalorie}kcal',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold))),
                  TimeZoneCalorieWidget(
                    timeZone: "breakfast",
                    calorie: timeZoneCalorieData["breakfast"]!["calorie"] ?? 0,
                    icon: Icons.sunny_snowing,
                    products: timeZoneCalorieData["breakfast"]!["foods"] ?? [],
                    selectedDate: _selectedDate ?? DateTime.now(),
                    setState: setState,
                  ),
                  TimeZoneCalorieWidget(
                    timeZone: "lunch",
                    calorie: timeZoneCalorieData["lunch"]!["calorie"] ?? 0,
                    icon: Icons.sunny,
                    products: timeZoneCalorieData["lunch"]!["foods"] ?? [],
                    selectedDate: _selectedDate ?? DateTime.now(),
                    setState: setState,
                  ),
                  TimeZoneCalorieWidget(
                    timeZone: "dinner",
                    calorie: timeZoneCalorieData["dinner"]!["calorie"] ?? 0,
                    icon: Icons.nightlight,
                    products: timeZoneCalorieData["dinner"]!["foods"] ?? [],
                    selectedDate: _selectedDate ?? DateTime.now(),
                    setState: setState,
                  ),
                  TimeZoneCalorieWidget(
                      timeZone: "snack",
                      calorie: timeZoneCalorieData["snack"]!["calorie"] ?? 0,
                      icon: Icons.local_cafe,
                      products: timeZoneCalorieData["snack"]!["foods"] ?? [],
                      selectedDate: _selectedDate ?? DateTime.now(),
                      setState: setState),
                  SizedBox(height: 80)
                ],
              )),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  // modal
                  showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                            margin: EdgeInsets.all(20),
                            alignment: Alignment.center,
                            height: 200,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _timeZone = "breakfast";
                                          });
                                          routeCameraModal();
                                        },
                                        icon: const Icon(
                                          Icons.sunny_snowing,
                                          size: 30,
                                        )),
                                    const Text(
                                      "朝食",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    )
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _timeZone = "lunch";
                                          });
                                          routeCameraModal();
                                        },
                                        icon: const Icon(
                                          Icons.sunny,
                                          size: 30,
                                        )),
                                    const Text(
                                      "昼食",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    )
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _timeZone = "dinner";
                                          });
                                          routeCameraModal();
                                        },
                                        icon: const Icon(
                                          Icons.nightlight,
                                          size: 30,
                                        )),
                                    const Text(
                                      "夕食",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    )
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _timeZone = "snack";
                                          });
                                          routeCameraModal();
                                        },
                                        icon: const Icon(Icons.local_cafe,
                                            size: 30)),
                                    const Text(
                                      "間食",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ));
                },
                backgroundColor: Colors.blueGrey[700],
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ));
        }));
  }
}

class Calorie {
  final String name;
  final int calorie;
  final String? imageURL;
  final String date;
  final String timeZone;

  Calorie(
      {required this.name,
      required this.calorie,
      required this.imageURL,
      required this.date,
      required this.timeZone});

  factory Calorie.fromMap(Map<String, dynamic> data) {
    return Calorie(
        name: data["name"],
        calorie: data["calorie"],
        imageURL: data["imageURL"],
        date: data["date"],
        timeZone: data["timeZone"]);
  }
}
