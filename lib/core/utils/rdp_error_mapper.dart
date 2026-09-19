class RdpErrorMapper {
  static String getMessage(String error) {
    if (error.contains('ERRCONNECT_CONNECT_FAILED')) {
      return 'Unable to reach the RDP server.';
    }

    if (error.contains('ERRCONNECT_AUTHENTICATION_FAILED')) {
      return 'Authentication failed. Check your username and password.';
    }

    if (error.contains('ERRCONNECT_LOGON_FAILURE')) {
      return 'Login failed. Check your credentials.';
    }

    if (error.contains('ERRCONNECT_PASSWORD_CERTAINLY_EXPIRED')) {
      return 'Your password has expired.';
    }

    if (error.contains('ERRCONNECT_ACCOUNT_LOCKED_OUT')) {
      return 'The account is locked.';
    }

    if (error.contains('ERRCONNECT_ACCOUNT_RESTRICTION')) {
      return 'The account is restricted from connecting.';
    }

    if (error.contains('ERRCONNECT_CONNECT_TRANSPORT_FAILED')) {
      return 'The network connection to the RDP server failed.';
    }

    if (error.contains('ERRCONNECT_DNS_NAME_NOT_FOUND')) {
      return 'The hostname could not be resolved.';
    }

    return 'Unable to establish the RDP connection.';
  }
}
