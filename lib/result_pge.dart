import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 解析したレシートから一致したデータを表示するページ
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
  late Future<List<SearchProducts>> _data;
  List<int>? _selectModalIndexes;
  List<int>? _selectIndexes;

  void setAddData(List<SearchProducts> products, SearchProducts newData) {
    products.add(newData);
  }

  void setParentState(int index) {
    setState(() {
      List<int> ary = _selectIndexes ?? [];
      ary.add(index);
      _selectIndexes = ary;
    });
  }

  Future<List<SearchProducts>> _fetchProduct() async {
    List<SearchProducts> searchProducts = [];
    final firestore = FirebaseFirestore.instance;

    for (String w in widget.receipt) {
      Query<Map<String, dynamic>> query = firestore.collection('products');
      List<String> splitedWord =
          w.replaceAll("-", "ー").split("").toSet().toList();
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
        return Product.fromMap(doc.data(), doc.id, 1);
      }).toList());
      if (products.isNotEmpty) {
        searchProducts.add(SearchProducts(searchWord: w, data: products));
      }
      int length = searchProducts.length;
      _selectIndexes = List.filled(length, 0, growable: true);
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
      List<SearchProducts>? products, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                product.imageURL != null
                    ? SizedBox(
                        width: 50,
                        height: 50,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(product.imageURL!)),
                      )
                    : const Icon(Icons.fastfood_outlined),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            // maxLines: 1,
                            softWrap: true,
                            // overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        SizedBox(
                          height: 2,
                        ),
                        Column(
                          children: [
                            Text(
                              '${product.calorie}kcal',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black45),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          isModal
              ? Container()
              : Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          if (products?[index]
                                  .data[_selectIndexes![index]]
                                  .amount ==
                              1) {
                            showDialog<void>(
                                context: context,
                                builder: (_) {
                                  return AlertDialog(
                                    title: Text('削除しますか？'),
                                    content: Text(products![index]
                                        .data[_selectIndexes![index]]
                                        .name),
                                    actions: <Widget>[
                                      MaterialButton(
                                        child: Text('いいえ'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      MaterialButton(
                                        child: Text('はい'),
                                        onPressed: () {
                                          products.removeAt(index);
                                          setState(() {
                                            var ary = _selectIndexes!;
                                            ary.removeAt(index);
                                            _selectIndexes = ary;
                                          });
                                          Navigator.pop(context);
                                        },
                                      )
                                    ],
                                  );
                                });
                          } else {
                            products?[index]
                                .data[_selectIndexes![index]]
                                .amount -= 1;
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.remove, size: 20)),
                    Text(
                      "${product.amount}",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                        onPressed: () {
                          products?[index]
                              .data[_selectIndexes![index]]
                              .amount += 1;
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.add,
                          size: 20,
                        ))
                  ],
                )
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
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
          var products = snapshot.data!;
          _selectIndexes ??= List.filled(products.length, 0);
          _selectModalIndexes ??= List.filled(products.length, 0);
          return Scaffold(
              appBar: AppBar(
                title: const Text('検索結果'),
                backgroundColor: Colors.blueGrey[50],
              ),
              backgroundColor: Colors.blueGrey[50],
              body: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Expanded(
                        //   child:
                        ListView.builder(
                            // Listのデータの数を数える
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              // index番目から数えて、０〜３まで登録されているデータを表示する変数
                              var product =
                                  products[index].data[_selectIndexes![index]];
                              final searchWord = products[index].searchWord;
                              // downloadImage(product.imageURL);
                              return Stack(
                                alignment: AlignmentDirectional.topEnd,
                                children: [
                                  Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Stack(
                                        children: [
                                          Column(
                                            children: [
                                              // if (products[index].products.length != 1)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4),
                                                child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        searchWord,
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                      IconButton(
                                                          onPressed: () {
                                                            showModalBottomSheet(
                                                                backgroundColor:
                                                                    Colors
                                                                        .white,
                                                                context:
                                                                    context,
                                                                builder: (context) => StatefulBuilder(
                                                                    builder: ((context, StateSetter setModalState) => Container(
                                                                        margin: const EdgeInsets.symmetric(vertical: 16),
                                                                        height: 500,
                                                                        child: ListView.builder(
                                                                            itemCount: products[index].data.length,
                                                                            itemBuilder: (context, i) {
                                                                              return GestureDetector(
                                                                                onTap: () {
                                                                                  setState(() {
                                                                                    _selectModalIndexes![index] = i;
                                                                                  });
                                                                                  setModalState(
                                                                                    () {
                                                                                      _selectIndexes![index] = i;
                                                                                    },
                                                                                  );
                                                                                },
                                                                                child: Container(
                                                                                  margin: EdgeInsets.all(8),
                                                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                                                                                  alignment: Alignment.center,
                                                                                  decoration: BoxDecoration(border: i == _selectIndexes![index] ? Border.all(color: Colors.blue) : null, borderRadius: BorderRadius.circular(16), color: Colors.white),
                                                                                  child: ListContainer(products[index].data[i], true, null, 1),
                                                                                ),
                                                                              );
                                                                            })))));
                                                          },
                                                          icon: const Icon(Icons
                                                              .chevron_right)),
                                                    ]),
                                              ),
                                              // if (products[index].products.length != 1)
                                              Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 4),
                                                  child: const Divider()),
                                              ListContainer(product, false,
                                                  products, index)
                                            ],
                                          )
                                        ],
                                      )
                                      // Personクラスのメンバ変数を使用する

                                      ),
                                  if (products[index].data.length != 1)
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
                                          '${products[index].data.length}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        )
                                      ],
                                    ),
                                ],
                              );
                            }),
                        // ),
                        const SizedBox(
                          height: 120,
                        )
                      ],
                    ),
                  ),
                  Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.all(8),
                      child: MaterialButton(
                          minWidth: MediaQuery.of(context).size.width,
                          color: Colors.blueGrey[300],
                          onPressed: () async {
                            final db = FirebaseFirestore.instance;
                            final String date = DateFormat("y-MM-dd")
                                .format(widget.selectedDate);
                            final query = db.collection("calories");

                            for (var i = 0; i < products.length; i++) {
                              final product = {
                                "name":
                                    products[i].data[_selectIndexes![i]].name,
                                "calorie": products[i]
                                    .data[_selectIndexes![i]]
                                    .calorie,
                                "imageURL": products[i]
                                    .data[_selectIndexes![i]]
                                    .imageURL,
                                "timeZone": widget.timeZone,
                                "date": date,
                                "amount":
                                    products[i].data[_selectIndexes![i]].amount,
                              };
                              await query.add(product);
                            }
                            route();
                          },
                          child: const Text("登録",
                              style: TextStyle(color: Colors.white))))
                ],
              ),
              // }),
              floatingActionButton: Container(
                margin: const EdgeInsets.only(bottom: 40),
                child: FloatingActionButton(
                  onPressed: () {
                    showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (context) {
                          return SearchProductsWidget(
                            data: products,
                            setAddData: setAddData,
                            setParentState: setParentState,
                          );
                        });
                  },
                  backgroundColor: Colors.blueGrey[700],
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                ),
              ));
        });
  }
}

