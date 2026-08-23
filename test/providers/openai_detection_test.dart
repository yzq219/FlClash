import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/common/request.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  late HttpClientAdapter originalAdapter;

  setUp(() {
    originalAdapter = request.openAIClientForTesting.httpClientAdapter;
  });

  tearDown(() {
    request.openAIClientForTesting.httpClientAdapter = originalAdapter;
  });

  test('dashboard gate is disabled until the OpenAI widget is added', () {
    final withoutWidget = ProviderContainer(
      overrides: [
        initProvider.overrideWithBuild((_, _) => true),
        runTimeProvider.overrideWithBuild((_, _) => 1),
        dashboardStateProvider.overrideWithValue(
          const DashboardState(
            dashboardWidgets: [DashboardWidget.networkDetection],
            contentWidth: 320,
          ),
        ),
      ],
    );
    addTearDown(withoutWidget.dispose);
    expect(withoutWidget.read(checkOpenAIIPProvider).d, false);

    final withWidget = ProviderContainer(
      overrides: [
        initProvider.overrideWithBuild((_, _) => true),
        runTimeProvider.overrideWithBuild((_, _) => 1),
        dashboardStateProvider.overrideWithValue(
          const DashboardState(
            dashboardWidgets: [DashboardWidget.openAIDetection],
            contentWidth: 320,
          ),
        ),
      ],
    );
    addTearDown(withWidget.dispose);
    expect(withWidget.read(checkOpenAIIPProvider).d, true);
  });

  test('core-off start request is ignored and clears stale state', () async {
    final adapter = _CountingAdapter('ip=203.0.113.8\nloc=US\n');
    request.openAIClientForTesting.httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        initProvider.overrideWithBuild((_, _) => true),
        runTimeProvider.overrideWithBuild((_, _) => null),
      ],
    );
    addTearDown(container.dispose);

    container.read(openAINetworkDetectionProvider.notifier).startCheck();
    await Future<void>.delayed(
      commonDuration + const Duration(milliseconds: 50),
    );

    final state = container.read(openAINetworkDetectionProvider);
    expect(adapter.requestCount, 0);
    expect(state.isLoading, false);
    expect(state.ipInfo, isNull);
  });

  test('initialized running core produces an OpenAI egress result', () async {
    final adapter = _CountingAdapter('ip=203.0.113.8\nloc=US\n');
    request.openAIClientForTesting.httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        initProvider.overrideWithBuild((_, _) => true),
        runTimeProvider.overrideWithBuild((_, _) => 1),
      ],
    );
    addTearDown(container.dispose);

    container.read(openAINetworkDetectionProvider.notifier).startCheck();
    await Future<void>.delayed(
      commonDuration + const Duration(milliseconds: 80),
    );

    final state = container.read(openAINetworkDetectionProvider);
    expect(adapter.requestCount, 1);
    expect(state.isLoading, false);
    expect(state.ipInfo?.ip, '203.0.113.8');
  });

  test('stop cancels an in-flight request and clears the result', () async {
    final adapter = _PendingAdapter();
    request.openAIClientForTesting.httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        initProvider.overrideWithBuild((_, _) => true),
        runTimeProvider.overrideWithBuild((_, _) => 1),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(openAINetworkDetectionProvider.notifier);

    notifier.startCheck();
    await Future<void>.delayed(
      commonDuration + const Duration(milliseconds: 50),
    );
    notifier.stopCheck();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = container.read(openAINetworkDetectionProvider);
    expect(adapter.requestCount, 1);
    expect(adapter.wasCancelled, true);
    expect(state.isLoading, false);
    expect(state.ipInfo, isNull);
  });

  test('a canceled stale response cannot replace a newer result', () async {
    request.openAIClientForTesting.httpClientAdapter = _SequencedAdapter();
    final container = ProviderContainer(
      overrides: [
        initProvider.overrideWithBuild((_, _) => true),
        runTimeProvider.overrideWithBuild((_, _) => 1),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(openAINetworkDetectionProvider.notifier);

    notifier.startCheck();
    await Future<void>.delayed(
      commonDuration + const Duration(milliseconds: 50),
    );
    notifier.startCheck();
    await Future<void>.delayed(
      commonDuration + const Duration(milliseconds: 80),
    );

    expect(
      container.read(openAINetworkDetectionProvider).ipInfo?.ip,
      '203.0.113.9',
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(
      container.read(openAINetworkDetectionProvider).ipInfo?.ip,
      '203.0.113.9',
    );
  });
}

class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter(this.body);

  final String body;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    return ResponseBody(
      Stream.value(Uint8List.fromList(utf8.encode(body))),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.textPlainContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _PendingAdapter implements HttpClientAdapter {
  int requestCount = 0;
  bool wasCancelled = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requestCount++;
    final completer = Completer<ResponseBody>();
    cancelFuture?.then((_) {
      wasCancelled = true;
      if (completer.isCompleted) return;
      completer.completeError(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: 'cancelled',
        ),
      );
    });
    return completer.future;
  }

  @override
  void close({bool force = false}) {}
}

class _SequencedAdapter implements HttpClientAdapter {
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requestCount++;
    if (requestCount == 1) {
      final completer = Completer<ResponseBody>();
      cancelFuture?.then((_) {
        Timer(const Duration(milliseconds: 100), () {
          if (completer.isCompleted) return;
          completer.completeError(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'cancelled',
            ),
          );
        });
      });
      return completer.future;
    }
    return Future<ResponseBody>.delayed(
      const Duration(milliseconds: 10),
      () => ResponseBody(
        Stream.value(
          Uint8List.fromList(utf8.encode('ip=203.0.113.9\nloc=JP\n')),
        ),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.textPlainContentType],
        },
      ),
    );
  }

  @override
  void close({bool force = false}) {}
}
