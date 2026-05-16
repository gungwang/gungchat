import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../app/providers.dart';
import 'media_call_controller.dart';

class VideoCallOverlay extends ConsumerWidget {
  const VideoCallOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(mediaCallControllerProvider);
    final controller = ref.read(mediaCallControllerProvider.notifier);

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(child: _RemoteStage(call: call)),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.58),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0, 0.42, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CallHeader(call: call),
                  if (call.showLocalPreview)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _LocalPreview(call: call),
                      ),
                    ),
                  const Spacer(),
                  _CallControls(
                    call: call,
                    controller: controller,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallHeader extends StatelessWidget {
  const _CallHeader({required this.call});

  final MediaCallState call;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Video Call',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          call.contact?.displayName ?? 'Unknown contact',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          call.statusText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 15,
          ),
        ),
        if (call.hasDuration) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              call.durationLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RemoteStage extends StatelessWidget {
  const _RemoteStage({required this.call});

  final MediaCallState call;

  @override
  Widget build(BuildContext context) {
    if (call.showRemoteVideo && call.remoteRenderer != null) {
      return RTCVideoView(
        call.remoteRenderer!,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 72,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              call.contact?.displayName ?? 'Waiting for video…',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              call.statusText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalPreview extends StatelessWidget {
  const _LocalPreview({required this.call});

  final MediaCallState call;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * 0.28, 136.0);
    final height = width * 1.45;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.54),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: call.hasLocalVideo && call.localRenderer != null
            ? RTCVideoView(
                call.localRenderer!,
                mirror: call.isFrontCamera,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            : const Center(
                child: Icon(
                  Icons.videocam_off_rounded,
                  color: Colors.white70,
                  size: 34,
                ),
              ),
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.call,
    required this.controller,
  });

  final MediaCallState call;
  final MediaCallController controller;

  @override
  Widget build(BuildContext context) {
    if (call.showIncomingActions) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CallActionButton(
            icon: Icons.call_end_rounded,
            label: 'Decline',
            backgroundColor: const Color(0xFFE34B4B),
            onPressed: () => controller.declineIncomingCall(),
          ),
          const SizedBox(width: 28),
          _CallActionButton(
            icon: Icons.videocam_rounded,
            label: 'Accept',
            backgroundColor: const Color(0xFF2DBD6E),
            onPressed: () => controller.acceptIncomingCall(),
          ),
        ],
      );
    }

    if (call.isTerminal) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CallActionButton(
            icon: Icons.close_rounded,
            label: 'Close',
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            onPressed: () => controller.dismiss(),
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 18,
      children: [
        _CallActionButton(
          icon: call.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: call.isMuted ? 'Unmute' : 'Mute',
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          onPressed: () => controller.toggleMute(),
        ),
        _CallActionButton(
          icon: call.isCameraEnabled
              ? Icons.videocam_rounded
              : Icons.videocam_off_rounded,
          label: call.isCameraEnabled ? 'Camera' : 'Camera off',
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          onPressed: () => controller.toggleCamera(),
        ),
        _CallActionButton(
          icon: Icons.cameraswitch_rounded,
          label: 'Flip',
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          onPressed: () => controller.switchCamera(),
        ),
        _CallActionButton(
          icon: call.isSpeakerOn
              ? Icons.volume_up_rounded
              : Icons.hearing_disabled_rounded,
          label: call.isSpeakerOn ? 'Speaker' : 'Earpiece',
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          onPressed: () => controller.toggleSpeaker(),
        ),
        _CallActionButton(
          icon: Icons.call_end_rounded,
          label: 'Hang up',
          backgroundColor: const Color(0xFFE34B4B),
          onPressed: () => controller.hangUp(),
        ),
      ],
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: backgroundColor,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(
                width: 66,
                height: 66,
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}