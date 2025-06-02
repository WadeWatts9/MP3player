import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
  late final BackgroundService _backgroundService;
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _error;
  Song? _currentPlayingSong;
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;
  bool _isBuffering = false;
  bool _isPlaying = false;

  final Map<String, StreamSubscription<FileResponse>> _downloadSubscriptions = {};
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloaded = {};

  @override
  void initState() {
    super.initState();
    _backgroundService = BackgroundService();
    _requestPermissions();
    _initializeApp();
    _setupAudioListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _downloadSubscriptions.forEach((key, subscription) => subscription.cancel());
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  void _setupAudioListeners() {
    _audioService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioService.bufferingStream.listen((buffering) {
      if (mounted) {
        setState(() {
          _isBuffering = buffering;
        });
      }
    });

    _audioService.playerStateStream.listen((playerState) {
      if (mounted) {
        setState(() {
          _isPlaying = playerState.playing;
        });
      }
    });

    _audioService.currentSongStream.listen((song) {
      if (mounted) {
        setState(() {
          _currentPlayingSong = song;
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await _audioService.initialize();
      await _backgroundService.initialize();
      final songs = await _downloadService.fetchPlaylist();
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
        for (var song in songs) {
          _checkIfDownloaded(song);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkIfDownloaded(Song song) async {
    final file = await _backgroundService.getCachedFile(song.url);
    if (mounted) {
      setState(() {
        _isDownloaded[song.url] = file != null && file.existsSync();
        if (_isDownloaded[song.url] == true) _downloadProgress[song.url] = 1.0;
      });
    }
  }

  Future<void> _startOrPlaySong(Song song) async {
    final isSongDownloaded = _isDownloaded[song.url] ?? false;

    if (isSongDownloaded) {
      await _audioService.play(song);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Iniciando descarga de ${song.title}...')),
      );
      _scheduleDownload(song);
      await _audioService.play(song);
    }
    if (mounted) setState(() {});
  }

  void _scheduleDownload(Song song) {
    if (_downloadProgress[song.url] != null && _downloadProgress[song.url]! > 0 && _downloadProgress[song.url]! < 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${song.title} ya se está descargando.')));
      return;
    }

    _backgroundService.scheduleDownload(song);
    if (mounted) {
      setState(() {
        _downloadProgress[song.url] = 0.001;
        _isDownloaded[song.url] = false;
      });
    }

    _downloadSubscriptions[song.url]?.cancel();
    _downloadSubscriptions[song.url] = _backgroundService.getDownloadProgressStream(song.url).listen(
      (fileResponse) {
        if (fileResponse is DownloadProgress) {
          if (mounted) {
            setState(() {
              _downloadProgress[song.url] = (fileResponse.downloaded / (fileResponse.totalSize ?? fileResponse.downloaded)).toDouble();
              _isDownloaded[song.url] = false;
            });
          }
        } else if (fileResponse is FileInfo) {
          if (mounted) {
            setState(() {
              _downloadProgress[song.url] = 1.0;
              _isDownloaded[song.url] = true;
            });
          }
          _downloadSubscriptions[song.url]?.cancel();
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error descargando ${song.title}: $error')),
          );
          setState(() {
            _downloadProgress.remove(song.url);
            _isDownloaded[song.url] = false;
          });
        }
      },
      onDone: () {
        _checkIfDownloaded(song);
      }
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildSongListItem(Song song, ThemeData theme) {
    final bool isCurrentlyPlaying = _currentPlayingSong?.url == song.url;
    final double progress = _downloadProgress[song.url] ?? 0.0;
    final bool downloaded = _isDownloaded[song.url] ?? false;

    Widget trailingWidget;
    if (downloaded) {
      trailingWidget = Icon(Icons.check_circle, color: Colors.green, size: 30);
    } else if (progress > 0 && progress < 1) {
      trailingWidget = SizedBox(
        width: 30, height: 30,
        child: CircularProgressIndicator(value: progress, strokeWidth: 3)
      );
    } else {
      trailingWidget = IconButton(
        icon: Icon(Icons.download_for_offline, size: 30, color: theme.colorScheme.primary),
        onPressed: () => _scheduleDownload(song),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isCurrentlyPlaying ? 4 : 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: isCurrentlyPlaying ? theme.colorScheme.primaryContainer.withOpacity(0.5) : theme.cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.music_note, color: theme.colorScheme.primary),
        ),
        title: Text(song.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(song.author),
        trailing: trailingWidget,
        onTap: () => _startOrPlaySong(song),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
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
            if (_currentPlayingSong != null)
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
                      _currentPlayingSong!.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _currentPlayingSong!.author,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (_totalDuration != null)
                      Row(
                        children: [
                          Text(_formatDuration(_currentPosition)),
                          Expanded(
                            child: Slider(
                              value: _currentPosition.inSeconds.toDouble().clamp(0.0, _totalDuration!.inSeconds.toDouble()),
                              max: _totalDuration!.inSeconds.toDouble(),
                              onChanged: (value) {
                                _audioService.seekTo(Duration(seconds: value.toInt()));
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
                            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            if (_isPlaying) {
                              _audioService.pause();
                            } else {
                              if (_currentPlayingSong != null) {
                                _audioService.play(_currentPlayingSong!);
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.stop_circle_outlined, size: 48, color: theme.colorScheme.secondary),
                          onPressed: () {
                            _audioService.stop();
                          },
                        ),
                        if (_isBuffering)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _songs.isEmpty
                  ? Center(child: Text('No hay canciones en la playlist.', style: theme.textTheme.bodyLarge))
                  : ListView.builder(
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        return _buildSongListItem(song, theme);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Diseñado por AC y WR',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 