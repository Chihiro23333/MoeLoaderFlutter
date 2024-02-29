void main() {
  String input = '''这是一个示例字符串，包含{page}和其它文本。''';
  String pattern = r'\{([^}]*)\}';

  // 使用正则表达式匹配被{}包围的内容
  RegExp regExp = RegExp(pattern);
  Iterable iterator = regExp.allMatches(input);

  // 遍历匹配结果并打印
  for (Match match in iterator) {
    print('找到匹配内容: ${match.group(1)}');
  }
}