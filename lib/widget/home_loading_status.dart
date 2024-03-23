import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import '../init.dart';
import '../net/download.dart';
import '../ui/common_function.dart';
import '../ui/download_tasks_dialog.dart';
import '../ui/info_dialog.dart';
import '../ui/url_list_dialog.dart';
import '../ui/view_model_home.dart';
import '../utils/const.dart';
import '../utils/sharedpreferences_utils.dart';
import '../utils/utils.dart';
import '../yamlhtmlparser/models.dart';
import '../yamlhtmlparser/yaml_validator.dart';

typedef ExceptionActionCallback = void Function(HomeState homeState);
typedef LoadingStatusBuilder = Widget Function(HomeState homeState);

class LoadingStatus extends StatefulWidget {
  const LoadingStatus({
    super.key,
    required this.snapshot,
    required this.builder,
    this.retryOnPressed,
    this.actionOnPressed,
  });

  final AsyncSnapshot snapshot;
  final VoidCallback? retryOnPressed;
  final ExceptionActionCallback? actionOnPressed;
  final LoadingStatusBuilder builder;

  @override
  State<StatefulWidget> createState() {
    return _LoadingStatusState();
  }
}

class _LoadingStatusState extends State<LoadingStatus> {
  final _log = Logger("_LoadingStatusState");

  @override
  Widget build(BuildContext context) {
    return _buildBody(context, widget.snapshot);
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.active) {
      HomeState homeState = snapshot.data;
      if (homeState.error && homeState.page <= 1) {
        List<Widget> children = [];
        children.add(ElevatedButton(
            onPressed: () {
              var retryOnPressed = widget.retryOnPressed;
              if (retryOnPressed != null) {
                retryOnPressed();
              }
            },
            child: const Text("点击重试")));
        if (homeState.code == ValidateResult.needChallenge ||
            homeState.code == ValidateResult.needLogin) {
          children.add(const SizedBox(
            height: 10,
          ));
          children.add(ElevatedButton(
              onPressed: () {
                var actionOnPressed = widget.actionOnPressed;
                if (actionOnPressed != null) {
                  actionOnPressed(homeState);
                }
              },
              child: Text(tipsByCode(homeState.code))));
        }
        children.add(const SizedBox(height: 20));
        children.add(Center(
          child: Text(
            homeState.errorMessage,
          ),
        ));
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        );
      }
      if (homeState.loading && homeState.list.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(10),
        child: widget.builder(homeState),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }
}
