import 'package:moeloaderflutter/generated/json/base/json_convert_content.dart';
import 'package:moeloaderflutter/model/home_page_item_entity.dart';
import 'package:moeloaderflutter/model/tag_entity.dart';

import 'package:moeloaderflutter/net/download.dart';


HomePageItemEntity $HomePageItemEntityFromJson(Map<String, dynamic> json) {
  final HomePageItemEntity homePageItemEntity = HomePageItemEntity();
  final String? type = jsonConvert.convert<String>(json['type']);
  if (type != null) {
    homePageItemEntity.type = type;
  }
  final String? coverUrl = jsonConvert.convert<String>(json['coverUrl']);
  if (coverUrl != null) {
    homePageItemEntity.coverUrl = coverUrl;
  }
  final String? href = jsonConvert.convert<String>(json['href']);
  if (href != null) {
    homePageItemEntity.href = href;
  }
  final String? tagStr = jsonConvert.convert<String>(json['tagStr']);
  if (tagStr != null) {
    homePageItemEntity.tagStr = tagStr;
  }
  final String? tagSplit = jsonConvert.convert<String>(json['tagSplit']);
  if (tagSplit != null) {
    homePageItemEntity.tagSplit = tagSplit;
  }
  final int? width = jsonConvert.convert<int>(json['width']);
  if (width != null) {
    homePageItemEntity.width = width;
  }
  final int? height = jsonConvert.convert<int>(json['height']);
  if (height != null) {
    homePageItemEntity.height = height;
  }
  final String? id = jsonConvert.convert<String>(json['id']);
  if (id != null) {
    homePageItemEntity.id = id;
  }
  final String? authorId = jsonConvert.convert<String>(json['authorId']);
  if (authorId != null) {
    homePageItemEntity.authorId = authorId;
  }
  final String? author = jsonConvert.convert<String>(json['author']);
  if (author != null) {
    homePageItemEntity.author = author;
  }
  final String? characters = jsonConvert.convert<String>(json['characters']);
  if (characters != null) {
    homePageItemEntity.characters = characters;
  }
  final String? fileSize = jsonConvert.convert<String>(json['fileSize']);
  if (fileSize != null) {
    homePageItemEntity.fileSize = fileSize;
  }
  final String? dimensions = jsonConvert.convert<String>(json['dimensions']);
  if (dimensions != null) {
    homePageItemEntity.dimensions = dimensions;
  }
  final String? source = jsonConvert.convert<String>(json['source']);
  if (source != null) {
    homePageItemEntity.source = source;
  }
  final String? bigUrl = jsonConvert.convert<String>(json['bigUrl']);
  if (bigUrl != null) {
    homePageItemEntity.bigUrl = bigUrl;
  }
  final String? rawUrl = jsonConvert.convert<String>(json['rawUrl']);
  if (rawUrl != null) {
    homePageItemEntity.rawUrl = rawUrl;
  }
  final String? desc = jsonConvert.convert<String>(json['desc']);
  if (desc != null) {
    homePageItemEntity.desc = desc;
  }
  final List<TagEntity>? tagList = (json['tagList'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<TagEntity>(e) as TagEntity).toList();
  if (tagList != null) {
    homePageItemEntity.tagList = tagList;
  }
  final int? downloadState = jsonConvert.convert<int>(json['downloadState']);
  if (downloadState != null) {
    homePageItemEntity.downloadState = downloadState;
  }
  return homePageItemEntity;
}

Map<String, dynamic> $HomePageItemEntityToJson(HomePageItemEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['type'] = entity.type;
  data['coverUrl'] = entity.coverUrl;
  data['href'] = entity.href;
  data['tagStr'] = entity.tagStr;
  data['tagSplit'] = entity.tagSplit;
  data['width'] = entity.width;
  data['height'] = entity.height;
  data['id'] = entity.id;
  data['authorId'] = entity.authorId;
  data['author'] = entity.author;
  data['characters'] = entity.characters;
  data['fileSize'] = entity.fileSize;
  data['dimensions'] = entity.dimensions;
  data['source'] = entity.source;
  data['bigUrl'] = entity.bigUrl;
  data['rawUrl'] = entity.rawUrl;
  data['desc'] = entity.desc;
  data['tagList'] = entity.tagList.map((v) => v.toJson()).toList();
  data['downloadState'] = entity.downloadState;
  return data;
}

extension HomePageItemEntityExtension on HomePageItemEntity {
  HomePageItemEntity copyWith({
    String? type,
    String? coverUrl,
    String? href,
    String? tagStr,
    String? tagSplit,
    int? width,
    int? height,
    String? id,
    String? authorId,
    String? author,
    String? characters,
    String? fileSize,
    String? dimensions,
    String? source,
    String? bigUrl,
    String? rawUrl,
    String? desc,
    List<TagEntity>? tagList,
    int? downloadState,
  }) {
    return HomePageItemEntity()
      ..type = type ?? this.type
      ..coverUrl = coverUrl ?? this.coverUrl
      ..href = href ?? this.href
      ..tagStr = tagStr ?? this.tagStr
      ..tagSplit = tagSplit ?? this.tagSplit
      ..width = width ?? this.width
      ..height = height ?? this.height
      ..id = id ?? this.id
      ..authorId = authorId ?? this.authorId
      ..author = author ?? this.author
      ..characters = characters ?? this.characters
      ..fileSize = fileSize ?? this.fileSize
      ..dimensions = dimensions ?? this.dimensions
      ..source = source ?? this.source
      ..bigUrl = bigUrl ?? this.bigUrl
      ..rawUrl = rawUrl ?? this.rawUrl
      ..desc = desc ?? this.desc
      ..tagList = tagList ?? this.tagList
      ..downloadState = downloadState ?? this.downloadState;
  }
}