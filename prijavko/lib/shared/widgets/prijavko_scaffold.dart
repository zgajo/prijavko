import 'package:flutter/material.dart';

/// Shared page chrome: optional [AppBar], responsive horizontal inset on wide
/// layouts, and [SafeArea] around [body] (Story 1.5 responsive baseline).
class PrijavkoScaffold extends StatelessWidget {
  const PrijavkoScaffold({super.key, this.appBar, required this.body});

  final PreferredSizeWidget? appBar;
  final Widget body;

  static const double _wideLayoutBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget inner = constraints.maxWidth > _wideLayoutBreakpoint
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: body,
                    ),
                  ),
                )
              : body;
          return SafeArea(child: inner);
        },
      ),
    );
  }
}
