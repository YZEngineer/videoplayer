class YoutubeUtils {
  static String? extractVideoId(String url) {
    if (url.isEmpty) return null;

    // Handle youtu.be short URLs
    if (url.contains('youtu.be')) {
      final uri = Uri.parse(url);
      return uri.pathSegments.first;
    }

    // Handle youtube.com URLs
    if (url.contains('youtube.com')) {
      final uri = Uri.parse(url);
      return uri.queryParameters['v'];
    }

    // If the input is already a video ID (no URL format)
    if (url.length == 11 && !url.contains('/') && !url.contains('.')) {
      return url;
    }

    return null;
  }
}
