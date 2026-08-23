import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class IPDetectionCard extends StatelessWidget {
  final String title;
  final String tip;
  final NetworkDetectionState state;
  final bool isConnected;
  final VoidCallback? onPressed;

  const IPDetectionCard({
    super.key,
    required this.title,
    required this.tip,
    required this.state,
    this.isConnected = true,
    this.onPressed,
  });

  String _countryCodeToEmoji(String countryCode) {
    final code = countryCode.toUpperCase();
    if (code.length != 2) return countryCode;
    final firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  @override
  Widget build(BuildContext context) {
    final ipInfo = state.ipInfo;
    final emojiTextStyle = context.textTheme.titleMedium?.toLight.copyWith(
      fontFamily: FontFamily.twEmoji.value,
    );
    final titleTextStyle = context.colorScheme.onSurfaceVariant;
    final descTextStyle = context.textTheme.titleSmall?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
    );
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        onPressed: onPressed ?? () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: globalState.measure.titleMediumHeight + 16,
              padding: baseInfoEdgeInsets.copyWith(bottom: 0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildLeading(
                    ipInfo: ipInfo,
                    emojiTextStyle: emojiTextStyle,
                    color: titleTextStyle,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: TooltipText(
                      text: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: descTextStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  AspectRatio(
                    aspectRatio: 1,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        globalState.showMessage(
                          title: context.appLocalizations.tip,
                          message: TextSpan(text: tip),
                          cancelable: false,
                        );
                      },
                      icon: Icon(
                        size: 16.ap,
                        Icons.info_outline,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: baseInfoEdgeInsets.copyWith(top: 0),
              child: SizedBox(
                height: globalState.measure.bodyMediumHeight + 2,
                child: FadeThroughBox(child: _buildValue(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading({
    required IpInfo? ipInfo,
    required TextStyle? emojiTextStyle,
    required Color color,
  }) {
    if (ipInfo != null && isConnected) {
      return Text(
        _countryCodeToEmoji(ipInfo.countryCode),
        style: emojiTextStyle,
      );
    }
    return Icon(Icons.network_check, color: color);
  }

  Widget _buildValue(BuildContext context) {
    final ipInfo = state.ipInfo;
    if (!isConnected) {
      return Text(
        '--',
        style: context.textTheme.bodyMedium?.toLight.adjustSize(1),
      );
    }
    if (ipInfo != null) {
      return TooltipText(
        text: Text(
          ipInfo.ip,
          style: context.textTheme.bodyMedium?.toLight.adjustSize(1),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    if (!state.isLoading) {
      return Text(
        'Timeout',
        style: context.textTheme.bodyMedium
            ?.copyWith(color: Colors.red)
            .adjustSize(1),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Container(
      padding: const EdgeInsets.all(2),
      child: const AspectRatio(aspectRatio: 1, child: CommonCircleLoading()),
    );
  }
}
