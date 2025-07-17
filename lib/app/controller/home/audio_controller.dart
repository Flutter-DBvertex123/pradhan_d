import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
//created by dbVertex
class AudioController extends GetxController{
  final RxBool isMuted=true.obs;
  final List<AudioPlayer>_audioPlayers=[];
  final List<VideoPlayerController> _videoControllers = [];


  void registerAudioPlayer(AudioPlayer player) {
    if (!_audioPlayers.contains(player)) {
      _audioPlayers.add(player);
      player.setVolume(getVolume());
    }
  }
  void registerVideoController(VideoPlayerController controller) {
    if (!_videoControllers.contains(controller)) {
      _videoControllers.add(controller);
      controller.setVolume(getVolume());
    }
  }

  void unregisterAudioPlayer(AudioPlayer player) {
    _audioPlayers.remove(player);
  }

  void unregisterVideoController(VideoPlayerController controller) {
    _videoControllers.remove(controller);
  }
  void toggleMute() {
    isMuted.value = !isMuted.value;
    final volume = getVolume();
    for (var player in _audioPlayers) {
      player.setVolume(volume);
    }
    for (var controller in _videoControllers) {
      controller.setVolume(volume);
    }
  }
  double getVolume() => isMuted.value?0.0:1.0;

  void muteAll() {
    for (var player in _audioPlayers) {
      player.setVolume(0.0);
    }
    for (var controller in _videoControllers) {
      controller.setVolume(0.0);
    }
  }
  void restoreVolume() {
    final volume = getVolume();
    for (var player in _audioPlayers) {
      player.setVolume(volume);
    }
    for (var controller in _videoControllers) {
      controller.setVolume(volume);
    }
  }
}