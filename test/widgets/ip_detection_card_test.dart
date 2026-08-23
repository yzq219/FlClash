import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/ip_detection_card.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('invokes the supplied refresh callback when tapped', (
    tester,
  ) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.delegate.supportedLocales,
        builder: (context, child) {
          globalState.measure = Measure.of(context, 1);
          globalState.theme = CommonTheme.of(context, 1);
          return child!;
        },
        home: Scaffold(
          body: SizedBox(
            width: 160,
            child: IPDetectionCard(
              title: 'Detection',
              tip: 'Tip',
              state: const NetworkDetectionState(
                isLoading: false,
                ipInfo: IpInfo(ip: '203.0.113.8', countryCode: 'US'),
              ),
              onPressed: () {
                refreshCount++;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(CommonCard));
    await tester.pump();

    expect(refreshCount, 1);
  });
}
