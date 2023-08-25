import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ResultPage extends StatefulWidget {
  final List<String> receipt;
  final String timeZone;
  final DateTime selectedDate;

  const ResultPage(
      {Key? key,
      required this.receipt,
      required this.timeZone,
      required this.selectedDate})
      : super(key: key);
  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('検索結果'),
        backgroundColor: Colors.blueGrey[50],
      ),
      backgroundColor: Colors.blueGrey[50],
      body: ProductListPage(
        receipt: receipt,
        timeZone: widget.timeZone,
        selectedDate: widget.selectedDate,
      ),
    );
  }
}

class ProductListPage extends StatefulWidget {
  final List<String> receipt;
  final String timeZone;
  final DateTime selectedDate;

  const ProductListPage(
      {Key? key,
      required this.receipt,
      required this.timeZone,
      required this.selectedDate})
      : super(key: key);
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<SearchProducts>> _data;
  List<int>? _selectModalIndexes;
  List<int>? _selectIndexes;

  Future<List<SearchProducts>> _fetchProduct() async {
    List<SearchProducts> searchProducts = [];
    final firestore = FirebaseFirestore.instance;

    for (String w in widget.receipt) {
      Query<Map<String, dynamic>> query = firestore.collection('products');
      List<String> splitedWord = w.split("").toSet().toList();
      splitedWord
          .removeWhere((e) => ['~', '*', '/', '[', ']', ' ', "ﾞ"].contains(e));

      for (var i = 0; i < splitedWord.length; i++) {
        splitedWord[i] = convertText(input: splitedWord[i]);
      }

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
          } on FirebaseException {}
        }
        return Product.fromMap(doc.data(), data, doc.id);
      }).toList());
      if (products.isNotEmpty) {
        searchProducts.add(SearchProducts(searchWord: w, products: products));
      }
      int length = searchProducts.length;
      _selectIndexes = List.filled(length, 0);
    }
    return searchProducts;
  }

  void route() async {
    if (context.mounted) {
      await Navigator.of(context)
          .pushNamed('/home', arguments: widget.selectedDate);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _data = _fetchProduct();
  }

  Widget ListContainer(Product product, bool isModal,
      List<SearchProducts>? products, int? index) {
    double width = isModal
        ? MediaQuery.of(context).size.width * 0.85
        : MediaQuery.of(context).size.width * 0.75;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: width,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              product.imageData != null
                  ? SizedBox(
                      width: 50,
                      height: 50,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(product.imageData!)),
                    )
                  : const Icon(Icons.fastfood_outlined),
              Flexible(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(
                    'Calorie: ${product.calorie}',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  )
                ],
              )),
            ],
          ),
        ),
        isModal
            ? Container()
            : IconButton(
                onPressed: () {
                  products!.removeAt(index!);
                  setState(() {});
                },
                icon: const Icon(Icons.delete))
      ],
    );
  }

  Widget build(BuildContext context) {
    // ListとPersonクラスを指定する
    print(widget.selectedDate);
    return FutureBuilder<List<SearchProducts>>(
      // 上で定義したメソッドを使用する
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final products = snapshot.data!;
        _selectIndexes ??= List.filled(products.length, 0);
        _selectModalIndexes ??= List.filled(products.length, 0);

        return Stack(
          children: [
            ListView.builder(
                // Listのデータの数を数える
                itemCount: products.length,
                itemBuilder: (context, index) {
                  // index番目から数えて、０〜３まで登録されているデータを表示する変数
                  var product =
                      products[index].products[_selectIndexes![index]];
                  final searchWord = products[index].searchWord;
                  print(_selectIndexes![index]);
                  // downloadImage(product.imagePath);
                  return Stack(
                    alignment: AlignmentDirectional.topEnd,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  // if (products[index].products.length != 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            searchWord,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          IconButton(
                                              onPressed: () {
                                                showModalBottomSheet(
                                                    backgroundColor:
                                                        Colors.white,
                                                    context: context,
                                                    builder: (context) =>
                                                        StatefulBuilder(
                                                            builder: ((context,
                                                                    StateSetter
                                                                        setModalState) =>
                                                                Container(
                                                                    margin: const EdgeInsets
                                                                            .symmetric(
                                                                        vertical:
                                                                            16),
                                                                    height: 500,
                                                                    child: ListView.builder(
                                                                        itemCount: products[index].products.length,
                                                                        itemBuilder: (context, i) {
                                                                          return GestureDetector(
                                                                            onTap:
                                                                                () {
                                                                              setState(() {
                                                                                _selectModalIndexes![index] = i;
                                                                              });
                                                                              setModalState(
                                                                                () {
                                                                                  _selectIndexes![index] = i;
                                                                                },
                                                                              );
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              margin: EdgeInsets.all(8),
                                                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                                                                              alignment: Alignment.center,
                                                                              decoration: BoxDecoration(border: i == _selectIndexes![index] ? Border.all(color: Colors.blue) : null, borderRadius: BorderRadius.circular(16), color: Colors.white),
                                                                              child: ListContainer(products[index].products[i], true, null, null),
                                                                            ),
                                                                          );
                                                                        })))));
                                              },
                                              icon: const Icon(
                                                  Icons.chevron_right)),
                                        ]),
                                  ),
                                  // if (products[index].products.length != 1)
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: const Divider()),
                                  ListContainer(product, false, products, index)
                                ],
                              )
                            ],
                          )
                          // Personクラスのメンバ変数を使用する

                          ),
                      if (products[index].products.length != 1)
                        Stack(
                          alignment: AlignmentDirectional.center,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                  color: Colors.blueGrey,
                                  shape: BoxShape.circle),
                            ),
                            Text(
                              '${products[index].products.length}',
                              style: const TextStyle(color: Colors.white),
                            )
                          ],
                        ),
                    ],
                  );
                }),
            Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.all(8),
                child: MaterialButton(
                    minWidth: MediaQuery.of(context).size.width,
                    color: Colors.blueGrey[300],
                    onPressed: () async {
                      final db = FirebaseFirestore.instance;
                      final String date =
                          DateFormat("y-MM-dd").format(widget.selectedDate);
                      final query = db.collection("calories");

                      for (var i = 0; i < products.length; i++) {
                        final product = {
                          "name": products[i].products[_selectIndexes![i]].name,
                          "calorie":
                              products[i].products[_selectIndexes![i]].calorie,
                          "imagePath": products[i]
                              .products[_selectIndexes![i]]
                              .imagePath,
                          "timeZone": widget.timeZone,
                          "date": date,
                        };
                        await query.add(product);
                      }
                      route();
                    },
                    child: const Text("登録",
                        style: TextStyle(color: Colors.white))))
          ],
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
  final String? imagePath;
  final Uint8List? imageData;
  final String? id;

  Product({
    required this.name,
    required this.calorie,
    this.imagePath,
    this.imageData,
    this.id,
  });

  factory Product.fromMap(
      Map<String, dynamic> data, Uint8List? imageData, String? id) {
    return Product(
      name: data['name'],
      calorie: data['calorie'],
      imagePath: data['imagePath'],
      imageData: imageData,
      id: id,
    );
  }
}

