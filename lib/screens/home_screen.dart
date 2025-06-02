import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_service.dart';
import '../services/download_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DownloadService _downloadService = DownloadService();
  final AudioService _audioService = AudioService();
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _error;
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _audioService.positionStream.listen((position) {
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioService.durationStream.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    _audioService.bufferingStream.listen((buffering) {
      setState(() {
        _isBuffering = buffering;
      });
    });
  }

  Future<void> _initializeApp() async {
    try {
      await _audioService.initialize();
      final songs = await _downloadService.fetchPlaylist();
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadSong(Song song) async {
    try {
      await _downloadService.downloadSong(
        song,
        (progress) {
          setState(() {
            song.downloadProgress = progress;
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar: $e')),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: _initializeApp,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reproductor MP3'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          if (_audioService.currentSong != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                children: [
                  Text(
                    _audioService.currentSong!.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    _audioService.currentSong!.author,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(_formatDuration(_currentPosition)),
                      Expanded(
                        child: Slider(
                          value: _currentPosition.inSeconds.toDouble(),
                          max: _totalDuration?.inSeconds.toDouble() ?? 0,
                          onChanged: (value) {
                            _audioService.seekTo(
                              Duration(seconds: value.toInt()),
                            );
                          },
                        ),
                      ),
                      Text(_formatDuration(_totalDuration ?? Duration.zero)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () {
                          if (_audioService.isPlaying) {
                            _audioService.pause();
                          } else {
                            _audioService.play(_audioService.currentSong!);
                          }
                          setState(() {});
                        },
                      ),
                      if (_isBuffering)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(song.title),
                    subtitle: Text(song.author),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (song.isDownloading)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value: song.downloadProgress,
                            ),
                          )
                        else if (!song.isDownloaded)
                          IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => _downloadSong(song),
                          ),
                        IconButton(
                          icon: Icon(
                            _audioService.currentSong?.url == song.url &&
                                    _audioService.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          onPressed: () {
                            if (_audioService.currentSong?.url == song.url &&
                                _audioService.isPlaying) {
                              _audioService.pause();
                            } else {
                              _audioService.play(song);
                            }
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
} 