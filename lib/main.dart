import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_swap_tool/settings.dart';
import 'package:palette_swap_tool/widgets/theme_mode_button.dart';
import 'package:image/image.dart' as image_loader;

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
  List<_LoadedImage> _loadedImages = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const headingPadding = 8.0;
    const sectionPadding = 32.0;
    const columnPadding = 48.0;

    const fileListWidth = 200.0;

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
                    Consumer(builder: ((context, ref, child) {
                      String? initialDir = ref.watch(previousFolderProvider);

                      // Make null if empty to not set on dialog open
                      if (initialDir != null && initialDir.isEmpty) {
                        initialDir = null;
                      }

                      return Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _pickInputFolder(initialDir, ref),
                            icon: const Icon(Icons.folder_open),
                            label: const Text("Open Folder"),
                          ),
                          TextButton.icon(
                            onPressed: () => _pickInputFiles(initialDir, ref),
                            icon: const Icon(Icons.file_open),
                            label: const Text("Open Files"),
                          ),
                        ],
                      );
                    })),
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
                          padding: const EdgeInsets.only(right: 12.0),
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
                      const SizedBox(height: sectionPadding),
                      Text("Preview", style: theme.textTheme.headlineLarge),
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

  Future<void> _pickInputFolder(String? initialDirectory, WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath(
      initialDirectory: initialDirectory,
    );
    if (result == null) return;

    // Save folder location to open at next time
    ref.read(previousFolderProvider.notifier).setValue(result);

    final filesAsBytes = await Directory(result)
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.png'))
        .asyncMap((entity) async {
      final file = entity as File;
      final bytes = await file.readAsBytes();
      return _LoadedImage(
        fileName: file.uri.pathSegments.last,
        bytes: bytes,
      );
    }).toList();

    await _loadImagesFromBytes(filesAsBytes);
  }

  Future<void> _pickInputFiles(String? initialDirectory, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png'],
      withData: true,
      allowMultiple: true,
      initialDirectory: initialDirectory,
    );
    if (result == null) return;

    // TODO: Get directory
    // if (result.paths.length > 0) {
    //   final path = result.files[0].
    // }

    final filesAsBytes = result.files
        .where((file) => file.bytes != null)
        .map((file) => _LoadedImage(
              fileName: file.name,
              bytes: file.bytes!,
            ))
        .toList();

    await _loadImagesFromBytes(filesAsBytes);
  }

  Future<void> _loadImagesFromBytes(List<_LoadedImage> images) async {
    final processedImages = await Future.wait(images.map((loadedImage) async {
      final bytes = await _processLoadedImage(loadedImage.bytes);
      if (bytes == null) return null;
      return _LoadedImage(
        fileName: loadedImage.fileName,
        bytes: bytes,
      );
    }));

    final successfulImages = processedImages.whereType<_LoadedImage>();

    setState(() {
      _loadedImages = successfulImages.toList();
    });
  }

  Future<Uint8List?> _processLoadedImage(Uint8List bytes) async {
    var receivePort = ReceivePort();

    // Spawn isolate to decode image so we don't stall the UI thread
    await Isolate.spawn(
        _decodeIsolate, _DecodeParam(bytes, receivePort.sendPort));

    // Get the processed image from the isolate.
    var image = await receivePort.first as image_loader.Image?;
    if (image != null) image = image_loader.trim(image);

    if (image == null) return null;

    return Uint8List.fromList(image_loader.encodePng(image));
  }
}

class _LoadedImage {
  final String fileName;
  final Uint8List bytes;

  const _LoadedImage({
    required this.fileName,
    required this.bytes,
  });
}

class _DecodeParam {
  final Uint8List bytes;
  final SendPort sendPort;
  _DecodeParam(this.bytes, this.sendPort);
}

void _decodeIsolate(_DecodeParam param) {
  var image = image_loader.decodeImage(param.bytes);
  param.sendPort.send(image);
}
