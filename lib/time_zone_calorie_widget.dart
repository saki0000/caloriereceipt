import 'package:caloriereceipt/main.dart';
import 'package:flutter/material.dart';

class TimeZoneCalorieWidget extends StatelessWidget {
  final String timeZone;
  final int calorie;
  final IconData icon;
  final List<dynamic> products;
  final DateTime selectedDate;
  final void Function(void Function())? setState;
  const TimeZoneCalorieWidget(
      {Key? key,
      required this.timeZone,
      required this.calorie,
      required this.icon,
      required this.products,
      required this.selectedDate,
      this.setState})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String foodsName = "";
    for (var s in products) {
      foodsName += "${s.name}、";
    }
    Map<String, String> title = {
      "breakfast": "朝食",
      "lunch": "昼食",
      "dinner": "夕食",
      "snack": "間食"
    };
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey, width: 2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    direction: Axis.horizontal,
                    children: [
                      Icon(icon, size: 34),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title[timeZone]!,
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      )
                    ]),
                // IconButton(onPressed: () {}, icon: const Icon(Icons.add))
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    "${calorie}kcal",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                    child: Text(
                  foodsName == "" ? "Nothing" : foodsName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1),
                )),
                IconButton(
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/foods-page',
                            arguments: FoodsPageArg(selectedDate, timeZone))
                        .then(
                      (value) {
                        print("back");
                        setState!(() {});
                      },
                    );
                  },
                  icon: const Icon(Icons.chevron_right_rounded),
                  padding: const EdgeInsets.all(2),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
