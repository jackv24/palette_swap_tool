import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_swap_tool/utils/update.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateIcon extends ConsumerWidget {
  final Color? color;

  const UpdateIcon({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateVersion = ref.watch(updateAvailableProvider).value;

    // Hide if no update available
    if (updateVersion == null) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: 'Update Available! v$buildName => v$updateVersion',
      child: IconButton(
        icon: const Icon(Icons.download),
        color: color,
        onPressed: () async {
          await launchUrl(Uri.parse(releasesPageUrl));
        },
      ),
    );
  }
}
