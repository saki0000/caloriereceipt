import 'dart:io';

import 'package:caloriereceipt/main.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

// 画像の確認と解析するページ
class AnalysePage extends StatefulWidget {
  final File? image;
  final String? timeZone;
  final DateTime? selectedDate;
  const AnalysePage({super.key, this.image, this.timeZone, this.selectedDate});

  @override
  State<AnalysePage> createState() => _AnalysePageState();
}

class _AnalysePageState extends State<AnalysePage> {
  Future<void> uploadImage(String uploadFileName) async {
    final FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child("images");

    UploadTask task = ref.child(uploadFileName).putFile(widget.image!);

    try {
      await task;
    } catch (e) {
      print(e);
    }
  }

  void route() async {
    if (context.mounted) {
      await Navigator.of(context).pushNamed('/result-page',
          arguments: ResultPageArg(
              widget.timeZone!, widget.selectedDate!, widget.image!));
    }
  }

  Widget build(BuildContext context) {
    print(widget.selectedDate);
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      appBar: AppBar(backgroundColor: Colors.blueGrey[100], title: Text("写真")),
      body: Center(
          child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(8),
              width: size.width * 0.8,
              child: widget.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(widget.image!),
                    )
                  : const Text("No image selected"),
            ),
            if (widget.image != null) _analysisButton()
          ],
        ),
      )),
    );
  }

  Widget _analysisButton() {
    return MaterialButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        color: Colors.blueGrey,
        textColor: Colors.white,
        onPressed: () async {
          route();
        },
        child: const Text(
          '解析',
          style: TextStyle(fontWeight: FontWeight.w700),
        ));
  }
}
