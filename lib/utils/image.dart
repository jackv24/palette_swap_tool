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
