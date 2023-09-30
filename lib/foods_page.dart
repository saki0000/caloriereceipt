import 'package:caloriereceipt/result_pge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// その日に食べたものを表示するページ
class FoodsPage extends StatefulWidget {
  final DateTime selectedDate;
  final String timeZone;
  const FoodsPage(
      {super.key, required this.selectedDate, required this.timeZone});

  @override
  State<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends State<FoodsPage> {
  Future<List<Product>>? _data;
  Future<List<Product>> _fetchFoods() async {
    final date = DateFormat("y-MM-dd").format(widget.selectedDate);
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection("calories")
        .where("date", isEqualTo: date)
        .where("timeZone", isEqualTo: widget.timeZone)
        .get();
    List<Product> foods = await Future.wait(snapshot.docs.map((doc) async {
      return Product.fromMap(doc.data(), doc.id, null);
    }).toList());
    return foods;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _data = _fetchFoods();
  }

  Widget build(BuildContext context) {
    final date = DateFormat("y/MM/dd").format(widget.selectedDate);
    return Scaffold(
      appBar: AppBar(
        title: Text(date),
        backgroundColor: Colors.blueGrey[50],
      ),
      backgroundColor: Colors.blueGrey[50],
      body: FutureBuilder(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final foods = snapshot.data!;
          return Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: SingleChildScrollView(
                  child: Column(
                children: [
                  ListView.builder(
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                  foods[index].imageURL!)),
                                        )
                                      : const Icon(Icons.fastfood_outlined),
                                  Flexible(
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(foods[index].name,
                                              // maxLines: 1,
                                              softWrap: true,
                                              // overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500)),
                                          Text(
                                            'Calorie: ${foods[index].calorie}',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black45),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection("calories")
                                          .doc(foods[index].id)
                                          .update({
                                        "amount": FieldValue.increment(-1)
                                      });
                                      if (foods[index].amount == 1) {
                                        showDialog<void>(
                                            context: context,
                                            builder: (_) {
                                              return AlertDialog(
                                                title: Text('削除しますか？'),
                                                content:
                                                    Text(foods[index].name),
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
                                                      FirebaseFirestore.instance
                                                          .collection(
                                                              "calories")
                                                          .doc(foods[index].id)
                                                          .delete();
                                                      setState(() {
                                                        snapshot.data!
                                                            .removeAt(index);
                                                      });
                                                      Navigator.pop(context);
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        foods[index].amount -= 1;
                                        setState(() {});
                                      }
                                    },
                                    icon: const Icon(Icons.remove, size: 20)),
                                Text(
                                  "${foods[index].amount}",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection("calories")
                                          .doc(foods[index].id)
                                          .update({
                                        "amount": FieldValue.increment(1)
                                      });
                                      foods[index].amount += 1;
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.add,
                                      size: 20,
                                    ))
                              ],
                            )
                            // IconButton(
                            //     onPressed: () {
                            //       FirebaseFirestore.instance
                            //           .collection("calories")
                            //           .doc(foods[index].id)
                            //           .delete();
                            //       setState(() {
                            //         snapshot.data!.removeAt(index);
                            //       });
                            //     },
                            //     icon: const Icon(Icons.delete))
                          ],
                        ),
                      );
                    },
                    shrinkWrap: true,
                  )
                ],
              )));
        },
      ),
    );
  }
}
