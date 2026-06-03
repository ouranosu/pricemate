import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('PriceMate'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: l10n.notifTooltip,
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.notifComingSoon)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _StorePage(
          store: store,
          selectedIndex: selectedIndex,
          onLogout: widget.onLogout,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.fabTooltip,
        onPressed: () {
          debugLog('FAB tap input');
          setState(() => selectedIndex = 5);
        },
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomAppBar(
        height: 64,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: l10n.tabHome,
                active: selectedIndex == 0,
                onTap: () {
                  debugLog('Tab tap home');
                  setState(() => selectedIndex = 0);
                },
              ),
            ),
            Expanded(
              child: _TabButton(
                icon: Icons.checklist_outlined,
                activeIcon: Icons.checklist,
                label: l10n.tabShopping,
                active: selectedIndex == 1,
                onTap: () {
                  debugLog('Tab tap shopping');
                  setState(() => selectedIndex = 1);
                },
              ),
            ),
            Expanded(
              child: _TabButton(
                icon: Icons.history,
                activeIcon: Icons.history,
                label: l10n.tabHistory,
                active: selectedIndex == 2,
                onTap: () {
                  debugLog('Tab tap history');
                  setState(() => selectedIndex = 2);
                },
              ),
            ),
            Expanded(
              child: _TabButton(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2,
                label: l10n.tabProducts,
                active: selectedIndex == 3,
                onTap: () {
                  debugLog('Tab tap products');
                  setState(() => selectedIndex = 3);
                },
              ),
            ),
            Expanded(
              child: _TabButton(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: l10n.tabSettings,
                active: selectedIndex == 4,
                onTap: () {
                  debugLog('Tab tap settings');
                  setState(() => selectedIndex = 4);
                },
              ),
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
    required this.onLogout,
  });

  final AppStore store;
  final int selectedIndex;
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
          0 => HomeView(store: store),
          1 => ShoppingListView(store: store),
          2 => PurchaseHistoryView(store: store),
          3 => ProductListView(store: store),
          4 => SettingsView(store: store, onLogout: onLogout),
          _ => InputView(store: store),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey<int>(selectedIndex),
            child: page,
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color =
        active ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return Semantics(
      label: label,
      selected: active,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 28 : 0,
                height: 3,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(active ? activeIcon : icon, color: color),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
