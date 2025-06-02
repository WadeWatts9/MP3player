import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_service.dart';
import '../services/download_service.dart';
import '../services/background_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DownloadService _downloadService = DownloadService();
  final AudioService _audioService = AudioService();
  final BackgroundService _backgroundService = BackgroundService();
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
      await _backgroundService.initialize();
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
      await _backgroundService.scheduleDownload(song);
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
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Logo y título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 48, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'MP3 Player',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_audioService.currentSong != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _audioService.currentSong!.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _audioService.currentSong!.author,
                      style: theme.textTheme.titleMedium,
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
                            _audioService.isPlaying ? Icons.pause_circle : Icons.play_circle,
                            size: 40,
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
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.music_note, color: theme.colorScheme.primary),
                        ),
                        title: Text(song.title, style: theme.textTheme.titleMedium),
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
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Text(
                'diseñado por AC y WR',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
} 