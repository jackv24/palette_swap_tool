import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image/image.dart' as image_util;

part 'image.freezed.dart';

final loadedImagesProvider = StateNotifierProvider.family<LoadedImagesNotifier,
    List<LoadedImage>, ImageCollectionType>((ref, collectionType) {
  return LoadedImagesNotifier([]);
});

final decodedImagesProvider =
    FutureProvider.family<List<DecodedImage>, ImageCollectionType>(
        (ref, collectionType) {
  final loadedImages = ref.watch(loadedImagesProvider(collectionType));
  return _decodeLoadedImages(loadedImages);
});

final displayImagesProvider =
    FutureProvider.family<List<LoadedImage>, ImageCollectionType>(
        (ref, collectionType) async {
  final images = await ref.watch(decodedImagesProvider(collectionType).future);
  return images.map((image) {
    final trimMode = collectionType.displayTrimMode;
    final trimmedImage = trimMode == null
        ? image.image
        : image_util.trim(image.image, mode: trimMode);

    return LoadedImage(
        fileName: image.fileName,
        bytes: Uint8List.fromList(image_util.encodePng(trimmedImage)));
  }).toList();
});

enum PaletteImageType { full, display }

final defaultPaletteProvider =
    FutureProvider.family<LoadedImage?, PaletteImageType>((ref, type) async {
  final inputImages =
      await ref.watch(decodedImagesProvider(ImageCollectionType.input).future);

  if (inputImages.isEmpty) return null;

  // Extract all unique pixels from all loaded images
  List<int> uniquePixels = [];
  for (final inputImage in inputImages) {
    for (final pixel in inputImage.image.data) {
      // Discard alpha of pixel
      final red = image_util.getChannel(pixel, image_util.Channel.red);
      final green = image_util.getChannel(pixel, image_util.Channel.green);
      final blue = image_util.getChannel(pixel, image_util.Channel.blue);
      final opaquePixel = image_util.getColor(red, green, blue);

      // Only add pixel to list if the same colour isn't already there
      if (uniquePixels.contains(opaquePixel)) continue;
      uniquePixels.add(opaquePixel);
    }
  }

  // Create colour palette image (256 pixels wide because colours are 0-255)
  const width = 256;
  final writeImage =
      image_util.Image(width, 1, channels: image_util.Channels.rgb);

  // Write palette colours into image
  for (int i = 0; i < uniquePixels.length.clamp(0, width); i++) {
    writeImage.setPixel(i, 0, uniquePixels[i]);
  }

  // Process palette image as desired
  final image_util.Image displayImage;
  switch (type) {
    case PaletteImageType.full:
      displayImage = writeImage;
      break;
    case PaletteImageType.display:
      displayImage = image_util.trim(writeImage,
          mode: image_util.TrimMode.bottomRightColor);
      break;
  }

  final bytes = Uint8List.fromList(image_util.encodePng(displayImage));
  return LoadedImage(
    fileName: '[generated]',
    bytes: bytes,
  );
});

final outputImagesProvider = FutureProvider<List<LoadedImage>>((ref) async {
  // TODO
  return [];
});

Future<List<DecodedImage>> _decodeLoadedImages(List<LoadedImage> images) async {
  final processedImages = await Future.wait(images.map((loadedImage) async {
    final image = await compute(image_util.decodeImage, loadedImage.bytes);
    if (image == null) return null;
    return DecodedImage(
      fileName: loadedImage.fileName,
      image: image,
    );
  }));

  final successfulImages = processedImages.whereType<DecodedImage>();
  return successfulImages.toList();
}

enum ImageCollectionType {
  input(displayTrimMode: image_util.TrimMode.transparent),
  palette(displayTrimMode: image_util.TrimMode.bottomRightColor),
  output;

  const ImageCollectionType({this.displayTrimMode});

  final image_util.TrimMode? displayTrimMode;
}

@freezed
class LoadedImage with _$LoadedImage {
  factory LoadedImage({
    required String fileName,
    required Uint8List bytes,
  }) = _LoadedImage;
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

@freezed
class DecodedImage with _$DecodedImage {
  factory DecodedImage({
    required String fileName,
    required image_util.Image image,
  }) = _DecodedImage;
}
