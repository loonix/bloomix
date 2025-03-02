import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'audio_manager.dart';
import 'models.dart';

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
  final Record _audioRecorder = Record();
  bool _isRecording = false;
  Session _currentSession = Session('New Session', []);
  String? _currentRecordingPath;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      await _audioRecorder.stop();

      if (_currentRecordingPath != null) {
        // Add the recording to the session
        _currentSession.tracks.add(Track(_currentRecordingPath!, Duration.zero));

        setState(() {
          _isRecording = false;
          _currentRecordingPath = null;
        });
      }
    } else {
      // Start recording
      if (await _audioRecorder.hasPermission()) {
        // Get a unique file path for the new recording
        final path = await _audioManager.getNewRecordingPath();
        _currentRecordingPath = path;

        await _audioRecorder.start(
          path: path,
          encoder: AudioEncoder.wav, // Using WAV format for quality
          bitRate: 128000,
          samplingRate: 44100,
        );

        setState(() {
          _isRecording = true;
        });
      } else {
        // No permission to record audio
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied')));
        }
      }
    }
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
