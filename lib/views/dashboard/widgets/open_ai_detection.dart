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
    final isStart = ref.watch(isStartProvider);
    return IPDetectionCard(
      title: 'OpenAI',
      tip: context.appLocalizations.openAIDetectionTip,
      state: state,
      isConnected: isStart,
    );
  }
}
