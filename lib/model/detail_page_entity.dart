import 'package:moeloaderflutter/generated/json/base/json_field.dart';
import 'package:moeloaderflutter/generated/json/detail_page_entity.g.dart';
import 'dart:convert';

import 'package:moeloaderflutter/model/tag_entity.dart';
export 'package:moeloaderflutter/generated/json/detail_page_entity.g.dart';

@JsonSerializable()
class DetailPageEntity {
	late String url = '';
	late String bigUrl = '';
	late String rawUrl = '';
	late String tagStr = '';
	late String tagSplit = '';
	late String width = '';
	late String height = '';
	late String id = '';
	late String authorId = '';
	late String author = '';
	late String dimensions = '';
	late String source = '';
	late List<TagEntity> tagList = [];

	DetailPageEntity();

	factory DetailPageEntity.fromJson(Map<String, dynamic> json) => $DetailPageEntityFromJson(json);

	Map<String, dynamic> toJson() => $DetailPageEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}