class SearchProductsWidget extends StatefulWidget {
  final List<SearchProducts> data;
  final void Function(List<SearchProducts>, SearchProducts) setAddData;
  final void Function(int) setParentState;
  const SearchProductsWidget(
      {super.key,
      required this.data,
      required this.setAddData,
      required this.setParentState});

  @override
  State<SearchProductsWidget> createState() => _SearchProductsWidgetState();
}

class _SearchProductsWidgetState extends State<SearchProductsWidget> {
  String? _searchWord;
  Future<List<Product>> _fetchProduct() async {
    List<Product> searchProducts = [];
    final firestore = FirebaseFirestore.instance;
    Query<Map<String, dynamic>> query = firestore.collection('products');
    List<String> splitedWord = [];
    if (_searchWord != null && _searchWord != "") {
      splitedWord =
          _searchWord!.replaceAll("-", "ー").split("").toSet().toList();
      splitedWord
          .removeWhere((e) => ['~', '*', '/', '[', ']', ' ', "ﾞ"].contains(e));

      for (var i = 0; i < splitedWord.length; i++) {
        splitedWord[i] = convertText(input: splitedWord[i]);
      }

      for (String s in splitedWord) {
        query = query.where('wordsMap.$s', isEqualTo: true);
      }
      final snapshot = await query.get();

      searchProducts = await Future.wait(snapshot.docs.map((doc) async {
        return Product.fromMap(doc.data(), doc.id, 1);
      }).toList());
    }

    return searchProducts;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _fetchProduct(),
        builder: (context, snapshot) {
          final foods = snapshot.data!;

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  margin: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter a search term',
                          ),
                          autofocus: true,
                          onChanged: (text) {
                            setState(() {
                              _searchWord = text;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: foods.length,
                          itemBuilder: (context, index) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              margin: EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      children: [
                                        foods[index].imageURL != null
                                            ? SizedBox(
                                                width: 50,
                                                height: 50,
                                                child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            100),
                                                    child: Image.network(
                                                        foods[index]
                                                            .imageURL!)),
                                              )
                                            : const Icon(
                                                Icons.fastfood_outlined),
                                        Flexible(
                                          child: Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(foods[index].name,
                                                    // maxLines: 1,
                                                    softWrap: true,
                                                    // overflow:
                                                    //     TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500)),
                                                Text(
                                                  'Calorie: ${foods[index].calorie}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black45),
                                                )
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        widget.setAddData(
                                            widget.data,
                                            SearchProducts(
                                                data: [foods[index]],
                                                searchWord: _searchWord!));
                                        widget.setParentState(0);
                                        Navigator.of(context).pop();
                                      },
                                      icon: const Icon(Icons.add))
                                ],
                              ),
                            );
                          },
                          shrinkWrap: true,
                        ),
                      )
                    ],
                  ),
                )),
          );
        });
  }
}

class SearchProducts {
  final String searchWord;
  final List<Product> data;

  SearchProducts({required this.searchWord, required this.data});
}

class Product {
  final String name;
  final int calorie;
  final String? imageURL;
  // final Uint8List? imageData;
  final String? id;
  int amount;

  Product({
    required this.name,
    required this.calorie,
    this.imageURL,
    // this.imageData,
    this.id,
    required this.amount,
  });

  factory Product.fromMap(Map<String, dynamic> data, String? id, int? amount) {
    return Product(
        name: data['name'],
        calorie: data['calorie'],
        imageURL: data['imageURL'],
        id: id,
        amount: data['amount'] ?? amount);
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
  '-': 'ー',
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
