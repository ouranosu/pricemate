import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';

Future<void> showThemeSheet(BuildContext context, AppStore store) async {
  var isProcessing = false;

  final selected = await showModalBottomSheet<AppThemePreset>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final l10n = AppLocalizations.of(context)!;
          return FractionallySizedBox(
            heightFactor: 0.75,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetTitle(title: l10n.themeColorTitle),
                  Text(l10n.themeColorDesc),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...themePresets.map(
                              (theme) => _ThemePresetTile(
                                theme: theme,
                                selected: store.selectedTheme.id == theme.id,
                                onTap: isProcessing
                                    ? null
                                    : () {
                                        setSheetState(
                                          () => isProcessing = true,
                                        );
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (context.mounted) {
                                                Navigator.pop(context, theme);
                                              }
                                            });
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  if (selected != null) {
    store.selectTheme(selected);
  }
}

class _ThemePresetTile extends StatelessWidget {
  const _ThemePresetTile({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final AppThemePreset theme;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _ColorSwatch(color: theme.seedColor),
      title: Text(theme.name),
      subtitle: Text(theme.description),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
