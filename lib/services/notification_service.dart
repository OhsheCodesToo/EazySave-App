import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<dynamic>? _subscription;

  Future<void> initialize() async {
    await _requestNotificationPermission();
    await _initializeLocalNotifications();
    await _setupRealtimeSubscription();
  }

  Future<void> _setupRealtimeSubscription() async {
    // Cancel any existing subscription
    await _subscription?.cancel();
    
    // Subscribe to notifications table changes
    _subscription = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .listen((dynamic data) {
      final List<Map<String, dynamic>> rows = data is List
          ? data.cast<Map<String, dynamic>>()
          : const <Map<String, dynamic>>[];

      if (rows.isNotEmpty) {
        final notification = rows.last;
        _showLocalNotification(
          title: notification['title'] ?? 'New Offer!',
          body: notification['message'] ?? 'Check out our latest offers!',
          payload: notification['payload']?.toString(),
        );
      }
    }, onError: (error) {
      debugPrint('Supabase realtime error (notifications): $error');
    });
  }

  Future<void> _requestNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Request notification permission for iOS
      await Permission.notification.request();
    }
  }

  // Method to send a notification to all users
  Future<void> sendNotification({
    required String title,
    required String message,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'title': title,
        'message': message,
        'payload': payload,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    tz.initializeTimeZones();

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'eazysave_channel',
      'EazySave Notifications',
      channelDescription: 'This channel is used for EazySave app notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelDetails,
      payload: payload,
    );
  }

  // Schedule a daily notification
  Future<void> scheduleDailyNotification({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    try {
      // Instead of scheduling locally, we'll store the schedule in Supabase
      // and have a server-side function handle the actual scheduling
      await _supabase.from('scheduled_notifications').insert({
        'title': title,
        'message': body,
        'scheduled_time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        'is_recurring': true,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      rethrow;
    }
  }
  
  // Clean up resources
  void dispose() {
    _subscription?.cancel();
  }
}
