# Reproductor MP3 Flutter

Una aplicación móvil desarrollada en Flutter para reproducir música MP3 con las siguientes características:

## Características principales

- Descarga y reproducción de playlist desde un servidor remoto
- Reproducción en segundo plano con notificaciones
- Streaming progresivo de audio
- Interfaz de usuario moderna y fácil de usar
- Gestión de descargas en segundo plano
- Manejo de errores y reconexión automática

## Requisitos

- Flutter SDK >= 3.2.3
- Android SDK >= 21
- Permisos de Internet y almacenamiento

## Instalación

1. Clona el repositorio:
```bash
git clone https://github.com/tu-usuario/mp3_player.git
```

2. Navega al directorio del proyecto:
```bash
cd mp3_player
```

3. Instala las dependencias:
```bash
flutter pub get
```

4. Ejecuta la aplicación:
```bash
flutter run
```

## Estructura del proyecto

```
lib/
  ├── models/
  │   └── song.dart
  ├── screens/
  │   └── home_screen.dart
  ├── services/
  │   ├── audio_service.dart
  │   └── download_service.dart
  └── main.dart
```

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## Contribuidores

- [Tu Nombre] - Desarrollador principal

## Agradecimientos

- Flutter team por el framework
- Los desarrolladores de los paquetes utilizados
- La comunidad de Flutter por su apoyo 