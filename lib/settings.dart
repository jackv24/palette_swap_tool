import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const themeModeAdapterTypeId = 0;

final _settingsBoxProvider = FutureProvider<Box>((ref) async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(themeModeAdapterTypeId)) {
    Hive.registerAdapter(_ThemeModeAdapter());
  }

  final box = await Hive.openBox('settings');

  ref.onDispose(() {
    box.close();
  });

  return box;
});

final themeModeProvider =
    StateNotifierProvider<HiveSettingNotifier<ThemeMode>, ThemeMode>((ref) {
  final box = ref.watch(_settingsBoxProvider);
  return HiveSettingNotifier(box.value, 'themeMode', ThemeMode.system);
});

final previousFolderProvider =
    StateNotifierProvider<HiveSettingNotifier<String>, String>((ref) {
  final box = ref.watch(_settingsBoxProvider);
  return HiveSettingNotifier(box.value, 'previousFolderPath', '');
});

class HiveSettingNotifier<T> extends StateNotifier<T> {
  final Box? box;
  final String key;

  HiveSettingNotifier(this.box, this.key, T defaultValue)
      : super(defaultValue) {
    final b = box;
    if (b == null) return;
    state = b.get(key, defaultValue: defaultValue);
  }

  void setValue(T value) async {
    final b = box;
    if (b == null) return;
    b.put(key, value);
    state = value;
  }
}

class _ThemeModeAdapter extends TypeAdapter<ThemeMode> {
  @override
  final typeId = themeModeAdapterTypeId;

  @override
  ThemeMode read(BinaryReader reader) {
    return ThemeMode.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ThemeMode obj) {
    writer.writeByte(obj.index);
  }
}
