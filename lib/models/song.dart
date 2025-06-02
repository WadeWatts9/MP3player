class Song {
  final String id;
  final String title;
  final String author;
  final String url;
  final String? coverUrl;
  double downloadProgress;
  bool isDownloading;
  bool isDownloaded;

  Song({
    required this.id,
    required this.title,
    required this.author,
    required this.url,
    this.coverUrl,
    this.downloadProgress = 0.0,
    this.isDownloading = false,
    this.isDownloaded = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      url: json['url'] as String,
      coverUrl: json['coverUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'url': url,
      'coverUrl': coverUrl,
    };
  }
} 