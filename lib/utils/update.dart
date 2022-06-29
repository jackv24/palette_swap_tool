import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';

const String buildName = String.fromEnvironment('BUILD_NAME', defaultValue: '');

const releasesPageUrl = 'https://github.com/jackv24/palette_swap_tool/releases';
const _latestReleaseApiUrl =
    'https://api.github.com/repos/jackv24/palette_swap_tool/releases/latest';

final updateAvailableProvider = FutureProvider<String?>((ref) async {
  final response = await http.get(Uri.parse(_latestReleaseApiUrl),
      headers: const {'Accept': 'application/vnd.github.v3+json'});

  final data = jsonDecode(response.body);

  // Get version name from tag
  var tag = data['tag_name'] as String;
  if (tag.startsWith('v')) tag = tag.substring(1);

  final currentVersion = _tryParseVersion(buildName);
  final latestVersion = _tryParseVersion(tag);

  return latestVersion > currentVersion ? tag : null;
});

Version _tryParseVersion(String string) {
  try {
    return Version.parse(string);
  } on FormatException {
    return Version(0, 0, 0);
  }
}
