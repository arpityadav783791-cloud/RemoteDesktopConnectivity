class RdpErrorMapper {
  static String message(String raw) {
    final text = raw.toLowerCase();
    if (text.contains('authentication') ||
        text.contains('logon failure') ||
        text.contains('wrong password')) {
      return 'Authentication failed. Check the username and password.';
    }
    if (text.contains('connection refused')) {
      return 'The remote computer refused the connection.';
    }
    if (text.contains('could not resolve') ||
        text.contains('name or service not known')) {
      return 'The remote host could not be resolved.';
    }
    if (text.contains('timeout')) return 'The connection timed out.';
    if (text.contains('certificate')) {
      return 'The remote certificate could not be verified.';
    }
    return raw.trim().isEmpty ? 'Unable to establish the RDP session.' : raw.trim();
  }
}
