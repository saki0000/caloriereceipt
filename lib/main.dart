import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  String? _result;

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  void _signIn() async {
    await FirebaseAuth.instance.signInAnonymously();
  }

  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final imageTemp = File(image.path);
      setState(() => this._image = imageTemp);
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future pickImageC() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      // 画像がnullの場合戻る
      if (image == null) return;

      final imageTemp = File(image.path);

      setState(() => this._image = imageTemp);
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _image != null
                ? Image.file(_image!)
                : const Text("No image selected"),
            if (_image != null) _analysisButton(),
            MaterialButton(onPressed: pickImage, child: Icon(Icons.photo)),
            Text((() {
              if (_result != null) {
                return _result!;
              } else if (_image != null) {
                return 'ボタンを押すと解析が始まります';
              } else {
                return '画像を選択';
              }
            }()))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImageC,
        tooltip: 'Pick Image',
        child: Icon(Icons.camera),
      ),
    );
  }

  Widget _analysisButton() {
    return ElevatedButton(
        onPressed: () async {
          List<int> _imageBytes = _image!.readAsBytesSync();
          String _base64Image = base64Encode(_imageBytes);
          final params = {
            "image": {"content": "$_base64Image"},
            "features": [
              {"type": "TEXT_DETECTION"}
            ],
            "imageContext": {
              "languageHints": ["ja"]
            }
          };
          final _text = await FirebaseFunctions.instance
              .httpsCallable('annotateImage')
              .call(params)
              .then((v) {
            return v.data[0]["fullTextAnnotation"]["text"];
          }).catchError((e) {
            print(e);
            print(e.details);
            print(e.message);
            return '読み取りエラーです';
          });
          setState(() {
            _result = _text;
          });
        },
        child: Text('解析'));
  }
}

class AnalyticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MyPage 2')),
      body: Center(
        child: MaterialButton(
          child: Text('Back to MyPage 1'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
