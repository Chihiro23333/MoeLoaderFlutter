import 'package:MoeLoaderFlutter/model/home_page_item_entity.dart';
import 'package:MoeLoaderFlutter/net/download.dart';

class YamlHomePageItem{
  String url = "";
  String href = "";
  double width = 0;
  double height = 0;
  CommonInfo? commonInfo;
  int downloadState = DownloadTask.idle;

  YamlHomePageItem(this.url, this.href, this.width, this.height, {this.commonInfo});
}

class YamlDetailPage{
  String url = "";
  String preview = "";
  HomePageItemEntity? homePageItem;

  YamlDetailPage(this.url, this.preview, {this.homePageItem});
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
  String desc = "";
  List<YamlTag> tags = [];

  CommonInfo(this.id, this.author, this.characters, this.fileSize,
      this.dimensions, this.source, this.bigUrl, this.rawUrl, this.desc,this.tags);
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