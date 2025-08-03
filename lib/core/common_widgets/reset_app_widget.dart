// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/widgets.dart';

/// Wrap your root App widget in this widget and call [ResetAppWidget.reset] to restart your app.
class ResetAppWidget extends StatefulWidget {
  final Widget child;

  const ResetAppWidget({Key? key, required this.child}) : super(key: key);

  @override
  _ResetAppWidgetState createState() => _ResetAppWidgetState();

  static reset(BuildContext context) {
    context.findAncestorStateOfType<_ResetAppWidgetState>()!.restartApp();
  }
}

class _ResetAppWidgetState extends State<ResetAppWidget> {
  Key _key = UniqueKey();

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}
