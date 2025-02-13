import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../init.dart';

typedef RadioSelectCallback = void Function(int index, String desc);

class RadioChoiceChip extends StatefulWidget {
  RadioChoiceChip(
      {super.key,
      required this.list,
      this.index,
      required this.radioSelectCallback});

  final List<String> list;
  int? index;
  final RadioSelectCallback radioSelectCallback;

  @override
  State<StatefulWidget> createState() {
    return _RadioChoiceChipState();
  }
}

class _RadioChoiceChipState extends State<RadioChoiceChip> {
  final _log = Logger('Parser');

  @override
  Widget build(BuildContext context) {
    List<String> list = widget.list;
    int index = widget.index ?? 0;
    RadioSelectCallback radioSelectCallback = widget.radioSelectCallback;

    List<Widget> choiceChips = [];
    for (int i = 0; i < list.length; i++) {
      String desc = list[i];
      bool selected = i == index;
      choiceChips.add(ChoiceChip.elevated(
        backgroundColor: Colors.white,
        label: Text(desc),
        selected: selected,
        onSelected: (bool selected) {
          _log.fine("index=$i;selected=$selected");
          widget.index = i;
          setState(() {});
          radioSelectCallback(i, desc);
        },
        selectedColor: Global.defaultColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black,
        ),
        elevation: 10,
        showCheckmark: false,
      ));
    }
    return Wrap(
      spacing: 8.0, // 主轴(水平)方向间距
      runSpacing: 4.0, // 纵轴（垂直）方向间距
      children: choiceChips,
    );
  }
}
