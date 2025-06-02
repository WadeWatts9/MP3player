import 'dart:async';
import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:workmanager/workmanager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/song.dart';

const String _downloadTaskKey = "mp3DownloadTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _downloadTaskKey) {
      if (inputData == null) {
        print("Workmanager: inputData es nulo para la tarea $_downloadTaskKey");
        return Future.value(false); // Indica fallo
      }

      final String songUrl = inputData['url'];
      final String songTitle = inputData['title'];
      // No podemos pasar el objeto Song completo directamente, así que pasamos sus primitivas.

      print('Workmanager: Iniciando descarga para "$songTitle" ($songUrl)');

      try {
        // Usamos DefaultCacheManager para manejar la descarga y el caché.
        // Esto también maneja el streaming progresivo indirectamente, ya que
        // just_audio puede empezar a reproducir desde el caché mientras descarga.
        var file = await DefaultCacheManager().getSingleFile(
          songUrl,
          // Puedes añadir headers si son necesarios para la descarga.
          // headers: {"some_header": "some_value"},
        );
        
        if (file != null && await file.exists()) {
          print('Workmanager: Descarga completada para "$songTitle". Archivo en: ${file.path}');
          // Aquí podrías enviar una notificación local si lo deseas,
          // o actualizar el estado de la canción en una base de datos local si fuera necesario.
          // Por ahora, la UI se actualizará cuando intente acceder al archivo.
          return Future.value(true); // Indica éxito
        } else {
          print('Workmanager: Error en la descarga para "$songTitle". El archivo no existe o es nulo.');
          return Future.value(false); // Indica fallo
        }
      } catch (e) {
        print('Workmanager: Excepción durante la descarga de "$songTitle": $e');
        // Manejo de errores y reintentos:
        // Workmanager puede reintentar automáticamente basado en la configuración de Workmanager().initialize.
        // Si la tarea falla consistentemente, considera no reintentar indefinidamente.
        return Future.value(false); // Indica fallo, workmanager podría reintentar.
      }
    }
    return Future.value(true); // Tarea no reconocida, pero se considera manejada.
  });
}

class BackgroundService {
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Cambiar a false para release.
    );
    print('BackgroundService (Android): Workmanager inicializado.');
  }

  Future<void> scheduleDownload(Song song) async {
    // Preparamos los datos para WorkManager (solo tipos primitivos o listas/mapas de primitivos)
    final inputData = <String, dynamic>{
      'url': song.url,
      'title': song.title,
      // No podemos pasar el objeto Song completo, ni callbacks de progreso directamente a una isolate de workmanager.
      // La UI deberá verificar el estado del archivo a través de flutter_cache_manager o similar.
    };

    // Usamos un ID único para cada tarea de descarga basado en la URL de la canción.
    // Esto permite cancelar descargas específicas y evita duplicados si se programa la misma canción varias veces.
    // También permite a WorkManager gestionar reintentos para esta tarea específica.
    final uniqueTaskName = 'download_${song.url.hashCode}';

    print('BackgroundService (Android): Programando descarga para "${song.title}" con ID: $uniqueTaskName');
    
    await Workmanager().registerOneOffTask(
      uniqueTaskName, // ID único de la tarea
      _downloadTaskKey, // Nombre genérico de la tarea que el dispatcher buscará
      inputData: inputData,
      constraints: Constraints(
        networkType: NetworkType.connected, // Solo descargar con conexión a internet
        // Puedes añadir más restricciones como:
        // requiresCharging: true,
        // requiresStorageNotLow: true,
      ),
      // backoffPolicy: BackoffPolicy.exponential, // Estrategia de reintento
      // backoffPolicyDelay: Duration(minutes: 10), // Retraso inicial para reintento
    );
    // La UI deberá actualizar el estado de 'isDownloading' para la canción.
    // WorkManager no provee un stream de progreso directo a la UI desde la tarea en segundo plano.
    // La UI puede escuchar cambios en el caché de flutter_cache_manager o verificar periódicamente.
  }

  Future<void> cancelDownload(String songUrl) async {
    final uniqueTaskName = 'download_${songUrl.hashCode}';
    print('BackgroundService (Android): Cancelando descarga con ID: $uniqueTaskName');
    await Workmanager().cancelByUniqueName(uniqueTaskName);
  }

  // Helper para verificar si una canción está descargada (o siendo descargada por cache_manager)
  // Esto puede ser usado por la UI para mostrar el estado.
  Future<File?> getCachedFile(String url) async {
    final fileInfo = await DefaultCacheManager().getFileFromCache(url);
    return fileInfo?.file;
  }

  Stream<FileResponse> getDownloadProgressStream(String url) {
     return DefaultCacheManager().getFileStream(url, withProgress: true);
  }
} 