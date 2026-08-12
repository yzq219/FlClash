import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoriteProxies extends ConsumerWidget {
  const FavoriteProxies({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProxiesProvider);
    final savedFavorites = ref.watch(
      currentProfileProvider.select(
        (profile) => profile?.favoriteProxies ?? [],
      ),
    );
    final isInit = ref.watch(initProvider);
    final isLoading = favorites.isEmpty && savedFavorites.isNotEmpty && !isInit;
    return CommonCard(
      info: Info(
        label: context.appLocalizations.favoriteProxies,
        iconData: Icons.star,
      ),
      child: Padding(
        padding: baseInfoEdgeInsets.copyWith(top: 8),
        child: SizedBox(
          height: getWidgetHeight(1),
          child: favorites.isEmpty
              ? isLoading
                    ? const _FavoriteProxiesLoading()
                    : _FavoriteProxiesEmpty(
                        label: context.appLocalizations.favoriteProxiesEmpty,
                      )
              : _FavoriteProxiesRow(favorites: favorites),
        ),
      ),
    );
  }
}

class _FavoriteProxiesRow extends StatelessWidget {
  final List<FavoriteProxy> favorites;

  const _FavoriteProxiesRow({required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int index = 0; index < favorites.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: _FavoriteProxyItem(favorite: favorites[index])),
        ],
      ],
    );
  }
}

class _FavoriteProxiesLoading extends StatelessWidget {
  const _FavoriteProxiesLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: CommonCircleLoading.defaultDimension,
        child: CommonCircleLoading(),
      ),
    );
  }
}

class _FavoriteProxiesEmpty extends StatelessWidget {
  final String label;

  const _FavoriteProxiesEmpty({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FavoriteProxyItem extends ConsumerWidget {
  final FavoriteProxy favorite;

  const _FavoriteProxyItem({required this.favorite});

  void _handleChangeProxy() {
    final ref = globalState.container;
    ref
        .read(profilesActionProvider.notifier)
        .updateCurrentSelectedMap(favorite.groupName, favorite.proxyName);
    ref
        .read(proxiesActionProvider.notifier)
        .changeProxyDebounce(favorite.groupName, favorite.proxyName);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProxyName = ref.watch(
      selectedProxyNameProvider(favorite.groupName),
    );
    return CommonCard(
      type: CommonCardType.filled,
      isSelected: selectedProxyName == favorite.proxyName,
      onPressed: _handleChangeProxy,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Center(
          child: EmojiText(
            favorite.proxyName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.toSoftBold,
          ),
        ),
      ),
    );
  }
}
