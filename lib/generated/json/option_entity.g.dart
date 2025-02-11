import 'package:moeloaderflutter/generated/json/base/json_convert_content.dart';
import 'package:moeloaderflutter/model/option_entity.dart';

OptionEntity $OptionEntityFromJson(Map<String, dynamic> json) {
  final OptionEntity optionEntity = OptionEntity();
  final String? id = jsonConvert.convert<String>(json['id']);
  if (id != null) {
    optionEntity.id = id;
  }
  final String? desc = jsonConvert.convert<String>(json['desc']);
  if (desc != null) {
    optionEntity.desc = desc;
  }
  final List<OptionItems>? items = (json['items'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<OptionItems>(e) as OptionItems).toList();
  if (items != null) {
    optionEntity.items = items;
  }
  return optionEntity;
}

Map<String, dynamic> $OptionEntityToJson(OptionEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['desc'] = entity.desc;
  data['items'] = entity.items.map((v) => v.toJson()).toList();
  return data;
}

extension OptionEntityExtension on OptionEntity {
  OptionEntity copyWith({
    String? id,
    String? desc,
    List<OptionItems>? items,
  }) {
    return OptionEntity()
      ..id = id ?? this.id
      ..desc = desc ?? this.desc
      ..items = items ?? this.items;
  }
}

OptionItems $OptionItemsFromJson(Map<String, dynamic> json) {
  final OptionItems optionItems = OptionItems();
  final String? desc = jsonConvert.convert<String>(json['desc']);
  if (desc != null) {
    optionItems.desc = desc;
  }
  final String? param = jsonConvert.convert<String>(json['param']);
  if (param != null) {
    optionItems.param = param;
  }
  return optionItems;
}

Map<String, dynamic> $OptionItemsToJson(OptionItems entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['desc'] = entity.desc;
  data['param'] = entity.param;
  return data;
}

extension OptionItemsExtension on OptionItems {
  OptionItems copyWith({
    String? desc,
    String? param,
  }) {
    return OptionItems()
      ..desc = desc ?? this.desc
      ..param = param ?? this.param;
  }
}