import 'package:uuid/uuid.dart';

class RdpConnection {
  /// Sentinel used by [copyWith] to tell "keep the current value" apart
  /// from "set this nullable field to null".
  static const Object _unset = Object();

  /// Stable, permanent identity of the connection.
  ///
  /// Identity MUST NOT be derived from name, host or username. The id stays
  /// unchanged when the connection is renamed, moved, edited or favorited.
  final String id;

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
    required this.id,
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

  /// Creates a brand new connection with a freshly generated stable id.
  factory RdpConnection.create({
    required String name,
    required String host,
    required String username,
    required String password,
    String? domain,
    bool fullscreen = false,
    bool clipboard = true,
    bool audio = true,
    int width = 1280,
    int height = 720,
    bool favorite = false,
  }) {
    return RdpConnection(
      id: const Uuid().v4(),
      name: name,
      host: host,
      username: username,
      password: password,
      domain: domain,
      fullscreen: fullscreen,
      clipboard: clipboard,
      audio: audio,
      width: width,
      height: height,
      favorite: favorite,
    );
  }

  /// Returns a copy of this connection with the given fields replaced.
  ///
  /// Omitted fields keep their current value, including [id] and [favorite].
  /// Pass `domain: null` explicitly to clear the domain.
  RdpConnection copyWith({
    String? id,
    String? name,
    String? host,
    String? username,
    String? password,
    Object? domain = _unset,
    bool? fullscreen,
    bool? clipboard,
    bool? audio,
    int? width,
    int? height,
    bool? favorite,
  }) {
    return RdpConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      username: username ?? this.username,
      password: password ?? this.password,
      domain: identical(domain, _unset) ? this.domain : domain as String?,
      fullscreen: fullscreen ?? this.fullscreen,
      clipboard: clipboard ?? this.clipboard,
      audio: audio ?? this.audio,
      width: width ?? this.width,
      height: height ?? this.height,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      // Legacy records have no id yet; they receive one during storage
      // migration (see StorageService.loadConnections).
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      domain: json['domain'] as String?,
      fullscreen: json['fullscreen'] as bool? ?? false,
      clipboard: json['clipboard'] as bool? ?? true,
      audio: json['audio'] as bool? ?? true,
      width: json['width'] as int? ?? 1280,
      height: json['height'] as int? ?? 720,
      favorite: json['favorite'] as bool? ?? false,
    );
  }

  /// Two connections are the same record when their stable ids match.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RdpConnection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Never leaks the password through logs or debug output.
  @override
  String toString() {
    return 'RdpConnection(id: $id, name: $name, host: $host, '
        'username: $username, password: ********, domain: $domain, '
        'fullscreen: $fullscreen, clipboard: $clipboard, audio: $audio, '
        'width: $width, height: $height, favorite: $favorite)';
  }
}
