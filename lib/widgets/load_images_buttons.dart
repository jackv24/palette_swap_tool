import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_swap_tool/utils/image.dart';
import 'package:palette_swap_tool/utils/settings.dart';

class LoadImagesButtons extends ConsumerWidget {
  final StateNotifierProvider<LoadedImagesNotifier, List<LoadedImage>>
      updateProvider;

  const LoadImagesButtons(this.updateProvider, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialDir = ref.watch(previousFolderProvider);

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
      return LoadedImage(
        fileName: file.uri.pathSegments.last,
        bytes: bytes,
      );
    }).toList();

    await _doLoad(filesAsBytes, ref);
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

    // Save folder location to open at next time (get from file path)
    if (result.paths.isNotEmpty) {
      final filePath = result.files[0].path;
      if (filePath != null) {
        final file = File(filePath);
        final dirPath = file.parent.path;
        ref.read(previousFolderProvider.notifier).setValue(dirPath);
      }
    }

    final filesAsBytes = result.files
        .where((file) => file.bytes != null)
        .map((file) => LoadedImage(
              fileName: file.name,
              bytes: file.bytes!,
            ))
        .toList();

    await _doLoad(filesAsBytes, ref);
  }

  Future<void> _doLoad(List<LoadedImage> images, WidgetRef ref) async {
    ref.read(updateProvider.notifier).update(images);
  }
}
