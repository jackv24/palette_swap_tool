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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final headerTextStyle = theme.textTheme.titleLarge;

    const headingPadding = 8.0;
    const sectionPadding = 32.0;
    const columnPadding = 48.0;

    const fileListWidth = 200.0;
    const scrollBarPadding = 12.0;

    Widget? flexibleSpace;
    if (isDesktop) {
      final windowButtonColors = WindowButtonColors(
        iconNormal: colorScheme.onBackground,
        mouseOver: colorScheme.tertiary,
        iconMouseOver: colorScheme.onTertiary,
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
                      processImages: _processImages,
                    ),
                    const SizedBox(height: headingPadding),
                    Text(
                      "${_loadedImages.length} files loaded:",
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: headingPadding),
                    Expanded(
                      child: SizedBox(
                        width: fileListWidth,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.only(right: scrollBarPadding),
                          itemBuilder: (context, index) {
                            final image = _loadedImages[index];
                            return Card(
                              child: Column(
                                children: [
                                  Text(image.fileName),
                                  Image.memory(
                                    image.bytes,
                                    height: 150,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.none,
                                  )
                                ],
                              ),
                            );
                          },
                          itemCount: _loadedImages.length,
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
                      Text(
                        "${_loadedPalettes.length} files loaded:",
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: headingPadding),
                      ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(right: scrollBarPadding),
                        itemBuilder: (context, index) {
                          final image = _loadedPalettes[index];
                          return Card(
                            child: Column(
                              children: [
                                Text(image.fileName),
                                Image.memory(
                                  image.bytes,
                                  height: 50,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none,
                                )
                              ],
                            ),
                          );
                        },
                        itemCount: _loadedPalettes.length,
                      ),
                      const SizedBox(height: sectionPadding),
                      Text("Preview", style: headerTextStyle),
                      Expanded(child: Container()),
                    ],
                  ),
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

  _onLoadedImages(List<LoadedImage> images) =>
      setState(() => _loadedImages = images);

  Future<List<LoadedImage>> _processImages(List<LoadedImage> images) =>
      processLoadedImages(images, trimMode: image_util.TrimMode.transparent);

  _onLoadedPalettes(List<LoadedImage> images) =>
      setState(() => _loadedPalettes = images);

  Future<List<LoadedImage>> _processPalettes(List<LoadedImage> images) =>
      processLoadedImages(images,
          trimMode: image_util.TrimMode.bottomRightColor);
}
