import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_swap_tool/utils/image.dart';
import 'package:palette_swap_tool/utils/settings.dart';

class LoadImageButton extends ConsumerWidget {
  final StateNotifierProvider<LoadedImageNotifier, LoadedImage?> updateProvider;

  const LoadImageButton(this.updateProvider, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialDir = ref.watch(previousFolderProvider);

    return TextButton.icon(
      onPressed: () => _pickInputFiles(initialDir, ref),
      icon: const Icon(Icons.file_open),
      label: const Text('Open File'),
    );
  }

  Future<void> _pickInputFiles(String? initialDirectory, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png'],
      withData: true,
      allowMultiple: false,
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

    final file = result.files[0];
    if (file.bytes == null) return;

    final image = LoadedImage(
      fileName: file.name,
      bytes: file.bytes!,
    );

    ref.read(updateProvider.notifier).update(image);
  }
}
