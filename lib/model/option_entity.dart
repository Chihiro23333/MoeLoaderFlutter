import 'package:MoeLoaderFlutter/generated/json/base/json_field.dart';
import 'package:MoeLoaderFlutter/generated/json/option_entity.g.dart';
import 'dart:convert';
export 'package:MoeLoaderFlutter/generated/json/option_entity.g.dart';

@JsonSerializable()
class OptionEntity {
	late String id = '';
	late String desc = '';
	late List<OptionItems> items = [];

	OptionEntity();

	factory OptionEntity.fromJson(Map<String, dynamic> json) => $OptionEntityFromJson(json);

	Map<String, dynamic> toJson() => $OptionEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class OptionItems {
	late String desc = '';
	late String param = '';

	OptionItems();

	factory OptionItems.fromJson(Map<String, dynamic> json) => $OptionItemsFromJson(json);

	Map<String, dynamic> toJson() => $OptionItemsToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}