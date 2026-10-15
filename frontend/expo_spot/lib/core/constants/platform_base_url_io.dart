import 'dart:io';

String platformDefaultBaseUrl() {
  if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://127.0.0.1:8080';
}
