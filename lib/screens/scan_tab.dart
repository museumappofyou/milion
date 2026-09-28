import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';

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
        if (mounted) setState(() => _cameraError = 'noCamera');
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
            _showMessage(context.l10n.liveUnavailable);
          }
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _cameraError = 'cameraError');
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
      if (mounted) _showMessage(context.l10n.liveUnavailable);
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
          if (mounted) _showMessage(context.l10n.liveUnavailable);
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
      if (mounted) _showMessage(context.l10n.scanFailed);
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
      if (mounted) _showMessage(context.l10n.scanFailed);
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
      if (mounted) _showMessage(context.l10n.lightFailed);
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
  Widget build(BuildContext context) => Theme(
    data: DesignTheme.lamp,
    child: Builder(
      builder: (context) {
        final s = context.l10n,
            c = MeasureColors.of(context),
            controller = _controller;
        final cameraReady =
            controller != null && controller.value.isInitialized;
        return Scaffold(
          appBar: AppBar(
            title: Text(s.scanScene),
            actions: [
              IconButton(
                tooltip: _live ? s.liveOn : s.liveOff,
                onPressed: _toggleLive,
                icon: PlanIcon(
                  PlanSymbol.cameraEye,
                  color: _live ? c.ink : c.secondary,
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: cameraReady
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              _CameraPreview(controller: controller),
                              IgnorePointer(
                                child: Center(
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Pigment.marble,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: SingleChildScrollView(
                              child: ContentState(
                                error: _cameraError != null,
                                title: _cameraError == null
                                    ? s.startCamera
                                    : s.cameraError,
                                message: _cameraError == 'noCamera'
                                    ? s.noCamera
                                    : _cameraError != null
                                    ? s.cameraErrorBody
                                    : s.cameraGuide,
                                onAction: _cameraError == null
                                    ? null
                                    : _initCamera,
                              ),
                            ),
                          ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .38,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (cameraReady)
                              InkWell(
                                onTap: _liveMatch == null
                                    ? null
                                    : () => _openScene(_liveMatch!),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    !_live
                                        ? s.liveOff
                                        : _liveMatch == null
                                        ? s.noSceneDetected
                                        : '${_liveMatch!.scene.id} · ${_liveMatch!.scene.prettyTitle} · ${s.modelMatch((_liveMatch!.probability * 100).round().toString())}',
                                  ),
                                ),
                              ),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _processing
                                      ? null
                                      : _pickFromGallery,
                                  icon: const PlanIcon(PlanSymbol.vitrine),
                                  label: Text(s.gallery),
                                ),
                                FilledButton.icon(
                                  onPressed: _processing || !cameraReady
                                      ? null
                                      : _scan,
                                  icon: const PlanIcon(PlanSymbol.cameraEye),
                                  label: Text(s.scan),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _processing || !cameraReady
                                      ? null
                                      : _toggleTorch,
                                  icon: PlanIcon(
                                    PlanSymbol.light,
                                    color: _torchOn ? c.accent : null,
                                  ),
                                  label: Text(s.light),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_processing)
                Positioned.fill(
                  child: ColoredBox(
                    color: c.ground,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const TesseraLoader(),
                          const SizedBox(height: 16),
                          Text(s.analysingScene),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
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

class _ResultsSheet extends StatelessWidget {
  const _ResultsSheet({required this.matches, required this.image});
  final List<SceneMatch> matches;
  final Uint8List image;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n, c = MeasureColors.of(context);
    return DimensionSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.memory(
            image,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 16),
          Text(s.topMatch, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(s.resultHint),
          for (final match in matches)
            InkWell(
              onTap: () => Navigator.pop(context, match),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${match.scene.id} · ${match.scene.prettyTitle}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.modelMatch(
                        (match.probability * 100).round().toString(),
                      ),
                      style: TypeRole.measurement.copyWith(color: c.secondary),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: match.probability,
                      color: c.accent,
                      backgroundColor: c.poche,
                      minHeight: 2,
                    ),
                  ],
                ),
              ),
            ),
          const Divider(),
          Text(s.demoResult),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const PlanIcon(PlanSymbol.cameraEye),
            label: Text(s.scanAgain),
          ),
        ],
      ),
    );
  }
}
