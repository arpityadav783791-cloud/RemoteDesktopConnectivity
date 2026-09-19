class RdpConnection {
  final String name;
  final String host;
  final String username;
  final String password;
  final String? domain;
  final bool fullscreen;
  final bool clipboard;
  final bool audio;
  final int width;
  final int height;
  final bool favorite;

  const RdpConnection({
    required this.name,
    required this.host,
    required this.username,
    required this.password,
    this.domain,
    this.fullscreen = false,
    this.clipboard = true,
    this.audio = true,
    this.width = 1280,
    this.height = 720,
    this.favorite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'host': host,
      'username': username,
      'password': password,
      'domain': domain,
      'fullscreen': fullscreen,
      'clipboard': clipboard,
      'audio': audio,
      'width': width,
      'height': height,
      'favorite': favorite,
    };
  }

  factory RdpConnection.fromJson(Map<String, dynamic> json) {
    return RdpConnection(
      name: json['name'] ?? '',
      host: json['host'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      domain: json['domain'],
      fullscreen: json['fullscreen'] ?? false,
      clipboard: json['clipboard'] ?? true,
      audio: json['audio'] ?? true,
      width: json['width'] ?? 1280,
      height: json['height'] ?? 720,
      favorite: json['favorite'] ?? false,
    );
  }
}
