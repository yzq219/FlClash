import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/open_ai_detection.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the OpenAI egress country and IP', (tester) async {
    await _pumpDetection(
      tester,
      isStart: true,
      state: const NetworkDetectionState(
        isLoading: false,
        ipInfo: IpInfo(ip: '203.0.113.8', countryCode: 'US'),
      ),
    );

    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('🇺🇸'), findsOneWidget);
    expect(find.text('203.0.113.8'), findsOneWidget);
    expect(
      tester.getSize(find.byType(OpenAIDetection)).height,
      getWidgetHeight(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a disconnected placeholder instead of a stale IP', (
    tester,
  ) async {
    await _pumpDetection(
      tester,
      isStart: false,
      state: const NetworkDetectionState(
        isLoading: false,
        ipInfo: IpInfo(ip: '203.0.113.8', countryCode: 'US'),
      ),
    );

    expect(find.text('--'), findsOneWidget);
    expect(find.byIcon(Icons.network_check), findsOneWidget);
    expect(find.text('203.0.113.8'), findsNothing);
    expect(find.text('🇺🇸'), findsNothing);
  });

  testWidgets('shows loading and timeout states without changing card size', (
    tester,
  ) async {
    await _pumpDetection(
      tester,
      isStart: true,
      state: const NetworkDetectionState(isLoading: true, ipInfo: null),
    );
    final loadingHeight = tester.getSize(find.byType(OpenAIDetection)).height;
    expect(find.byType(CommonCircleLoading), findsOneWidget);
    expect(find.byIcon(Icons.network_check), findsOneWidget);
    expect(find.text('🇨🇳'), findsNothing);

    await _pumpDetection(
      tester,
      isStart: true,
      state: const NetworkDetectionState(isLoading: false, ipInfo: null),
    );
    expect(find.text('Timeout'), findsOneWidget);
    expect(tester.getSize(find.byType(OpenAIDetection)).height, loadingHeight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows loading instead of timeout while auto-start initializes', (
    tester,
  ) async {
    await _pumpDetection(
      tester,
      isStart: true,
      isInit: false,
      state: const NetworkDetectionState(isLoading: false, ipInfo: null),
    );

    expect(find.byIcon(Icons.network_check), findsOneWidget);
    expect(find.byType(CommonCircleLoading), findsOneWidget);
    expect(find.text('Timeout'), findsNothing);
    expect(find.text('--'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDetection(
  WidgetTester tester, {
  required bool isStart,
  bool isInit = true,
  required NetworkDetectionState state,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  final container = ProviderContainer(
    overrides: [
      initProvider.overrideWithBuild((_, _) => isInit),
      runTimeProvider.overrideWithBuild((_, _) => isStart ? 1 : null),
      openAINetworkDetectionProvider.overrideWithValue(state),
    ],
  );
  addTearDown(container.dispose);
  globalState.container = container;
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const _TestApp()),
  );
  await tester.pump();
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalState.navigatorKey,
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
      home: const Scaffold(
        body: SizedBox(width: 160, child: OpenAIDetection()),
      ),
    );
  }
}
