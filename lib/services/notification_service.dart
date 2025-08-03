import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'trustify_certificates';
  static const String _channelName = 'Certificados Trustify';
  static const String _channelDescription = 'Notificaciones de certificados NFT emitidos';

  /// Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    try {
      // Configuración para Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración general
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Crear canal de notificaciones para Android
      await _createNotificationChannel();

      developer.log('Servicio de notificaciones inicializado', name: 'NotificationService');
    } catch (e) {
      developer.log('Error inicializando notificaciones: $e', name: 'NotificationService');
    }
  }

  /// Crear canal de notificaciones para Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Solicitar permisos de notificación
  static Future<bool> requestPermissions() async {
    try {
      // Para Android 13+
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }

      return true; // Para versiones más antiguas
    } catch (e) {
      developer.log('Error solicitando permisos: $e', name: 'NotificationService');
      return false;
    }
  }

  /// Mostrar notificación de certificado emitido
  static Future<void> showCertificateNotification({
    required String certificateName,
    String? issuerName,
  }) async {
    try {
      const int notificationId = 1001;
      
      final String title = '🎉 Certificado Emitido';
      final String body = issuerName != null 
          ? 'Se ha emitido el certificado "$certificateName" por $issuerName'
          : 'Se ha emitido un nuevo certificado: "$certificateName"';

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: 'certificate:$certificateName',
      );

      developer.log('Notificación mostrada: $certificateName', name: 'NotificationService');
    } catch (e) {
      developer.log('Error mostrando notificación: $e', name: 'NotificationService');
    }
  }

  /// Manejar cuando se toca una notificación
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    try {
      final String? payload = notificationResponse.payload;
      developer.log('Notificación tocada con payload: $payload', name: 'NotificationService');
      
      if (payload != null && payload.startsWith('certificate:')) {
        final certificateName = payload.substring('certificate:'.length);
        developer.log('Usuario tocó notificación del certificado: $certificateName', name: 'NotificationService');
        // Aquí puedes navegar a una pantalla específica o realizar alguna acción
      }
    } catch (e) {
      developer.log('Error manejando toque de notificación: $e', name: 'NotificationService');
    }
  }

  /// Mostrar notificación de prueba
  static Future<void> showTestNotification() async {
    await showCertificateNotification(
      certificateName: 'Certificado de Prueba NFT',
      issuerName: 'Trustify Platform',
    );
  }
}
