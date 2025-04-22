import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> showPageInputDialog(BuildContext context, int defaultValue,
    dynamic callBack) {
  return _showNumberInputDialog(
      context, defaultValue, "请输入要加载的页码", callBack);
}

Future<void> _showNumberInputDialog(BuildContext context, int defaultValue,
    String title, dynamic callBack) async {
  final TextEditingController controller = TextEditingController(
      text: "$defaultValue");

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title
          , style: const TextStyle(
              fontSize: 18
          ),),
        content: Form(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '请输入一个数字',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入数字';
              }
              if (double.tryParse(value) == null) {
                return '请输入有效的数字';
              }
              return null;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('确认'),
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
          ),
        ],
      );
    },
  ).then((value) {
    if (value != null) {
      callBack(value);
    }
  });
}
