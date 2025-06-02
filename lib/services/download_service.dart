import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class DownloadService {
  static const String _playlistUrl = 'https://cors-anywhere.herokuapp.com/https://www.rafaelamorim.com.br/mobile2/musicas/list.json';

  Future<List<Song>> fetchPlaylist() async {
    try {
      final response = await http.get(Uri.parse(_playlistUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Song.fromJson(json)).toList();
      }
      throw Exception('Error al cargar la playlist');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> downloadSong(Song song, Function(double) onProgress) async {
    try {
      song.isDownloading = true;
      song.downloadProgress = 0.0;

      final response = await http.get(Uri.parse('https://cors-anywhere.herokuapp.com/${song.url}'));
      if (response.statusCode == 200) {
        song.isDownloaded = true;
        song.isDownloading = false;
        song.downloadProgress = 1.0;
        onProgress(1.0);
      } else {
        throw Exception('Error al descargar la canción');
      }
    } catch (e) {
      song.isDownloading = false;
      song.downloadProgress = 0.0;
      throw Exception('Error al descargar la canción: $e');
    }
  }
} 