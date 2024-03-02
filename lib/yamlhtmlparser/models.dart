class YamlHomePageItem{
  String url = "";
  String href = "";
  double width = 0;
  double height = 0;
  CommonInfo? commonInfo;

  YamlHomePageItem(this.url, this.href, this.width, this.height, {this.commonInfo});
}

class YamlDetailPage{
  String url = "";
  String preview = "";
  CommonInfo? commonInfo;

  YamlDetailPage(this.url, this.preview, {this.commonInfo});
}

class CommonInfo{
  String id = "";
  String author = "";
  String characters = "";
  String fileSize = "";
  String dimensions = "";
  String source = "";
  String bigUrl = "";
  String rawUrl = "";
  List<YamlTag> tags = [];

  CommonInfo(this.id, this.author, this.characters, this.fileSize,
      this.dimensions, this.source, this.bigUrl, this.rawUrl, this.tags);
}

class YamlTag{
  String desc = "";
  String tag = "";

  YamlTag(this.desc, this.tag);
}

class YamlOptionList{
  String id = "";
  String desc = "";
  List<YamlOption> options = [];

  YamlOptionList(this.id, this.desc, this.options);
}

class YamlOption{
  String pId = "";
  String desc = "";
  String param = "";

  YamlOption(this.pId, this.desc, this.param);
}

class YamlPreview{
  String url = "";

  YamlPreview(this.url);
}

class WebPageItem{
  Rule rule;

  WebPageItem(this.rule);
}

class Rule{
  String type;
  String path;
  String name;

  Rule(this.type, this.path, this.name);
}

class NaviResult<T>{

  T? data;

  NaviResult(this.data);
}