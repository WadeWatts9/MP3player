class Song {
  final String title;
  final String author;
  final String url;
  final String duration;
  bool isDownloaded;
  bool isDownloading;
  double downloadProgress;

  Song({
    required this.title,
    required this.author,
    required this.url,
    required this.duration,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      url: json['url'] ?? '',
      duration: json['duration'] ?? '00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'url': url,
      'duration': duration,
    };
  }
} 