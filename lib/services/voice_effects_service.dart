import 'package:just_audio/just_audio.dart';

enum VoiceEffect {
  none,
  pitchUp,
  pitchDown,
  robot,
  chipmunk,
  deep,
}

/// Voice effect parameters for just_audio playback
class VoiceEffectParams {
  final double pitch;
  final double speed;

  const VoiceEffectParams({required this.pitch, required this.speed});
}

class VoiceEffectsService {
  /// Get playback parameters for a voice effect
  /// These are applied during audio playback using just_audio
  static VoiceEffectParams getPlaybackParams(VoiceEffect effect) {
    switch (effect) {
      case VoiceEffect.none:
        return const VoiceEffectParams(pitch: 1.0, speed: 1.0);
      case VoiceEffect.pitchUp:
        return const VoiceEffectParams(pitch: 1.3, speed: 1.0);
      case VoiceEffect.pitchDown:
        return const VoiceEffectParams(pitch: 0.7, speed: 1.0);
      case VoiceEffect.robot:
        // Robot effect: slight pitch modification
        return const VoiceEffectParams(pitch: 0.85, speed: 1.0);
      case VoiceEffect.chipmunk:
        return const VoiceEffectParams(pitch: 1.8, speed: 1.0);
      case VoiceEffect.deep:
        return const VoiceEffectParams(pitch: 0.5, speed: 1.0);
    }
  }

  /// Apply effect to an AudioPlayer instance
  static Future<void> applyEffectToPlayer(
    AudioPlayer player,
    VoiceEffect effect,
  ) async {
    final params = getPlaybackParams(effect);
    await player.setPitch(params.pitch);
    await player.setSpeed(params.speed);
  }

  /// Get display name for voice effect
  static String getEffectName(VoiceEffect effect) {
    switch (effect) {
      case VoiceEffect.none:
        return 'Normal';
      case VoiceEffect.pitchUp:
        return 'Aigu';
      case VoiceEffect.pitchDown:
        return 'Grave';
      case VoiceEffect.robot:
        return 'Robot';
      case VoiceEffect.chipmunk:
        return 'Chipmunk';
      case VoiceEffect.deep:
        return 'Profond';
    }
  }

  /// Get effect icon
  static String getEffectIcon(VoiceEffect effect) {
    switch (effect) {
      case VoiceEffect.none:
        return 'mic';
      case VoiceEffect.pitchUp:
        return 'arrow_upward';
      case VoiceEffect.pitchDown:
        return 'arrow_downward';
      case VoiceEffect.robot:
        return 'smart_toy';
      case VoiceEffect.chipmunk:
        return 'pets';
      case VoiceEffect.deep:
        return 'graphic_eq';
    }
  }

  /// Convert effect enum to API string
  static String effectToString(VoiceEffect effect) {
    switch (effect) {
      case VoiceEffect.none:
        return 'none';
      case VoiceEffect.pitchUp:
        return 'pitch_up';
      case VoiceEffect.pitchDown:
        return 'pitch_down';
      case VoiceEffect.robot:
        return 'robot';
      case VoiceEffect.chipmunk:
        return 'chipmunk';
      case VoiceEffect.deep:
        return 'deep';
    }
  }

  /// Convert API string to effect enum
  static VoiceEffect stringToEffect(String? effectString) {
    switch (effectString) {
      case 'pitch_up':
        return VoiceEffect.pitchUp;
      case 'pitch_down':
        return VoiceEffect.pitchDown;
      case 'robot':
        return VoiceEffect.robot;
      case 'chipmunk':
        return VoiceEffect.chipmunk;
      case 'deep':
        return VoiceEffect.deep;
      default:
        return VoiceEffect.none;
    }
  }
}
