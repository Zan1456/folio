import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:folio/api/client.dart';
import 'package:folio/models/release.dart';
import 'package:folio/theme/colors/colors.dart';

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.release});

  final Release release;

  static void show(BuildContext context, Release release) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      useRootNavigator: true,
      builder: (_) => UpdateDialog(release: release),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

enum _DownloadState { idle, downloading, installing, error }

class _UpdateDialogState extends State<UpdateDialog> {
  _DownloadState _state = _DownloadState.idle;
  double _progress = 0.0;
  String? _errorMessage;

  ReleaseDownload? get _apkAsset {
    try {
      return widget.release.downloads.firstWhere(
        (d) => d.url.toLowerCase().endsWith('.apk'),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _downloadAndInstall() async {
    final asset = _apkAsset;
    if (asset == null) {
      setState(() {
        _state = _DownloadState.error;
        _errorMessage = 'Nem található letölthető APK a kiadásban.';
      });
      return;
    }

    setState(() {
      _state = _DownloadState.downloading;
      _progress = 0.0;
    });

    try {
      final response = await FilcAPI.downloadRelease(asset);
      if (response == null) throw Exception('Letöltés sikertelen.');

      final total = asset.size > 0 ? asset.size : response.contentLength ?? 0;
      int received = 0;
      final chunks = <Uint8List>[];

      await for (final chunk in response.stream) {
        chunks.add(Uint8List.fromList(chunk));
        received += chunk.length;
        if (total > 0) {
          setState(() => _progress = received / total);
        }
      }

      // Write to temp file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/folio_update_${widget.release.tag}.apk');
      final sink = file.openWrite();
      for (final chunk in chunks) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();

      if (!mounted) return;
      setState(() => _state = _DownloadState.installing);

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        setState(() {
          _state = _DownloadState.error;
          _errorMessage = 'Telepítés sikertelen: ${result.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _DownloadState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasApk = _apkAsset != null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.fromLTRB(
          20.0, 16.0, 20.0, MediaQuery.of(context).padding.bottom + 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                color: AppColors.of(context).text.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),

          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Icon(Icons.system_update_rounded,
                    size: 22.0, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Új verzió elérhető',
                      style: tt.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                    Text(
                      widget.release.tag,
                      style: tt.bodySmall!.copyWith(
                          color: cs.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          // Release notes
          if (widget.release.body.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 200.0),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: widget.release.body.trim(),
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                    p: tt.bodySmall!
                        .copyWith(color: cs.onSurface.withValues(alpha: 0.8)),
                    h1: tt.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface),
                    h2: tt.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                    h3: tt.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                    code: tt.bodySmall!.copyWith(
                        fontFamily: 'monospace',
                        color: cs.primary),
                    codeblockDecoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14.0),
          ],

          // Error message
          if (_state == _DownloadState.error && _errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                _errorMessage!,
                style:
                    tt.bodySmall!.copyWith(color: cs.onErrorContainer),
              ),
            ),
            const SizedBox(height: 12.0),
          ],

          // Progress bar
          if (_state == _DownloadState.downloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8.0,
                backgroundColor: cs.surfaceContainerHigh,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _progress > 0
                  ? 'Letöltés: ${(_progress * 100).toStringAsFixed(0)}%'
                  : 'Letöltés...',
              style: tt.bodySmall!
                  .copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 14.0),
          ],

          if (_state == _DownloadState.installing) ...[
            Row(
              children: [
                SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.0, color: cs.primary),
                ),
                const SizedBox(width: 10.0),
                Text('Telepítő megnyitása...',
                    style: tt.bodySmall!
                        .copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
              ],
            ),
            const SizedBox(height: 14.0),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _state == _DownloadState.downloading
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0)),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    side: BorderSide(
                        color: cs.outline.withValues(alpha: 0.4)),
                  ),
                  child: const Text('Később',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: (!hasApk ||
                          _state == _DownloadState.downloading ||
                          _state == _DownloadState.installing)
                      ? null
                      : _downloadAndInstall,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0)),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  icon: Icon(
                    _state == _DownloadState.error
                        ? Icons.refresh_rounded
                        : Icons.download_rounded,
                    size: 18.0,
                  ),
                  label: Text(
                    !hasApk
                        ? 'Nincs APK'
                        : _state == _DownloadState.error
                            ? 'Újra'
                            : 'Letöltés és telepítés',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
