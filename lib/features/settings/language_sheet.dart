import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';

const _localeOptions = [
  (code: 'ja', flag: '🇯🇵', name: '日本語'),
  (code: 'en', flag: '🇺🇸', name: 'English'),
];

// Sentinel: "use system locale" selection (not a real language code).
const _systemLocale = Locale('system');

String localeName(Locale? locale) {
  if (locale == null) return 'システム';
  return switch (locale.languageCode) {
    'ja' => '日本語',
    'en' => 'English',
    _ => 'システム',
  };
}

Future<void> showLanguageSheet(BuildContext context, AppStore store) async {
  final result = await showModalBottomSheet<Locale>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final current = store.localeNotifier.value;
      return FractionallySizedBox(
        heightFactor: 0.6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(title: l10n.languageSheetTitle),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LocaleTile(
                          flag: '⚙️',
                          name: l10n.systemLanguage,
                          selected: current == null,
                          onTap: () => Navigator.pop(context, _systemLocale),
                        ),
                        const Divider(height: 1),
                        ...List.generate(_localeOptions.length, (i) {
                          final opt = _localeOptions[i];
                          final locale = Locale(opt.code);
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LocaleTile(
                                flag: opt.flag,
                                name: opt.name,
                                selected: current?.languageCode == opt.code,
                                onTap: () => Navigator.pop(context, locale),
                              ),
                              if (i < _localeOptions.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        }),
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

  if (result == null) return; // dismissed without selection
  store.selectLocale(result == _systemLocale ? null : result);
}

class _LocaleTile extends StatelessWidget {
  const _LocaleTile({
    required this.flag,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(name),
      trailing: selected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
