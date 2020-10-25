import 'dart:io';

//obtém os dados do dispositivo, para identificação
//codigo retirado da aplicação de vídeo conferência Flutter WebRTC disponível no Github em <https://github.com/nhancv/nc-flutter-webrtc-ex>
class DeviceInfo {
  static String get label {
    return Platform.localHostname + '(' + Platform.operatingSystem + ")";
  }

  static String get userAgent {
    return 'flutter-webrtc/' + Platform.operatingSystem + '-plugin 0.0.1';
  }
}
