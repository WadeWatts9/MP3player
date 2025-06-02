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
    final theme = Theme.of(context);
    
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
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('MP3 Player'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          if (_audioService.currentSong != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _audioService.currentSong!.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _audioService.currentSong!.author,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
                          _audioService.isPlaying ? Icons.pause_circle : Icons.play_circle,
                          size: 48,
                          color: theme.colorScheme.primary,
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
              padding: const EdgeInsets.all(8),
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        song.isDownloaded ? Icons.music_note : Icons.download,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(song.title),
                    subtitle: Text('${song.author} • ${song.duration}'),
                    trailing: song.isDownloading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value: song.downloadProgress,
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              song.isDownloaded ? Icons.play_arrow : Icons.download,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () {
                              if (song.isDownloaded) {
                                _audioService.play(song);
                              } else {
                                _downloadSong(song);
                              }
                            },
                          ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Diseñado por AC y WR',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
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