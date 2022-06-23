import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_swap_tool/settings.dart';

class ThemeModeButton extends ConsumerWidget {
  final Color? color;

  const ThemeModeButton({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show icon for current theme mode
    final themeMode = ref.watch(themeModeProvider);
    final IconData icon;
    switch (themeMode) {
      case ThemeMode.system:
        icon = Icons.brightness_auto;
        break;
      case ThemeMode.light:
        icon = Icons.brightness_5;
        break;
      case ThemeMode.dark:
        icon = Icons.brightness_4;
        break;
    }

    return IconButton(
      onPressed: () {
        // Cycle theme modes
        final nextIndex = (themeMode.index + 1) % ThemeMode.values.length;
        final newThemeMode = ThemeMode.values[nextIndex];
        ref.read(themeModeProvider.notifier).setValue(newThemeMode);
      },
      icon: Icon(icon),
      color: color,
    );
  }
}
