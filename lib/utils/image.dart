import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image_util;

final loadedImagesProvider =
    StateNotifierProvider<LoadedImagesNotifier, List<LoadedImage>>((ref) {
  return LoadedImagesNotifier([]);
});

final trimmedImagesProvider = FutureProvider<List<LoadedImage>>((ref) async {
  final images = ref.watch(loadedImagesProvider);
  return await _processLoadedImages(images,
      trimMode: image_util.TrimMode.transparent);
});

final loadedPalettesProvider =
    StateNotifierProvider<LoadedImagesNotifier, List<LoadedImage>>((ref) {
  return LoadedImagesNotifier([]);
});

final trimmedPalettesProvider = FutureProvider<List<LoadedImage>>((ref) async {
  final images = ref.watch(loadedPalettesProvider);
  return await _processLoadedImages(images,
      trimMode: image_util.TrimMode.bottomRightColor);
});

final outputImagesProvider = FutureProvider<List<LoadedImage>>((ref) async {
  // TODO
  return [];
});

Future<List<LoadedImage>> _processLoadedImages(List<LoadedImage> images,
    {image_util.TrimMode? trimMode}) async {
  final processedImages = await Future.wait(images.map((loadedImage) async {
    final bytes =
        await _processLoadedImage(loadedImage.bytes, trimMode: trimMode);
    if (bytes == null) return null;
    return LoadedImage(
      fileName: loadedImage.fileName,
      bytes: bytes,
    );
  }));

  final successfulImages = processedImages.whereType<LoadedImage>();
  return successfulImages.toList();
}

Future<Uint8List?> _processLoadedImage(Uint8List bytes,
    {image_util.TrimMode? trimMode}) async {
  // Decode image off the main thread
  var image = await compute(image_util.decodeImage, bytes);

  // Trim image if desired
  if (image != null && trimMode != null) {
    image = image_util.trim(image, mode: trimMode);
  }

  if (image == null) return null;

  return Uint8List.fromList(image_util.encodePng(image));
}

class LoadedImage {
  final String fileName;
  final Uint8List bytes;

  const LoadedImage({
    required this.fileName,
    required this.bytes,
  });
}

class LoadedImagesNotifier extends StateNotifier<List<LoadedImage>> {
  LoadedImagesNotifier(super.state);

  void update(List<LoadedImage> images) {
    state = images;
  }

  void clear() {
    state = [];
  }
}
