import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/song.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  bool _isInitialized = false;
  // StreamControllers para manejar el estado de buffering y la canción actual.
  final StreamController<bool> _bufferingStreamController = StreamController<bool>.broadcast();
  final StreamController<Song?> _currentSongStreamController = StreamController<Song?>.broadcast();

  Future<void> initialize() async {
    if (!_isInitialized) {
      // Escucha los eventos de estado del reproductor para actualizar el estado de buffering.
      _audioPlayer.playerStateStream.listen((playerState) {
        final isPlaying = playerState.playing;
        final processingState = playerState.processingState;
        if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
          _bufferingStreamController.add(true);
        } else {
          _bufferingStreamController.add(false);
        }
      });
      _isInitialized = true;
    }
  }

  Future<void> play(Song song) async {
    if (_currentSong?.url != song.url || !_audioPlayer.playing) {
      _currentSong = song;
      _currentSongStreamController.add(song);

      // Utiliza DefaultCacheManager para obtener el archivo (ya sea de caché o descargándolo)
      final fileInfo = await DefaultCacheManager().getFileStream(song.url, withProgress: true).first;
      
      final audioSource = AudioSource.uri(
        Uri.parse(fileInfo.file.path), // Usa la ruta del archivo local
        tag: MediaItem(
          id: song.url, // ID único para la canción
          album: "Playlist MP3",
          title: song.title,
          artist: song.author,
          artUri: Uri.parse("https://example.com/albumart.jpg"), // Placeholder, idealmente deberías tener una URL de imagen real
        ),
      );

      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
    } else {
      await _audioPlayer.play(); // Si es la misma canción y estaba pausada, solo reanuda.
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSong = null;
    _currentSongStreamController.add(null);
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
    _bufferingStreamController.close();
    _currentSongStreamController.close();
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
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<bool> get bufferingStream => _bufferingStreamController.stream;
  Stream<Song?> get currentSongStream => _currentSongStreamController.stream;

  // Getters para el estado actual
  bool get isPlaying => _audioPlayer.playing;
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;
  Song? get currentSong => _currentSong;
} 