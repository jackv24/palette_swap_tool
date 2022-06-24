import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_swap_tool/utils/settings.dart';
import 'package:palette_swap_tool/widgets/load_images_buttons.dart';
import 'package:palette_swap_tool/widgets/theme_mode_button.dart';
import 'package:palette_swap_tool/utils/image.dart';
import 'package:image/image.dart' as image_util;

void main() {
  runApp(const ProviderScope(child: MyApp()));
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

    const headingPadding = 8.0;
    const sectionPadding = 32.0;
    const columnPadding = 48.0;

    const fileListWidth = 200.0;
    const scrollBarPadding = 12.0;

    return Scaffold(
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
                    Text("Input Files", style: theme.textTheme.headlineLarge),
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
                      Text("Palettes", style: theme.textTheme.headlineLarge),
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
                      Text("Preview", style: theme.textTheme.headlineLarge),
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
