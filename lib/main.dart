import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_swap_tool/utils/settings.dart';
import 'package:palette_swap_tool/widgets/load_images_buttons.dart';
import 'package:palette_swap_tool/widgets/theme_mode_button.dart';
import 'package:palette_swap_tool/utils/image.dart';
import 'package:image/image.dart' as image_util;
import 'package:bitsdojo_window/bitsdojo_window.dart';

const appTitle = "Palette Swap Tool";

bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(
    child: MyApp(),
  ));

  if (isDesktop) {
    doWhenWindowReady(() {
      appWindow.minSize = const Size(600, 200);
      appWindow.size = const Size(800, 600);
      appWindow.alignment = Alignment.center;
      appWindow.title = appTitle;
      appWindow.show();
    });
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    const seedColor = Colors.teal;

    return MaterialApp(
      title: 'Palette Swap Tool',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seedColor,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seedColor,
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final headerTextStyle = theme.textTheme.titleLarge;

    const headingPadding = 8.0;
    const sectionPadding = 32.0;
    const columnPadding = 48.0;

    const fileListWidth = 200.0;
    const fileListItemHeight = 150.0;
    const paletteListItemHeight = 50.0;
    const previewHeight = 300.0;

    // On desktop we need window buttons, since system window border is hidden
    Widget? flexibleSpace;
    if (isDesktop) {
      final windowButtonColors = WindowButtonColors(
        iconNormal: colorScheme.onBackground,
        mouseOver: colorScheme.surfaceVariant,
        iconMouseOver: colorScheme.onSurfaceVariant,
      );
      final windowCloseButtonColors = WindowButtonColors(
        mouseOver: const Color(0xFFD32F2F),
        mouseDown: const Color(0xFFB71C1C),
        iconNormal: colorScheme.onBackground,
        iconMouseOver: const Color(0xFFFFFFFF),
      );

      flexibleSpace = Stack(children: [
        MoveWindow(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              children: [
                WindowTitleBarBox(
                  child: Row(
                    children: [
                      MinimizeWindowButton(colors: windowButtonColors),
                      MaximizeWindowButton(colors: windowButtonColors),
                      CloseWindowButton(colors: windowCloseButtonColors),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const IgnorePointer(
          child: Text(appTitle),
        ),
        flexibleSpace: flexibleSpace,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Input Files", style: headerTextStyle),
                    const SizedBox(height: headingPadding),
                    LoadImagesButtons(loadedImagesProvider),
                    const SizedBox(height: headingPadding),
                    _ListHeading(loadedImagesProvider),
                    const SizedBox(height: headingPadding),
                    Expanded(
                      child: SizedBox(
                        width: fileListWidth,
                        child: _ImageListView(
                          imageProvider: trimmedImagesProvider,
                          itemHeight: fileListItemHeight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: columnPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Palettes", style: headerTextStyle),
                      const SizedBox(height: headingPadding),
                      LoadImagesButtons(loadedPalettesProvider),
                      const SizedBox(height: headingPadding),
                      _ListHeading(loadedPalettesProvider),
                      const SizedBox(height: headingPadding),
                      Flexible(
                        child: _ImageListView(
                          imageProvider: trimmedPalettesProvider,
                          itemHeight: paletteListItemHeight,
                        ),
                      ),
                      const SizedBox(height: sectionPadding),
                      Text("Preview", style: headerTextStyle),
                      const SizedBox(height: previewHeight),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Output Files", style: headerTextStyle),
                    const SizedBox(height: headingPadding),
                    ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Refresh"),
                    ),
                    const SizedBox(height: headingPadding),
                    ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.save),
                      label: const Text("Output To Folder"),
                    ),
                    const SizedBox(height: headingPadding),
                    Expanded(
                      child: SizedBox(
                        width: fileListWidth,
                        child: _ImageListView(
                          imageProvider: outputImagesProvider,
                          itemHeight: fileListItemHeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.all(12.0),
            child: const ThemeModeButton(),
          ),
        ],
      ),
    );
  }
}

class _ListHeading extends ConsumerWidget {
  final StateNotifierProvider<LoadedImagesNotifier, List<LoadedImage>>
      listProvider;

  const _ListHeading(this.listProvider, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(listProvider);

    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          "${list.length} files loaded",
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () {
            ref.read(listProvider.notifier).clear();
          },
          icon: const Icon(Icons.clear_all),
          label: const Text("Clear All"),
        ),
      ],
    );
  }
}

class _ImageListView extends ConsumerWidget {
  final FutureProvider<List<LoadedImage>> imageProvider;
  final double? itemHeight;

  const _ImageListView({
    Key? key,
    required this.imageProvider,
    this.itemHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const scrollBarPadding = 12.0;

    final asyncImages = ref.watch(imageProvider);
    return asyncImages.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => ErrorWidget(err),
      data: (images) => ListView.builder(
        primary: false,
        shrinkWrap: true,
        padding: const EdgeInsets.only(right: scrollBarPadding),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          return Card(
            child: Column(
              children: [
                Text(image.fileName),
                Image.memory(
                  image.bytes,
                  height: itemHeight,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
