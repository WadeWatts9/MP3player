import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class DownloadService {
  // Usar la URL directa. Para web, el usuario puede desactivar CORS en el navegador para desarrollo.
  // Para Android, no hay problemas de CORS con http.
  static const String _playlistUrl = 'https://www.rafaelamorim.com.br/mobile2/musicas/list.json';

  Future<List<Song>> fetchPlaylist() async {
    try {
      print('Fetching playlist from: $_playlistUrl');
      final response = await http.get(Uri.parse(_playlistUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        // Asegurarse de que las URLs de las canciones también sean directas
        return jsonList.map((json) {
          String songUrl = json['url'];
          // Eliminar el proxy si está presente en la URL de la canción del JSON
          if (songUrl.startsWith('https://cors-anywhere.herokuapp.com/')) {
            songUrl = songUrl.replaceFirst('https://cors-anywhere.herokuapp.com/', '');
          }
          return Song.fromJson({...json, 'url': songUrl});
        }).toList();
      } else {
        print('Error fetching playlist: ${response.statusCode} ${response.body}');
        throw Exception('Error al cargar la playlist (status: ${response.statusCode})');
      }
    } catch (e) {
      print('Connection error: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // La función downloadSong se eliminará de aquí, ya que workmanager la gestionará
  // a través de BackgroundService.
} 