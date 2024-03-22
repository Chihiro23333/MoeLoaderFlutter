class Rule{
  String type;
  String path;
  String name;

  Rule(this.type, this.path, this.name);
}

class WebPageItem{
  Rule rule;

  WebPageItem(this.rule);
}