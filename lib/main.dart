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

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<LoadedImage> _loadedImages = [];
  List<LoadedImage> _loadedPalettes = [];
  List<LoadedImage> _processedImages = [];

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
                    LoadImagesButtons(
                      onLoadedImages: _onLoadedImages,
                      processImages: _processInputImages,
                    ),
                    const SizedBox(height: headingPadding),
                    _ListHeading(
                      listCount: _loadedImages.length,
                      onListClearPressed: _clearImages,
                    ),
                    const SizedBox(height: headingPadding),
                    Expanded(
                      child: SizedBox(
                        width: fileListWidth,
                        child: _ImageListView(
                          images: _loadedImages,
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
                      LoadImagesButtons(
                        onLoadedImages: _onLoadedPalettes,
                        processImages: _processPalettes,
                      ),
                      const SizedBox(height: headingPadding),
                      _ListHeading(
                        listCount: _loadedPalettes.length,
                        onListClearPressed: _clearPalettes,
                      ),
                      const SizedBox(height: headingPadding),
                      Flexible(
                        child: _ImageListView(
                          images: _loadedPalettes,
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
                      onPressed: _processOutputImages,
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
                          images: _processedImages,
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

  void _onLoadedImages(List<LoadedImage> images) =>
      setState(() => _loadedImages = images);

  Future<List<LoadedImage>> _processInputImages(List<LoadedImage> images) =>
      processLoadedImages(images, trimMode: image_util.TrimMode.transparent);

  void _clearImages() => setState((() => _loadedImages.clear()));

  void _onLoadedPalettes(List<LoadedImage> images) =>
      setState(() => _loadedPalettes = images);

  Future<List<LoadedImage>> _processPalettes(List<LoadedImage> images) =>
      processLoadedImages(images,
          trimMode: image_util.TrimMode.bottomRightColor);

  void _clearPalettes() => setState((() => _loadedPalettes.clear()));

  Future<void> _processOutputImages() async {
    // TODO
    Future.delayed(const Duration(seconds: 2));
  }
}

class _ListHeading extends StatelessWidget {
  final int listCount;
  final void Function() onListClearPressed;

  const _ListHeading({
    Key? key,
    required this.listCount,
    required this.onListClearPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          "$listCount files loaded",
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: onListClearPressed,
          icon: const Icon(Icons.clear_all),
          label: const Text("Clear All"),
        ),
      ],
    );
  }
}

class _ImageListView extends StatelessWidget {
  final List<LoadedImage> images;
  final double? itemHeight;

  const _ImageListView({
    Key? key,
    required this.images,
    this.itemHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const scrollBarPadding = 12.0;

    return ListView.builder(
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
    );
  }
}
