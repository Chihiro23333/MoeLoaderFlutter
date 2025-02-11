import 'package:moeloaderflutter/generated/json/base/json_convert_content.dart';
import 'package:moeloaderflutter/model/tag_entity.dart';

TagEntity $TagEntityFromJson(Map<String, dynamic> json) {
  final TagEntity tagEntity = TagEntity();
  final String? desc = jsonConvert.convert<String>(json['desc']);
  if (desc != null) {
    tagEntity.desc = desc;
  }
  final String? tag = jsonConvert.convert<String>(json['tag']);
  if (tag != null) {
    tagEntity.tag = tag;
  }
  return tagEntity;
}

Map<String, dynamic> $TagEntityToJson(TagEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['desc'] = entity.desc;
  data['tag'] = entity.tag;
  return data;
}

extension TagEntityExtension on TagEntity {
  TagEntity copyWith({
    String? desc,
    String? tag,
  }) {
    return TagEntity()
      ..desc = desc ?? this.desc
      ..tag = tag ?? this.tag;
  }
}