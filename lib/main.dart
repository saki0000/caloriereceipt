import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
        routes: <String, WidgetBuilder>{
          '/my-page-1': (BuildContext context) =>
              const MyHomePage(title: 'Flutter Demo Page'),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/my-page-2') {
            final arg = settings.arguments as List<String>;
            return MaterialPageRoute(
              builder: (context) => AnalyticsPage(receipt: arg),
            );
          }
          return null;
        });
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
  List<String>? _result;

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  void _signIn() async {
    await FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> uploadImage(String uploadFileName) async {
    final FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child("images");

    UploadTask task = ref.child(uploadFileName).putFile(_image!);

    try {
      await task;
    } catch (e) {
      print(e);
    }
  }

  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final imageTemp = File(image.path);
      setState(() => _image = imageTemp);
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

      setState(() => _image = imageTemp);
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  void route() async {
    if (context.mounted) {
      await Navigator.of(context).pushNamed('/my-page-2', arguments: _result);
    }
  }

  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(children: [
        Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: size.width * 0.8,
                height: size.width * 0.8 * 4 / 3,
                child: _image != null
                    ? Image.file(_image!)
                    : const Text("No image selected")),
            if (_image != null) _analysisButton(),
          ],
        )),
        Padding(
            padding: const EdgeInsets.all(20.0),
            child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MaterialButton(
                      child: Icon(Icons.photo),
                      onPressed: pickImage,
                    ),
                    MaterialButton(
                        onPressed: pickImageC, child: Icon(Icons.camera))
                  ],
                ))),
      ]),
    );
  }

  Widget _analysisButton() {
    final db = FirebaseFirestore.instance;
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
            return v.data[0]["fullTextAnnotation"]["text"].split("\n");
          }).catchError((e) {
            print(e);
            print(e.details);
            print(e.message);
            return '読み取りエラーです';
          });
          setState(() {
            _result = _text;
          });
          db.collection("foods").add({"text": _result});

          DateTime now = DateTime.now();
          DateFormat outputFormat = DateFormat('yyyy-MM-dd-Hm');
          String date = outputFormat.format(now);
          uploadImage(date);
          // fetchP
          // roduct();
          route();
        },
        child: const Text('解析'));
  }
}

class AnalyticsPage extends StatefulWidget {
  final List<String> receipt;

  const AnalyticsPage({Key? key, required this.receipt}) : super(key: key);
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;

    return Scaffold(
      appBar: AppBar(title: const Text('MyPage 2')),
      body: ProductListPage(
        receipt: receipt,
      ),
    );
  }
}

class ProductListPage extends StatefulWidget {
  final List<String> receipt;

  const ProductListPage({Key? key, required this.receipt}) : super(key: key);
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  Future<List<SearchProducts>> _fetchProduct() async {
    List<SearchProducts> searchProducts = [];
    final firestore = FirebaseFirestore.instance;

    for (String w in widget.receipt) {
      Query<Map<String, dynamic>> query = firestore.collection('products');
      List<String> splitedWord = w.split("").toSet().toList();
      splitedWord.removeWhere((e) => ['~', '*', '/', '[', ']'].contains(e));

      for (String s in splitedWord) {
        query = query.where('wordsMap.$s', isEqualTo: true);
      }

      final snapshot = await query.get();
      List<Product> products = await Future.wait(snapshot.docs.map((doc) async {
        Uint8List? data;
        final storageRef = FirebaseStorage.instance;
        if (doc.data()['imagePath'] != null) {
          final productRef = storageRef.refFromURL(doc.data()['imagePath']);
          try {
            const oneMegabyte = 1024 * 1024;
            data = await productRef.getData(oneMegabyte);
          } on FirebaseException catch (e) {
            print(e);
          }
        }
        return Product.fromMap(doc.data(), data);
      }).toList());
      if (products.length != 0) {
        searchProducts.add(SearchProducts(searchWord: w, products: products));
      }
    }
    return searchProducts;
  }

  @override
  Widget build(BuildContext context) {
    // ListとPersonクラスを指定する
    return FutureBuilder<List<SearchProducts>>(
      // 上で定義したメソッドを使用する
      future: _fetchProduct(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final products = snapshot.data!;

        return ListView.builder(
          // Listのデータの数を数える
          itemCount: products.length,
          itemBuilder: (context, index) {
            // index番目から数えて、０〜３まで登録されているデータを表示する変数
            final product = products[index].products[0];
            // downloadImage(product.imagePath);
            return ListTile(
                // Personクラスのメンバ変数を使用する
                title: Text('Name: ${product.name}'),
                subtitle: Text('Calorie: ${product.calorie}'),
                leading: product.imageData != null
                    ? Image.memory(product.imageData!)
                    : const Icon(Icons.fastfood_outlined));
          },
        );
      },
    );
  }
}

class SearchProducts {
  final String searchWord;
  final List<Product> products;

  SearchProducts({required this.searchWord, required this.products});
}

class Product {
  final String name;
  final int calorie;
  final List<dynamic> words;
  final String? imagePath;
  final Uint8List? imageData;

  Product({
    required this.name,
    required this.calorie,
    required this.words,
    this.imagePath,
    this.imageData,
  });

  factory Product.fromMap(Map<String, dynamic> data, Uint8List? imageData) {
    return Product(
      name: data['name'],
      calorie: data['calorie'],
      words: data['words'],
      imagePath: data['imagePath'],
      imageData: imageData,
    );
  }
}