String convertText({required String input}) {
  final fullWidthKana = getFullWidthKana(input: input);
  final halfWidthAlphanumeric =
      getHalfWidthAlphanumericCharacters(input: fullWidthKana);
  return halfWidthAlphanumeric;
}

String getFullWidthKana({required String input}) {
  final fullWidthKana =
      input.replaceAllMapped(RegExp('[ｱ-ﾝﾞﾟｰァ-ｮ]ﾞ?ﾟ?'), (Match match) {
    final result = kanaMap[match.group(0)!];
    return result ?? match.group(0)!;
  });
  return fullWidthKana;
}

String getHalfWidthAlphanumericCharacters({required String input}) {
  final halfWidthAlphanumericCharacters =
      input.replaceAllMapped(RegExp('[Ａ-Ｚａ-ｚ０-９]'), (Match match) {
    final result = alphanumericMap[match.group(0)!];
    return result ?? '';
  });
  return halfWidthAlphanumericCharacters.isEmpty
      ? input
      : halfWidthAlphanumericCharacters;
}

final kanaMap = {
  'ｱ': 'ア',
  'ｲ': 'イ',
  'ｳ': 'ウ',
  'ｴ': 'エ',
  'ｵ': 'オ',
  'ｶ': 'カ',
  'ｷ': 'キ',
  'ｸ': 'ク',
  'ｹ': 'ケ',
  'ｺ': 'コ',
  'ｻ': 'サ',
  'ｼ': 'シ',
  'ｽ': 'ス',
  'ｾ': 'セ',
  'ｿ': 'ソ',
  'ﾀ': 'タ',
  'ﾁ': 'チ',
  'ﾂ': 'ツ',
  'ﾃ': 'テ',
  'ﾄ': 'ト',
  'ﾅ': 'ナ',
  'ﾆ': 'ニ',
  'ﾇ': 'ヌ',
  'ﾈ': 'ネ',
  'ﾉ': 'ノ',
  'ﾊ': 'ハ',
  'ﾋ': 'ヒ',
  'ﾌ': 'フ',
  'ﾍ': 'ヘ',
  'ﾎ': 'ホ',
  'ﾏ': 'マ',
  'ﾐ': 'ミ',
  'ﾑ': 'ム',
  'ﾒ': 'メ',
  'ﾓ': 'モ',
  'ﾔ': 'ヤ',
  'ﾕ': 'ユ',
  'ﾖ': 'ヨ',
  'ﾗ': 'ラ',
  'ﾘ': 'リ',
  'ﾙ': 'ル',
  'ﾚ': 'レ',
  'ﾛ': 'ロ',
  'ﾜ': 'ワ',
  'ｦ': 'ヲ',
  'ﾝ': 'ン',
  'ｳﾞ': 'ヴ',
  'ｶﾞ': 'ガ',
  'ｷﾞ': 'ギ',
  'ｸﾞ': 'グ',
  'ｹﾞ': 'ゲ',
  'ｺﾞ': 'ゴ',
  'ｻﾞ': 'ザ',
  'ｼﾞ': 'ジ',
  'ｽﾞ': 'ズ',
  'ｾﾞ': 'ゼ',
  'ｿﾞ': 'ゾ',
  'ﾀﾞ': 'ダ',
  'ﾁﾞ': 'ヂ',
  'ﾂﾞ': 'ヅ',
  'ﾃﾞ': 'デ',
  'ﾄﾞ': 'ド',
  'ﾊﾞ': 'バ',
  'ﾋﾞ': 'ビ',
  'ﾌﾞ': 'ブ',
  'ﾍﾞ': 'ベ',
  'ﾎﾞ': 'ボ',
  'ﾊﾟ': 'パ',
  'ﾋﾟ': 'ピ',
  'ﾌﾟ': 'プ',
  'ﾍﾟ': 'ペ',
  'ﾎﾟ': 'ポ',
  'ｧ': 'ァ',
  'ｨ': 'ィ',
  'ｩ': 'ゥ',
  'ｪ': 'ェ',
  'ｫ': 'ォ',
  'ｯ': 'ッ',
  'ｬ': 'ャ',
  'ｭ': 'ュ',
  'ｮ': 'ョ',
  'ｰ': 'ー',
};
final alphanumericMap = {
  'Ａ': 'A',
  'Ｂ': 'B',
  'Ｃ': 'C',
  'Ｄ': 'D',
  'Ｅ': 'E',
  'Ｆ': 'F',
  'Ｇ': 'G',
  'Ｈ': 'H',
  'Ｉ': 'I',
  'Ｊ': 'J',
  'Ｋ': 'K',
  'Ｌ': 'L',
  'Ｍ': 'M',
  'Ｎ': 'N',
  'Ｏ': 'O',
  'Ｐ': 'P',
  'Ｑ': 'Q',
  'Ｒ': 'R',
  'Ｓ': 'S',
  'Ｔ': 'T',
  'Ｕ': 'U',
  'Ｖ': 'V',
  'Ｗ': 'W',
  'Ｘ': 'X',
  'Ｙ': 'Y',
  'Ｚ': 'Z',
  'ａ': 'a',
  'ｂ': 'b',
  'ｃ': 'c',
  'ｄ': 'd',
  'ｅ': 'e',
  'ｆ': 'f',
  'ｇ': 'g',
  'ｈ': 'h',
  'ｉ': 'i',
  'ｊ': 'j',
  'ｋ': 'k',
  'ｌ': 'l',
  'ｍ': 'm',
  'ｎ': 'n',
  'ｏ': 'o',
  'ｐ': 'p',
  'ｑ': 'q',
  'ｒ': 'r',
  'ｓ': 's',
  'ｔ': 't',
  'ｕ': 'u',
  'ｖ': 'v',
  'ｗ': 'w',
  'ｘ': 'x',
  'ｙ': 'y',
  'ｚ': 'z',
  '０': '0',
  '１': '1',
  '２': '2',
  '３': '3',
  '４': '4',
  '５': '5',
  '６': '6',
  '７': '7',
  '８': '8',
  '９': '9',
};
