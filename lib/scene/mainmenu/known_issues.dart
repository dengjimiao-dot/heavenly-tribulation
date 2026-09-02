import 'package:flutter/material.dart';

import '../../global.dart';
import '../../widgets/ui/close_button2.dart';
import '../../widgets/ui/responsive_view.dart';

class KnownIssuesDialog extends StatelessWidget {
  const KnownIssuesDialog({super.key});

  static const _issueKeys = [
    'knownIssuesArt',
    'knownIssuesMissingArt',
    'knownIssuesXianming',
    'knownIssuesFightingSave',
    'knownIssuesLocalExec',
    'knownIssuesSliceQuality',
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 600.0,
      height: 480.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('knownIssues')),
          actions: [
            CloseButton2(
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(engine.locale('knownIssuesIntro')),
              ),
              for (final key in _issueKeys)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text('· ${engine.locale(key)}'),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Text(engine.locale('knownIssuesFeedback')),
              ),
              SelectableText(engine.locale('knownIssuesUrl')),
            ],
          ),
        ),
      ),
    );
  }
}
