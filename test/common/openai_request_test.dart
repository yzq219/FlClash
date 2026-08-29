import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/request.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpClientAdapter originalAdapter;

  setUp(() {
    originalAdapter = request.openAIClientForTesting.httpClientAdapter;
  });

  tearDown(() {
    request.openAIClientForTesting.httpClientAdapter = originalAdapter;
  });

  test('OpenAI trace request uses the expected endpoint and headers', () async {
    final adapter = _StaticAdapter(
      statusCode: HttpStatus.ok,
      body: 'ip=203.0.113.8\nloc=us\n',
    );
    request.openAIClientForTesting.httpClientAdapter = adapter;

    final result = await request.checkOpenAIIP();

    expect(result.type, ResultType.success);
    expect(result.data?.ip, '203.0.113.8');
    expect(result.data?.countryCode, 'US');
    expect(adapter.lastOptions?.uri.toString(), Request.openAITraceUrl);
    expect(
      adapter.lastOptions?.headers[HttpHeaders.userAgentHeader],
      'FlClash OpenAI IP Check',
    );
  });

  test('non-200 and invalid trace responses return no IP', () async {
    request.openAIClientForTesting.httpClientAdapter = _StaticAdapter(
      statusCode: HttpStatus.serviceUnavailable,
      body: 'unavailable',
    );
    expect((await request.checkOpenAIIP()).data, isNull);

    request.openAIClientForTesting.httpClientAdapter = _StaticAdapter(
      statusCode: HttpStatus.ok,
      body: 'ip=invalid\nloc=US\n',
    );
    expect((await request.checkOpenAIIP()).data, isNull);
  });

  test('cancellation is reported as an error result', () async {
    request.openAIClientForTesting.httpClientAdapter = _PendingAdapter();
    final cancelToken = CancelToken();
    final future = request.checkOpenAIIP(cancelToken: cancelToken);

    cancelToken.cancel();

    final result = await future;
    expect(result.type, ResultType.error);
    expect(result.message, 'cancelled');
  });

  test('timeout cancels the request and returns no IP', () async {
    request.openAIClientForTesting.httpClientAdapter = _PendingAdapter();

    final result = await request.checkOpenAIIP(
      timeout: const Duration(milliseconds: 20),
    );

    expect(result.type, ResultType.success);
    expect(result.data, isNull);
  });
}

class _StaticAdapter implements HttpClientAdapter {
  _StaticAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody(
      Stream.value(Uint8List.fromList(utf8.encode(body))),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.textPlainContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _PendingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final completer = Completer<ResponseBody>();
    cancelFuture?.then((_) {
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
