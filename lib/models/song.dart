class Song {
  final String id;
  final String title;
  final String author;
  final String url;
  final String duration;
  final String? coverUrl;
  double downloadProgress;
  bool isDownloading;
  bool isDownloaded;

  Song({
    required this.id,
    required this.title,
    required this.author,
    required this.url,
    required this.duration,
    this.coverUrl,
    this.downloadProgress = 0.0,
    this.isDownloading = false,
    this.isDownloaded = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['title'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      url: json['url'] as String,
      duration: json['duration'] as String,
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