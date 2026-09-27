import 'package:flutter/material.dart';

import '../models/anastasis_capture.dart';

/// Full-height examination view of one reference capture: pinch-zoom and pan
/// over the prepared image with its provenance underneath.
class CaptureViewerSheet extends StatelessWidget {
  const CaptureViewerSheet({super.key, required this.capture});

  final AnastasisCapture capture;

  static const Map<String, String> _roleLabels = {
    'texture': 'viewer texture',
    'wide': 'wide view',
    'flat-reference': 'flat reference',
    'detail': 'detail',
    'context': 'in situ',
    'historical': 'historical',
    'capture': 'capture',
    'guide': 'guide thumbnail',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        capture.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_roleLabels[capture.role] ?? capture.role} · '
                        '${capture.width}×${capture.height} · from '
                        '${capture.source}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 0.9,
              maxScale: 5,
              child: Center(
                child: Image.asset(capture.file, fit: BoxFit.contain),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capture.caption,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  capture.credit,
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
                if (capture.sourceUrl != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    capture.sourceUrl!,
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
                ],
                if (capture.pipExcluded) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'The capture viewer\u2019s picture-in-picture overlay was '
                    'cropped away when this image was prepared.',
                    style: TextStyle(fontSize: 10.5, color: Colors.white38),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
