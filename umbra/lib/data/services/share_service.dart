import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

enum ShareOutcome { shared, dismissed, copied }

/// Hands a text file to the system share sheet; falls back to the clipboard
/// where sharing files isn't supported.
class ShareService {
  const ShareService();

  Future<ShareOutcome> shareFile({required String name, required String mimeType, required String text, Rect? origin}) async {
    try {
      final res = await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(Uint8List.fromList(utf8.encode(text)), mimeType: mimeType, name: name)],
        fileNameOverrides: [name],
        subject: 'Umbra memory export',
        sharePositionOrigin: origin,
      ));
      if (res.status == ShareResultStatus.unavailable) throw StateError('share unavailable');
      return res.status == ShareResultStatus.success ? ShareOutcome.shared : ShareOutcome.dismissed;
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      return ShareOutcome.copied;
    }
  }
}
