import 'package:moeloaderflutter/ui/viewmodel/view_model_pool_list.dart';
import 'package:moeloaderflutter/util/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:to_json/validator.dart';

typedef ExceptionActionCallback = void Function(PoolListState poolListState);
typedef LoadingStatusBuilder = Widget Function(PoolListState poolListState);

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
      PoolListState poolListState = snapshot.data;
      if (poolListState.error) {
        List<Widget> children = [];
        children.add(ElevatedButton(
            onPressed: () {
              var retryOnPressed = widget.retryOnPressed;
              if (retryOnPressed != null) {
                retryOnPressed();
              }
            },
            child: const Text("点击重试")));
        if (poolListState.code == ValidateResult.needChallenge ||
            poolListState.code == ValidateResult.needLogin) {
          children.add(const SizedBox(
            height: 10,
          ));
          children.add(ElevatedButton(
              onPressed: () {
                var actionOnPressed = widget.actionOnPressed;
                if (actionOnPressed != null) {
                  actionOnPressed(poolListState);
                }
              },
              child: Text(tipsByCode(poolListState.code))));
        }
        children.add(const SizedBox(height: 20));
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(25, 0, 0, 0),
          child: Text(
            poolListState.errorMessage,
          ),
        ));
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        );
      }
      if (poolListState.loading && poolListState.list.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(10),
        child: widget.builder(poolListState),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }
}
