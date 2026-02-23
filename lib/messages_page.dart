import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';
import 'province_dropdown.dart';

class Message {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? storeName;
  final bool isRead;
  final Map<String, dynamic>? payload;

  Message({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.storeName,
    this.isRead = false,
    this.payload,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'New Offer!',
      body: json['message']?.toString() ?? json['body']?.toString() ?? '',
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : json['timestamp'] != null
              ? DateTime.parse(json['timestamp'].toString())
              : DateTime.now(),
      storeName: json['store_name']?.toString() ?? json['storeName']?.toString(),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      payload: json['payload'] is Map<String, dynamic> 
          ? json['payload'] 
          : json['payload'] != null 
              ? {'data': json['payload']} 
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': body,
      'created_at': timestamp.toIso8601String(),
      'store_name': storeName,
      'is_read': isRead,
      'payload': payload,
    };
  }
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, this.showBackground = false});

  final bool showBackground;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Message> _messages = [];
  bool _isLoading = true;
  StreamSubscription? _messagesSubscription;
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'notifications';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Opacity(
          opacity: 1,
          child: Image.asset(
            'assets/welcome_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Container(color: Colors.white.withValues(alpha: 0.20)),
      ],
    );
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Cancel any existing subscription
      await _messagesSubscription?.cancel();
      
      // Subscribe to real-time updates
      _messagesSubscription = _supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen((dynamic data) {
        if (mounted) {
          final List<Map<String, dynamic>> rows = data is List
              ? data.cast<Map<String, dynamic>>()
              : const <Map<String, dynamic>>[];
          setState(() {
            _messages = rows
                .map((json) => Message.fromJson(json))
                .toList(growable: false);
            _isLoading = false;
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading messages: $error')),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load messages')),
        );
      }
    }
  }

  Future<void> _markAsRead(Message message) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'is_read': true})
          .eq('id', message.id);
      
      // The UI will update automatically through the stream subscription
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark message as read')),
        );
      }
    }
  }

  Future<void> _deleteMessage(String id) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id);
      
      // The UI will update automatically through the stream subscription
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete message')),
        );
      }
      // Refresh the list to restore the deleted message
      _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBackground = Color(0xFFF5F5F5);
    const Color primaryTeal = Color(0xFF315762);
    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_messages.isEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No special offers yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for the latest deals and offers',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    } else {
      content = ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return Dismissible(
            key: Key(message.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            onDismissed: (direction) {
              _deleteMessage(message.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${message.title}" deleted'),
                ),
              );
            },
            child: Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: message.isRead
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                  child: Icon(
                    message.isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  message.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: message.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.storeName != null &&
                        message.storeName!.isNotEmpty)
                      Text(
                        message.storeName!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    Text(
                      message.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(message.timestamp),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
                onTap: () => _markAsRead(message),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: primaryTeal,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ProvinceDropdown(
              foregroundColor: primaryTeal,
              dropdownColor: pageBackground,
            ),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () {
            Navigator.of(context)
                .popUntil((Route<dynamic> route) => route.isFirst);
          },
        ),
        title: const Text('Deals'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (widget.showBackground) _buildBackground(),
            SafeArea(
              top: false,
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}
