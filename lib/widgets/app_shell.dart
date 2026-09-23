import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../core/debug.dart';
import '../features/home/home_view.dart';
import '../l10n/app_localizations.dart';
import '../features/history/purchase_history_view.dart';
import '../features/input/input_view.dart';
import '../features/products/product_list_view.dart';
import '../features/settings/settings_view.dart';
import '../features/shopping/shopping_list_view.dart';
import '../store/app_store.dart';

class PriceMateShell extends StatefulWidget {
  const PriceMateShell({
    super.key,
    required this.store,
    required this.onLogout,
  });

  final AppStore store;
  final VoidCallback onLogout;

  @override
  State<PriceMateShell> createState() => _PriceMateShellState();
}

class _PriceMateShellState extends State<PriceMateShell> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    debugLog('PriceMateShell initState');
  }

  @override
  void dispose() {
    debugLog('PriceMateShell dispose selectedIndex=$selectedIndex');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    final l10n = AppLocalizations.of(context)!;
    debugLog('PriceMateShell build selectedIndex=$selectedIndex');
    return ShowCaseWidget(
      builder: (showcaseCtx) => Scaffold(
        appBar: AppBar(title: const Text('PriceMate'), centerTitle: false),
        body: SafeArea(
          child: _StorePage(
            store: store,
            selectedIndex: selectedIndex,
            onSelectTab: (index) => setState(() => selectedIndex = index),
            onLogout: widget.onLogout,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => selectedIndex = index),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.tabHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.shopping_basket_outlined),
              selectedIcon: const Icon(Icons.shopping_basket_rounded),
              label: l10n.tabShopping,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: l10n.tabHistory,
            ),
            NavigationDestination(
              icon: const Icon(Icons.local_offer_outlined),
              selectedIcon: const Icon(Icons.local_offer),
              label: l10n.tabProducts,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.tabSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _StorePage extends StatelessWidget {
  const _StorePage({
    required this.store,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onLogout,
  });

  final AppStore store;
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        debugLog(
          'StorePage rebuild selectedIndex=$selectedIndex '
          'space=${store.activeSpaceId}',
        );
        final page = switch (selectedIndex) {
          0 => HomeView(store: store, onNavigateTab: onSelectTab),
          1 => ShoppingListView(store: store),
          2 => PurchaseHistoryView(store: store),
          3 => ProductListView(store: store),
          4 => SettingsView(store: store, onLogout: onLogout),
          _ => InputView(store: store),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey<int>(selectedIndex), child: page),
        );
      },
    );
  }
}
