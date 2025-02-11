import 'package:moeloaderflutter/generated/json/base/json_field.dart';
import 'package:moeloaderflutter/generated/json/home_page_item_entity.g.dart';
import 'package:moeloaderflutter/model/tag_entity.dart';
import 'dart:convert';

import 'package:moeloaderflutter/net/download.dart';
export 'package:moeloaderflutter/generated/json/home_page_item_entity.g.dart';

@JsonSerializable()
class HomePageItemEntity {
	late String type = '';
	late String coverUrl = '';
	late String href = '';
	late String tagStr = '';
	late String tagSplit = '';
	late int width = 0;
	late int height = 0;
	late String id = '';
	late String authorId = '';
	late String author = '';
	late String characters = '';
	late String fileSize = '';
	late String dimensions = '';
	late String source = '';
	late String bigUrl = '';
	late String rawUrl = '';
	late String desc = '';
	late List<TagEntity> tagList = [];

	late int downloadState = DownloadTask.idle;

	HomePageItemEntity();

	factory HomePageItemEntity.fromJson(Map<String, dynamic> json) => $HomePageItemEntityFromJson(json);

	Map<String, dynamic> toJson() => $HomePageItemEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}