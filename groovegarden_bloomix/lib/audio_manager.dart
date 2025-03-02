import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AudioManager {
  Future<String> getAudioDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/bloomix_audio');
    if (!await audioDir.exists()) {
      await audioDir.create();
    }
    return audioDir.path;
  }

  Future<String> getNewRecordingPath() async {
    final audioDir = await getAudioDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$audioDir/recording_$timestamp.wav';
  }
}
