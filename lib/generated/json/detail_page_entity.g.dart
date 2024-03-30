import 'package:MoeLoaderFlutter/generated/json/base/json_convert_content.dart';
import 'package:MoeLoaderFlutter/model/detail_page_entity.dart';
import 'package:MoeLoaderFlutter/model/tag_entity.dart';


DetailPageEntity $DetailPageEntityFromJson(Map<String, dynamic> json) {
  final DetailPageEntity detailPageEntity = DetailPageEntity();
  final String? url = jsonConvert.convert<String>(json['url']);
  if (url != null) {
    detailPageEntity.url = url;
  }
  final String? bigUrl = jsonConvert.convert<String>(json['bigUrl']);
  if (bigUrl != null) {
    detailPageEntity.bigUrl = bigUrl;
  }
  final String? rawUrl = jsonConvert.convert<String>(json['rawUrl']);
  if (rawUrl != null) {
    detailPageEntity.rawUrl = rawUrl;
  }
  final String? tagStr = jsonConvert.convert<String>(json['tagStr']);
  if (tagStr != null) {
    detailPageEntity.tagStr = tagStr;
  }
  final String? tagSplit = jsonConvert.convert<String>(json['tagSplit']);
  if (tagSplit != null) {
    detailPageEntity.tagSplit = tagSplit;
  }
  final String? width = jsonConvert.convert<String>(json['width']);
  if (width != null) {
    detailPageEntity.width = width;
  }
  final String? height = jsonConvert.convert<String>(json['height']);
  if (height != null) {
    detailPageEntity.height = height;
  }
  final String? id = jsonConvert.convert<String>(json['id']);
  if (id != null) {
    detailPageEntity.id = id;
  }
  final String? author = jsonConvert.convert<String>(json['author']);
  if (author != null) {
    detailPageEntity.author = author;
  }
  final String? dimensions = jsonConvert.convert<String>(json['dimensions']);
  if (dimensions != null) {
    detailPageEntity.dimensions = dimensions;
  }
  final String? source = jsonConvert.convert<String>(json['source']);
  if (source != null) {
    detailPageEntity.source = source;
  }
  final List<TagEntity>? tagList = (json['tagList'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<TagEntity>(e) as TagEntity).toList();
  if (tagList != null) {
    detailPageEntity.tagList = tagList;
  }
  return detailPageEntity;
}

Map<String, dynamic> $DetailPageEntityToJson(DetailPageEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['url'] = entity.url;
  data['bigUrl'] = entity.bigUrl;
  data['rawUrl'] = entity.rawUrl;
  data['tagStr'] = entity.tagStr;
  data['tagSplit'] = entity.tagSplit;
  data['width'] = entity.width;
  data['height'] = entity.height;
  data['id'] = entity.id;
  data['author'] = entity.author;
  data['dimensions'] = entity.dimensions;
  data['source'] = entity.source;
  data['tagList'] = entity.tagList.map((v) => v.toJson()).toList();
  return data;
}

extension DetailPageEntityExtension on DetailPageEntity {
  DetailPageEntity copyWith({
    String? url,
    String? bigUrl,
    String? rawUrl,
    String? tagStr,
    String? tagSplit,
    String? width,
    String? height,
    String? id,
    String? author,
    String? dimensions,
    String? source,
    List<TagEntity>? tagList,
  }) {
    return DetailPageEntity()
      ..url = url ?? this.url
      ..bigUrl = bigUrl ?? this.bigUrl
      ..rawUrl = rawUrl ?? this.rawUrl
      ..tagStr = tagStr ?? this.tagStr
      ..tagSplit = tagSplit ?? this.tagSplit
      ..width = width ?? this.width
      ..height = height ?? this.height
      ..id = id ?? this.id
      ..author = author ?? this.author
      ..dimensions = dimensions ?? this.dimensions
      ..source = source ?? this.source
      ..tagList = tagList ?? this.tagList;
  }
}