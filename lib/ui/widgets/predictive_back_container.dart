import 'package:flutter/material.dart';

/// Container implementing AOSP-style predictive back gesture and overlay slide transition
/// ported from NCM-Converter-For-Android's PredictiveBackContainer.kt:
/// - Overlay scales down (1.00 -> 0.90) with dynamic rounded corners (0 -> 28dp) and shadow (0 -> 12dp)
///   during interactive edge-swipe back gesture.
/// - Underlying background page reveals beneath with parallax scale (0.94 -> 1.00) and fading scrim.
/// - Smooth slide-in (280ms) and slide-out (240ms) when opening or tapping back button.
class PredictiveBackContainer extends StatefulWidget {
  final bool isOverlayOpen;
  final VoidCallback onCloseOverlay;
  final Widget backgroundContent;
  final Widget Function(VoidCallback requestClose) overlayContent;

  const PredictiveBackContainer({
    super.key,
    required this.isOverlayOpen,
    required this.onCloseOverlay,
    required this.backgroundContent,
    required this.overlayContent,
  });

  @override
  State<PredictiveBackContainer> createState() => _PredictiveBackContainerState();
}

class _PredictiveBackContainerState extends State<PredictiveBackContainer>
    with TickerProviderStateMixin {
  // 0.0 = settled on-screen, 1.0 = offscreen to the right
  late final AnimationController _slideController;
  late final AnimationController _gestureAnimController;

  bool _internalOverlayOpen = false;
  bool _isPredicting = false;
  double _predictiveProgress = 0.0;
  bool _swipeFromLeft = true;
  double _commitExitFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _internalOverlayOpen = widget.isOverlayOpen;
    _slideController = AnimationController(
      vsync: this,
      value: widget.isOverlayOpen ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _gestureAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void didUpdateWidget(covariant PredictiveBackContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOverlayOpen && !oldWidget.isOverlayOpen) {
      _gestureAnimController.stop();
      setState(() {
        _internalOverlayOpen = true;
        _isPredicting = false;
        _predictiveProgress = 0.0;
        _commitExitFraction = 0.0;
      });
      _slideController.value = 1.0;
      _slideController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.fastOutSlowIn,
      );
    } else if (!widget.isOverlayOpen && oldWidget.isOverlayOpen) {
      if (_commitExitFraction == 0.0 && _slideController.value == 0.0) {
        _requestClose();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _gestureAnimController.dispose();
    super.dispose();
  }

  void _requestClose() {
    if (!_internalOverlayOpen || _isPredicting || _commitExitFraction > 0.0) return;
    _gestureAnimController.stop();
    _slideController
        .animateTo(
      1.0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.fastOutSlowIn,
    )
        .whenComplete(() {
      if (!mounted) return;
      widget.onCloseOverlay();
      setState(() {
        _internalOverlayOpen = false;
        _predictiveProgress = 0.0;
        _commitExitFraction = 0.0;
      });
    });
  }

  void _onEdgeDragStart(DragStartDetails details, double screenWidth) {
    if (!_internalOverlayOpen || _slideController.value != 0.0) return;
    final dx = details.globalPosition.dx;
    if (dx <= 28.0) {
      _swipeFromLeft = true;
    } else if (dx >= screenWidth - 28.0) {
      _swipeFromLeft = false;
    } else {
      return;
    }
    _gestureAnimController.stop();
    setState(() {
      _isPredicting = true;
      _predictiveProgress = 0.0;
      _commitExitFraction = 0.0;
    });
  }

  void _onEdgeDragUpdate(DragUpdateDetails details, double screenWidth) {
    if (!_isPredicting) return;
    final delta = _swipeFromLeft ? details.delta.dx : -details.delta.dx;
    final next = (_predictiveProgress + delta / (screenWidth * 0.65)).clamp(0.0, 1.0);
    setState(() {
      _predictiveProgress = next;
    });
  }

  void _onEdgeDragEnd(DragEndDetails details) {
    if (!_isPredicting) return;
    final velocity = _swipeFromLeft
        ? (details.primaryVelocity ?? 0.0)
        : -(details.primaryVelocity ?? 0.0);
    final shouldCommit = _predictiveProgress > 0.28 || velocity > 450.0;

    if (shouldCommit) {
      _gestureAnimController.reset();
      void listener() {
        if (!mounted) return;
        setState(() {
          _commitExitFraction = Curves.fastOutSlowIn.transform(_gestureAnimController.value);
        });
      }

      _gestureAnimController.addListener(listener);
      _gestureAnimController
          .animateTo(1.0, duration: const Duration(milliseconds: 180))
          .whenComplete(() {
        _gestureAnimController.removeListener(listener);
        if (!mounted) return;
        widget.onCloseOverlay();
        setState(() {
          _internalOverlayOpen = false;
          _isPredicting = false;
          _predictiveProgress = 0.0;
          _commitExitFraction = 0.0;
        });
      });
    } else {
      final startProgress = _predictiveProgress;
      _gestureAnimController.reset();
      void listener() {
        if (!mounted) return;
        final t = Curves.fastOutSlowIn.transform(_gestureAnimController.value);
        setState(() {
          _predictiveProgress = (startProgress * (1.0 - t)).clamp(0.0, 1.0);
        });
      }

      _gestureAnimController.addListener(listener);
      _gestureAnimController
          .animateTo(1.0, duration: const Duration(milliseconds: 180))
          .whenComplete(() {
        _gestureAnimController.removeListener(listener);
        if (!mounted) return;
        setState(() {
          _predictiveProgress = 0.0;
          _isPredicting = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_internalOverlayOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _internalOverlayOpen) {
          _requestClose();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth > 0
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;

          return AnimatedBuilder(
            animation: _slideController,
            builder: (context, _) {
              final isGestureMode = _isPredicting || _commitExitFraction > 0.0;
              final eased = Curves.fastOutSlowIn.transform(_predictiveProgress.clamp(0.0, 1.0));
              final exitFraction = _commitExitFraction.clamp(0.0, 1.0);

              final double currentScale;
              final double currentTranslationX;
              final double currentAlpha;
              final double currentCornerRadius;
              final double currentElevation;
              final double bgScale;
              final double currentScrimAlpha;

              if (isGestureMode) {
                currentScale = ((1.0 - 0.10 * eased) * (1.0 - 0.08 * exitFraction)).clamp(0.80, 1.0);
                currentCornerRadius = (28.0 * eased).clamp(0.0, 28.0);
                currentElevation = (12.0 * eased).clamp(0.0, 12.0);

                final edgeMultiplier = _swipeFromLeft ? 1.0 : -1.0;
                final dragOffset = edgeMultiplier * 36.0 * eased;
                final commitOffset = (_swipeFromLeft ? screenWidth : -screenWidth) * exitFraction;
                currentTranslationX = dragOffset + commitOffset;
                currentAlpha = ((1.0 - 0.05 * eased) * (1.0 - exitFraction)).clamp(0.0, 1.0);

                final totalProgress = (eased + (1.0 - eased) * exitFraction).clamp(0.0, 1.0);
                bgScale = (0.94 + 0.06 * totalProgress).clamp(0.90, 1.0);
                currentScrimAlpha = (0.25 * (1.0 - totalProgress)).clamp(0.0, 0.25);
              } else {
                final slideVal = _slideController.value.clamp(0.0, 1.0);
                final openFraction = (1.0 - slideVal).clamp(0.0, 1.0);

                currentScale = 1.0;
                currentCornerRadius = 0.0;
                currentElevation = 0.0;
                currentTranslationX = screenWidth * slideVal;
                currentAlpha = (1.0 - 0.3 * slideVal).clamp(0.0, 1.0);

                bgScale = (1.0 - 0.06 * openFraction).clamp(0.90, 1.0);
                currentScrimAlpha = (0.25 * openFraction).clamp(0.0, 0.25);
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: Background Screen (HomeScreen)
                  Transform.scale(
                    scale: bgScale,
                    child: widget.backgroundContent,
                  ),

                  // Layer 2: Dim Scrim over Background Screen
                  if (_internalOverlayOpen && currentScrimAlpha > 0.0)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: currentScrimAlpha),
                      ),
                    ),

                  // Layer 3: Overlay Screen (SettingsScreen)
                  if (_internalOverlayOpen)
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: (d) => _onEdgeDragStart(d, screenWidth),
                      onHorizontalDragUpdate: (d) => _onEdgeDragUpdate(d, screenWidth),
                      onHorizontalDragEnd: _onEdgeDragEnd,
                      child: Opacity(
                        opacity: currentAlpha,
                        child: Transform.translate(
                          offset: Offset(currentTranslationX, 0),
                          child: Transform.scale(
                            scale: currentScale,
                            child: Material(
                              elevation: currentElevation,
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(currentCornerRadius),
                              clipBehavior:
                                  currentCornerRadius > 0 ? Clip.antiAlias : Clip.none,
                              child: widget.overlayContent(_requestClose),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
