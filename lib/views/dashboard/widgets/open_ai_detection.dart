import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/views/dashboard/widgets/ip_detection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OpenAIDetection extends ConsumerWidget {
  const OpenAIDetection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(openAINetworkDetectionProvider);
    final isInit = ref.watch(initProvider);
    final isStart = ref.watch(isStartProvider);
    final displayState = isStart && !isInit
        ? state.copyWith(isLoading: true, ipInfo: null)
        : state;
    return IPDetectionCard(
      title: 'OpenAI',
      tip: context.appLocalizations.openAIDetectionTip,
      state: displayState,
      isConnected: isStart,
    );
  }
}
