import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_swap_tool/utils/color.dart';
import 'package:palette_swap_tool/utils/settings.dart';
import 'package:palette_swap_tool/widgets/load_image_button.dart';
import 'package:palette_swap_tool/widgets/load_images_buttons.dart';
import 'package:palette_swap_tool/widgets/theme_mode_button.dart';
import 'package:palette_swap_tool/utils/image.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:palette_swap_tool/widgets/update_icon.dart';

const appTitle = 'Palette Swap Tool';

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
      appWindow.minSize = const Size(800, 600);
      appWindow.size = const Size(900, 650);
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
    final asyncColor = ref.watch(colorSchemeSeedProvider);
    final seedColor = asyncColor.when(
      data: (data) => data,
      error: (err, stack) => Colors.white,
      loading: () => null,
    );

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
    final header2TextStyle = theme.textTheme.titleMedium;

    const headingPadding = 8.0;
    const sectionPadding = 32.0;
    const columnPadding = 48.0;

    const fileListWidth = 200.0;
    const fileListItemHeight = 150.0;
    const paletteListItemHeight = 50.0;

    // On desktop we need window buttons, since system window border is hidden
    Widget flexibleSpace;
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
            Container(
              alignment: Alignment.topRight,
              padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
              child: UpdateIcon(
                color: colorScheme.tertiary,
              ),
            ),
            Container(
              alignment: Alignment.topRight,
              padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
              child: ThemeModeButton(
                color: colorScheme.tertiary,
              ),
            ),
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
    } else {
      flexibleSpace = Container(
        alignment: Alignment.topRight,
        padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
        child: const ThemeModeButton(),
      );
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
                Flexible(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Input Sprites', style: headerTextStyle),
                    const SizedBox(height: headingPadding),
                    LoadImagesButtons(
                        loadedImagesProvider(ImageCollectionType.input)),
                    const SizedBox(height: headingPadding),
                    _ListHeading(
                        loadedImagesProvider(ImageCollectionType.input)),
                    const SizedBox(height: headingPadding),
                    Expanded(
                      child: SizedBox(
                        width: fileListWidth,
                        child: _ImageListView(
                          imageProvider:
                              displayImagesProvider(ImageCollectionType.input),
                          selectedProvider: selectedInputImageProvider,
                          itemHeight: fileListItemHeight,
                        ),
                      ),
                    ),
                  ],
                )),
                const SizedBox(width: columnPadding),
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Default Palette', style: headerTextStyle),
                      const SizedBox(height: headingPadding),
                      Wrap(
                        children: [
                          Text('Loaded Base Palette', style: header2TextStyle),
                          LoadImageButton(loadedInputPaletteProvider),
                          Consumer(
                            builder: (context, ref, child) {
                              final palette =
                                  ref.watch(loadedInputPaletteProvider);
                              return TextButton.icon(
                                onPressed: palette != null
                                    ? () {
                                        ref
                                            .read(loadedInputPaletteProvider
                                                .notifier)
                                            .update(null);
                                      }
                                    : null,
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Clear'),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: headingPadding),
                      Consumer(builder: (context, ref, child) {
                        final asyncImage =
                            ref.watch(displayInputPaletteProvider);
                        return asyncImage.when(
                          data: (image) {
                            if (image == null) return const SizedBox.shrink();

                            return _ImageListItem(
                              image: image,
                              height: paletteListItemHeight,
                            );
                          },
                          error: (err, stack) => ErrorWidget(err),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                        );
                      }),
                      const SizedBox(height: headingPadding),
                      Text('Generated Palette', style: header2TextStyle),
                      const SizedBox(height: headingPadding),
                      Consumer(builder: (context, ref, child) {
                        final selectedIndex =
                            ref.watch(selectedPaletteIndexProvider);

                        final asyncImage = ref.watch(
                            defaultPaletteImageProvider(
                                PaletteImageType.display));
                        return asyncImage.when(
                          data: (image) {
                            if (image == null) return const SizedBox.shrink();

                            return _ImageListItem(
                              image: image,
                              height: paletteListItemHeight,
                              isSelected: selectedIndex < 0,
                              onTap: () {
                                ref
                                    .read(selectedPaletteIndexProvider.notifier)
                                    .setValue(-1);
                              },
                            );
                          },
                          error: (err, stack) => ErrorWidget(err),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                        );
                      }),
                      const SizedBox(height: sectionPadding),
                      Text('Other Palettes', style: headerTextStyle),
                      const SizedBox(height: headingPadding),
                      LoadImagesButtons(
                          loadedImagesProvider(ImageCollectionType.palette)),
                      const SizedBox(height: headingPadding),
                      _ListHeading(
                          loadedImagesProvider(ImageCollectionType.palette)),
                      const SizedBox(height: headingPadding),
                      _ImageListView(
                        imageProvider:
                            displayImagesProvider(ImageCollectionType.palette),
                        itemHeight: paletteListItemHeight,
                        selectedProvider: selectedPaletteIndexProvider,
                      ),
                      const SizedBox(height: sectionPadding),
                      Text('Preview', style: headerTextStyle),
                      Expanded(
                        child: Consumer(builder: (context, ref, child) {
                          final asyncImage = ref.watch(previewImageProvider);
                          return asyncImage.when(
                            data: (image) {
                              if (image == null) return const SizedBox.shrink();

                              return _ImageListItem(
                                image: image,
                              );
                            },
                            error: (err, stack) => ErrorWidget(err),
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: columnPadding),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Output Files', style: headerTextStyle),
                      const SizedBox(height: headingPadding),
                      Consumer(builder: (context, ref, child) {
                        final asyncPalette = ref.watch(
                            defaultPaletteImageProvider(PaletteImageType.full));
                        return ElevatedButton.icon(
                          // Palette save button only work when there is a palette to save
                          onPressed: asyncPalette.when(
                            data: (paletteImage) {
                              if (paletteImage == null) return null;
                              return () =>
                                  _saveGeneratedPalette(paletteImage, ref);
                            },
                            error: (err, stack) => null,
                            loading: () => null,
                          ),
                          icon: const Icon(Icons.save),
                          label: const Text('Save Generated Palette'),
                        );
                      }),
                      const SizedBox(height: headingPadding),
                      Consumer(builder: (context, ref, child) {
                        final asyncSprites = ref.watch(outputImagesProvider(
                            ImageCollectionType.outputSave));
                        return ElevatedButton.icon(
                          onPressed: asyncSprites.when(
                            data: (images) {
                              return () => _saveSpritesToFolder(images, ref);
                            },
                            error: (err, stack) => null,
                            loading: () => null,
                          ),
                          icon: const Icon(Icons.save),
                          label: const Text('Save Sprites To Folder'),
                        );
                      }),
                      const SizedBox(height: headingPadding),
                      Expanded(
                        child: SizedBox(
                          width: fileListWidth,
                          child: _ImageListView(
                            imageProvider: outputImagesProvider(
                                ImageCollectionType.outputPreview),
                            itemHeight: fileListItemHeight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGeneratedPalette(
      LoadedImage paletteImage, WidgetRef ref) async {
    final initialDir = ref.read(previousFolderProvider);

    // Add file extension to file name if not there
    final fileName = paletteImage.fileName.endsWith('.png')
        ? paletteImage.fileName
        : '${paletteImage.fileName}.png';

    final result = await FilePicker.platform.saveFile(
      initialDirectory: initialDir,
      type: FileType.custom,
      allowedExtensions: ['png'],
      fileName: fileName,
    );
    if (result == null) return;

    // Save folder location to open at next time
    ref.read(previousFolderProvider.notifier).setValue(result);

    // Write image bytes to chosen file location
    await File(result).writeAsBytes(paletteImage.bytes);
  }

  Future<void> _saveSpritesToFolder(
      List<LoadedImage> outputImages, WidgetRef ref) async {
    final initialDir = ref.read(previousFolderProvider);

    final result = await FilePicker.platform
        .getDirectoryPath(initialDirectory: initialDir);
    if (result == null) return;

    // Save folder location to open at next time
    ref.read(previousFolderProvider.notifier).setValue(result);

    List<Future<File>> waitFor = [];
    for (final outputImage in outputImages) {
      // Write image bytes to chosen file location
      final path = '$result/${outputImage.fileName}';
      waitFor.add(File(path).writeAsBytes(outputImage.bytes));
    }

    // Wait for all write operations at once after starting them
    await Future.wait(waitFor);
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

    return Wrap(
      children: [
        Text(
          '${list.length} files loaded',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: list.isNotEmpty
              ? () {
                  ref.read(listProvider.notifier).clear();
                }
              : null,
          icon: const Icon(Icons.clear_all),
          label: const Text('Clear All'),
        ),
      ],
    );
  }
}

class _ImageListView extends ConsumerWidget {
  final FutureProvider<List<LoadedImage>> imageProvider;
  final StateNotifierProvider<IntNotifier, int>? selectedProvider;
  final double? itemHeight;

  const _ImageListView({
    Key? key,
    required this.imageProvider,
    this.selectedProvider,
    this.itemHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const scrollBarPadding = 12.0;

    final selProv = selectedProvider;
    final selectedIndex = selProv != null ? ref.watch(selProv) : -1;

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
          return _ImageListItem(
            image: image,
            height: itemHeight,
            isSelected: selectedIndex == index,
            onTap: selProv != null
                ? () {
                    ref.read(selProv.notifier).setValue(index);
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _ImageListItem extends StatelessWidget {
  final LoadedImage image;
  final double? height;
  final bool isSelected;
  final void Function()? onTap;

  const _ImageListItem({
    Key? key,
    required this.image,
    this.height,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double? elevation;
    if (isSelected) {
      elevation = 5;
    } else if (onTap != null) {
      elevation = 1;
    } else {
      elevation = 0.5;
    }

    return SizedBox(
      height: height,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: elevation,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Text(image.fileName)),
              Expanded(
                  child: Image.memory(
                image.bytes,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
