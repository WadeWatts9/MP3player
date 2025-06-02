import '../models/song.dart';

// Implementación Stub para plataformas no Android
class BackgroundService {
  Future<void> initialize() async {
    // No se necesita inicialización para el stub
    print('BackgroundService: Stub initialized (no background tasks on this platform).');
  }

  Future<void> scheduleDownload(Song song) async {
    print('BackgroundService: scheduleDownload called on unsupported platform.');
    // Opcional: lanzar una excepción o manejarlo de alguna manera
    // throw UnimplementedError('Background download is not supported on this platform.');
    // Por ahora, solo lo registraremos.
  }

  Future<void> cancelDownload(String songUrl) async {
    print('BackgroundService: cancelDownload called on unsupported platform.');
  }

  // Podrías añadir un stream para el progreso si quieres simularlo en la UI,
  // pero para un stub, usualmente se mantiene simple.
} 