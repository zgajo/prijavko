import 'package:flutter/material.dart';

import 'package:prijavko/core/l10n/context_l10n.dart';
import 'package:prijavko/shared/widgets/prijavko_scaffold.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrijavkoScaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.tabHistory,
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ),
      body: Center(child: Text(context.l10n.tabHistory)),
    );
  }
}
