import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final colorSchemeSeedProvider = FutureProvider((ref) async {
  return await DynamicColorPlugin.getAccentColor();
});
