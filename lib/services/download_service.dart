import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

class DownloadService {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  Future<void> downloadSong(Song song, Function(double) onProgress) async {
    try {
      song.isDownloading = true;
      song.downloadProgress = 0.0;

      final fileStream = _cacheManager.getFileStream(song.url, withProgress: true);
      File? file;
      await for (var response in fileStream) {
        if (response is DownloadProgress) {
          final progress = response.progress ?? 0.0;
          song.downloadProgress = progress;
          onProgress(progress);
        } else if (response is FileInfo) {
          file = response.file;
        }
      }

      if (file != null) {
        // Mover el archivo a una ubicación permanente
        final appDir = await getApplicationDocumentsDirectory();
        final songsDir = Directory('${appDir.path}/songs');
        if (!await songsDir.exists()) {
          await songsDir.create(recursive: true);
        }
        final destinationPath = '${songsDir.path}/${song.id}.mp3';
        await file.copy(destinationPath);

        song.isDownloaded = true;
        song.isDownloading = false;
        song.downloadProgress = 1.0;
      }
    } catch (e) {
      song.isDownloading = false;
      song.downloadProgress = 0.0;
      rethrow;
    }
  }

  Future<List<Song>> fetchPlaylist() async {
    // Aquí deberías implementar la lógica para obtener tu lista de reproducción
    // Por ahora, retornaremos una lista de ejemplo
    return [
      Song(
        id: '1',
        title: 'Canción de ejemplo 1',
        author: 'Artista 1',
        url: 'https://example.com/song1.mp3',
      ),
      Song(
        id: '2',
        title: 'Canción de ejemplo 2',
        author: 'Artista 2',
        url: 'https://example.com/song2.mp3',
      ),
    ];
  }

  Future<void> cancelDownload(Song song) async {
    if (song.isDownloading) {
      await _cacheManager.removeFile(song.url);
      song.isDownloading = false;
      song.downloadProgress = 0.0;
    }
  }
} 