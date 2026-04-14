import 'package:flutter/material.dart';

import 'package:prijavko/core/l10n/context_l10n.dart';
import 'package:prijavko/shared/widgets/prijavko_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrijavkoScaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.tabHome,
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ),
      body: Center(child: Text(context.l10n.tabHome)),
    );
  }
}
