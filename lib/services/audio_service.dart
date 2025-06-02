import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  bool _isInitialized = false;
  bool _isBuffering = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _audioPlayer.setLoopMode(LoopMode.off);
      _audioPlayer.playbackEventStream.listen((event) {
        if (event.processingState == ProcessingState.buffering) {
          _isBuffering = true;
        } else {
          _isBuffering = false;
        }
      });
      _isInitialized = true;
    }
  }

  Future<void> play(Song song) async {
    if (_currentSong?.url != song.url) {
      _currentSong = song;
      final audioSource = AudioSource.uri(
        Uri.parse(song.url),
      );

      await _audioPlayer.setAudioSource(
        audioSource,
        preload: true,
        initialPosition: Duration.zero,
      );
    }

    if (!_isBuffering) {
      await _audioPlayer.play();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  Duration? _parseDuration(String duration) {
    try {
      final parts = duration.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return Duration(minutes: minutes, seconds: seconds);
      }
    } catch (e) {
      print('Error parsing duration: $e');
    }
    return null;
  }

  // Streams para la UI
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<SequenceState?> get sequenceStateStream => _audioPlayer.sequenceStateStream;
  Stream<bool> get bufferingStream => _audioPlayer.processingStateStream
      .map((state) => state == ProcessingState.buffering);

  // Getters para el estado actual
  bool get isPlaying => _audioPlayer.playing;
  bool get isBuffering => _isBuffering;
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;
  Song? get currentSong => _currentSong;
} 