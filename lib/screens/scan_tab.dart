import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../theme/milion_theme.dart';

import 'package:image_picker/image_picker.dart';

import '../services/classifier.dart';
import '../widgets/scene_detail_sheet.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({
    super.key,
    required this.classifier,
    this.onExploreAnastasis,
    this.onExploreLastJudgment,
  });

  final Classifier classifier;
  final VoidCallback? onExploreAnastasis;
  final VoidCallback? onExploreLastJudgment;

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> with WidgetsBindingObserver {
  static const double _showThreshold = 0.30;
  static const double _hideThreshold = 0.20;
  static const int _requiredFrames = 3;
  static const double _smoothing = 0.4;

  CameraController? _controller;
  bool _processing = false;
  bool _live = true;
  bool _torchOn = false;
  bool _frameBusy = false;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  SceneMatch? _liveMatch;
  List<double>? _smoothed;
  String? _candidateId;
  int _candidateFrames = 0;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera found on this device.');
        return;
      }
      final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraError = null;
      });
      _resetLive();
      if (_live) {
        try {
          await controller.startImageStream(_onFrame);
        } catch (error) {
          if (mounted) {
            setState(() => _live = false);
            _showMessage(
              'Live recognition is not available on this device: $error',
            );
          }
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _cameraError = '$error');
      }
    }
  }

  void _onFrame(CameraImage image) {
    if (!_live || _frameBusy || _processing) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastFrameAt).inMilliseconds < 500) {
      return;
    }
    _lastFrameAt = now;
    _frameBusy = true;
    final orientation = _controller?.description.sensorOrientation ?? 90;
    widget.classifier
        .classifyCameraImage(image, orientation)
        .then((prediction) {
          if (!mounted || prediction == null) {
            return;
          }
          _applyPrediction(prediction);
        })
        .catchError((Object _) {
          // Skip frames that cannot be processed; the next frame will retry.
        })
        .whenComplete(() => _frameBusy = false);
  }

  void _applyPrediction(LivePrediction prediction) {
    final probabilities = prediction.probabilities;
    var smoothed = _smoothed;
    if (smoothed == null || smoothed.length != probabilities.length) {
      smoothed = List<double>.from(probabilities);
    } else {
      for (var i = 0; i < probabilities.length; i++) {
        smoothed[i] =
            smoothed[i] * (1 - _smoothing) + probabilities[i] * _smoothing;
      }
    }
    _smoothed = smoothed;

    var bestIndex = 0;
    for (var i = 1; i < smoothed.length; i++) {
      if (smoothed[i] > smoothed[bestIndex]) {
        bestIndex = i;
      }
    }
    final bestProbability = smoothed[bestIndex];
    final bestId = widget.classifier.sceneAtPrediction(bestIndex).id;

    if (bestProbability < _hideThreshold) {
      _candidateId = null;
      _candidateFrames = 0;
      if (_liveMatch != null) {
        setState(() => _liveMatch = null);
      }
      return;
    }

    if (bestId == _candidateId) {
      _candidateFrames++;
    } else {
      _candidateId = bestId;
      _candidateFrames = 1;
    }

    final alreadyShown = _liveMatch?.scene.id == bestId;
    final confirmed =
        _candidateFrames >= _requiredFrames &&
        bestProbability >= _showThreshold;
    if (confirmed || alreadyShown) {
      final match = SceneMatch(
        widget.classifier.sceneAtPrediction(bestIndex),
        bestProbability,
      );
      setState(() => _liveMatch = match);
    }
  }

  void _resetLive() {
    _smoothed = null;
    _candidateId = null;
    _candidateFrames = 0;
    _liveMatch = null;
  }

  Future<void> _toggleLive() async {
    final next = !_live;
    setState(() {
      _live = next;
      if (!next) {
        _resetLive();
      }
    });
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    try {
      if (next) {
        await controller.startImageStream(_onFrame);
      } else if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (error) {
      _showMessage('Could not switch live recognition: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pauseStream() async {
    final controller = _controller;
    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
  }

  Future<void> _resumeStream() async {
    final controller = _controller;
    if (_live &&
        controller != null &&
        controller.value.isInitialized &&
        !controller.value.isStreamingImages) {
      try {
        await controller.startImageStream(_onFrame);
      } catch (error) {
        if (mounted) {
          setState(() => _live = false);
          _showMessage('Live recognition is not available here: $error');
        }
      }
    }
  }

  Future<void> _scan() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _processing) {
      return;
    }
    setState(() => _processing = true);
    await _pauseStream();
    try {
      final shot = await controller.takePicture();
      await _classifyFile(shot);
    } catch (error) {
      _showMessage('Could not capture the photo: $error');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
      await _resumeStream();
    }
  }

  Future<void> _pickFromGallery() async {
    if (_processing) {
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked == null) {
      return;
    }
    setState(() => _processing = true);
    await _pauseStream();
    try {
      await _classifyFile(picked);
    } catch (error) {
      _showMessage('Could not read that image: $error');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
      await _resumeStream();
    }
  }

  Future<void> _classifyFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final matches = await widget.classifier.classifyBytes(bytes);
    if (!mounted) {
      return;
    }
    final selected = await showModalBottomSheet<SceneMatch>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ResultsSheet(matches: matches, image: bytes),
    );
    if (selected != null && mounted) {
      await _openScene(selected);
    }
  }

  Future<void> _openScene(SceneMatch match) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SceneDetailSheet(
        scene: match.scene,
        confidence: match.probability,
        onExamine: switch (match.scene.id) {
          'F02' => widget.onExploreAnastasis,
          'F05' => widget.onExploreLastJudgment,
          _ => null,
        },
      ),
    );
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    final next = !_torchOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _torchOn = next);
    } catch (error) {
      _showMessage('Could not switch the light: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan a scene'),
        actions: [
          IconButton(
            tooltip: _live ? 'Live recognition on' : 'Live recognition off',
            onPressed: _toggleLive,
            icon: Icon(
              _live ? Icons.motion_photos_on : Icons.motion_photos_off,
            ),
          ),
          IconButton(
            tooltip: 'Pick from gallery',
            onPressed: _processing ? null : _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            _CameraPreview(controller: controller)
          else
            _CameraPlaceholder(error: _cameraError, onRetry: _initCamera),
          const _GuideFrame(),
          Positioned(
            left: 16,
            right: 16,
            bottom: 168,
            child: _LivePill(
              live: _live,
              match: _liveMatch,
              onTap: _liveMatch == null ? null : () => _openScene(_liveMatch!),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onPressed: _processing ? null : _pickFromGallery,
                  ),
                  _ScanButton(onPressed: _processing ? null : _scan),
                  _RoundButton(
                    icon: _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                    label: 'Light',
                    onPressed: (_processing || controller == null)
                        ? null
                        : _toggleTorch,
                  ),
                ],
              ),
            ),
          ),
          if (_processing) const _ProcessingOverlay(),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({
    required this.live,
    required this.match,
    required this.onTap,
  });

  final bool live;
  final SceneMatch? match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget content;
    if (!live) {
      content = Row(
        children: [
          Icon(
            Icons.motion_photos_off,
            size: 16,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'Live recognition off',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      );
    } else if (match == null) {
      content = Row(
        children: [
          Icon(
            Icons.search_off,
            size: 16,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'No scene detected · keep looking',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      );
    } else {
      final confidence = match!.probability;
      final dotColor = confidence >= 0.65
          ? const Color(0xFF66BB6A)
          : confidence >= 0.35
          ? const Color(0xFFFFB74D)
          : const Color(0xFFBDBDBD);
      content = Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${match!.scene.id} · ${match!.scene.prettyTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(confidence * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      );
    }

    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: content,
        ),
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size?.height ?? 1080,
          height: size?.width ?? 1920,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF101820),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 56,
                color: Colors.white70,
              ),
              const SizedBox(height: 16),
              Text(
                error ?? 'Starting the camera...',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideFrame extends StatelessWidget {
  const _GuideFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spacer(),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Point the camera at a mosaic or fresco',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: onPressed == null ? Colors.white38 : MilionTheme.lightGold,
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const SizedBox(
              width: 78,
              height: 78,
              child: Icon(Icons.camera_alt, size: 34, color: MilionTheme.ink),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Scan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white24,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x99000000),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: MilionTheme.lightGold),
            SizedBox(height: 16),
            Text(
              'Analysing the scene...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsSheet extends StatelessWidget {
  const _ResultsSheet({required this.matches, required this.image});

  final List<SceneMatch> matches;
  final Uint8List image;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      image,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top match',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${matches.first.scene.id} · ${matches.first.scene.prettyTitle}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap a result for details and notes',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (final match in matches)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.of(context).pop(match),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _MatchBar(match: match, scheme: scheme),
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo result. The model ranks possibilities only; it does not '
                        'verify the scene. Always confirm against the mosaic itself.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchBar extends StatelessWidget {
  const _MatchBar({required this.match, required this.scheme});

  final SceneMatch match;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final probability = match.probability;
    final color = probability >= 0.65
        ? const Color(0xFF2E7D32)
        : probability >= 0.35
        ? const Color(0xFFB26A00)
        : const Color(0xFF9E9E9E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${match.scene.id} · ${match.scene.prettyTitle}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text('${(probability * 100).toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: probability.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: const Color(0xFFEDEDED),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${match.scene.room} · ${match.scene.surface}',
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
