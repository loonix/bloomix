import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'audio_manager.dart';
import 'models.dart';
import 'dart:async';

void main() {
  runApp(const BloomixApp());
}

class BloomixApp extends StatelessWidget {
  const BloomixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrooveGarden Bloomix',
      theme: ThemeData(
        primarySwatch: Colors.green, // Garden-inspired base color
      ),
      home: const SessionScreen(),
    );
  }
}

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final AudioManager _audioManager = AudioManager();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  final Session _currentSession = Session('New Session', []);
  String? _currentRecordingPath;
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  Timer? _recordingTimer;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      setState(() {
        _recordState = recordState;
        _isRecording = recordState == RecordState.record;
      });
    });
  }

  @override
  void dispose() {
    _recordSub?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Get a unique file path for the new recording
        final path = await _audioManager.getNewRecordingPath();
        _currentRecordingPath = path;

        // Configure recording options
        final audioConfig = RecordConfig(encoder: AudioEncoder.wav, bitRate: 128000, sampleRate: 44100);

        // Start recording
        await _audioRecorder.start(audioConfig, path: path);

        // Start a timer to track recording duration
        _recordDuration = 0;
        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
          setState(() => _recordDuration++);
        });
      } else {
        // No permission to record audio
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();

    if (path != null) {
      // Add the recording to the session
      _currentSession.tracks.add(Track(path, Duration.zero));

      setState(() {
        _currentRecordingPath = null;
        _recordDuration = 0;
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bloomix Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed:
                _currentSession.tracks.isEmpty
                    ? null
                    : () {
                      // TODO: Implement playback of all tracks
                    },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(16.0), child: Text('Welcome to your music prototyping space!')),

          if (_isRecording)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Recording: ${_formatDuration(_recordDuration)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),

          Expanded(
            child:
                _currentSession.tracks.isEmpty
                    ? const Center(child: Text('No tracks recorded yet. Press the mic button to start.'))
                    : ListView.builder(
                      itemCount: _currentSession.tracks.length,
                      itemBuilder: (context, index) {
                        final track = _currentSession.tracks[index];
                        return ListTile(
                          leading: const Icon(Icons.audio_file),
                          title: Text('Track ${index + 1}'),
                          subtitle: Text(track.filePath.split('/').last),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () {
                              // TODO: Implement single track playback
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _toggleRecording, backgroundColor: _isRecording ? Colors.red : Colors.green, child: Icon(_isRecording ? Icons.stop : Icons.mic)),
    );
  }
}
