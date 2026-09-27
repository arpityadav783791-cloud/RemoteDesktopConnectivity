import 'package:uuid/uuid.dart';

class RdpConnection {
  final String id;
  final String name;
  final String host;
  final String username;
  final String password;
  final String? domain;
  final bool rememberMe;
  final bool fullscreen;
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
    this.rememberMe = false,
    this.fullscreen = false,
    this.width = 1280,
    this.height = 720,
    this.favorite = false,
  });

  factory RdpConnection.create({
    required String name,
    required String host,
    required String username,
    required String password,
    String? domain,
    bool rememberMe = false,
    bool fullscreen = false,
    int width = 1280,
    int height = 720,
    bool favorite = false,
  }) => RdpConnection(
        id: const Uuid().v4(),
        name: name,
        host: host,
        username: username,
        password: password,
        domain: domain,
        rememberMe: rememberMe,
        fullscreen: fullscreen,
        width: width,
        height: height,
        favorite: favorite,
      );

  RdpConnection copyWith({
    String? name,
    String? host,
    String? username,
    String? password,
    String? domain,
    bool? rememberMe,
    bool? fullscreen,
    int? width,
    int? height,
    bool? favorite,
  }) => RdpConnection(
        id: id,
        name: name ?? this.name,
        host: host ?? this.host,
        username: username ?? this.username,
        password: password ?? this.password,
        domain: domain ?? this.domain,
        rememberMe: rememberMe ?? this.rememberMe,
        fullscreen: fullscreen ?? this.fullscreen,
        width: width ?? this.width,
        height: height ?? this.height,
        favorite: favorite ?? this.favorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'username': username,
        'password': rememberMe ? password : '',
        'domain': domain,
        'rememberMe': rememberMe,
        'fullscreen': fullscreen,
        'width': width,
        'height': height,
        'favorite': favorite,
      };

  factory RdpConnection.fromJson(Map<String, dynamic> json) {
    final savedId = (json['id'] as String?)?.trim();
    return RdpConnection(
      id: savedId == null || savedId.isEmpty ? const Uuid().v4() : savedId,
      name: json['name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      domain: json['domain'] as String?,
      rememberMe: json['rememberMe'] as bool? ?? false,
      fullscreen: json['fullscreen'] as bool? ?? false,
      width: (json['width'] as num?)?.toInt() ?? 1280,
      height: (json['height'] as num?)?.toInt() ?? 720,
      favorite: json['favorite'] as bool? ?? false,
    );
  }
}
