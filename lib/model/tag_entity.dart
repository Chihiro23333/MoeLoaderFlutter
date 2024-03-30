import 'package:MoeLoaderFlutter/generated/json/base/json_field.dart';
import 'package:MoeLoaderFlutter/generated/json/tag_entity.g.dart';
import 'dart:convert';
export 'package:MoeLoaderFlutter/generated/json/tag_entity.g.dart';

@JsonSerializable()
class TagEntity {
	late String desc = '';
	late String tag = '';

	TagEntity();

	factory TagEntity.fromJson(Map<String, dynamic> json) => $TagEntityFromJson(json);

	Map<String, dynamic> toJson() => $TagEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}