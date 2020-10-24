import 'dart:io';

//obtém os dados do dispositivo, para identificação

class DeviceInfo {
  static String get label {
    return Platform.localHostname + '(' + Platform.operatingSystem + ")";
  }

  static String get userAgent {
    return 'flutter-webrtc/' + Platform.operatingSystem + '-plugin 0.0.1';
  }
}
