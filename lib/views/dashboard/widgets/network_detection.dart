import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/views/dashboard/widgets/ip_detection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkDetection extends ConsumerWidget {
  const NetworkDetection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final state = ref.watch(networkDetectionProvider);
    return IPDetectionCard(
      title: appLocalizations.networkDetection,
      tip: appLocalizations.detectionTip,
      state: state,
      onPressed: () {
        ref.read(networkDetectionProvider.notifier).startCheck();
      },
    );
  }
}
