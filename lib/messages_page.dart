import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';

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
  const MessagesPage({super.key});

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

  Future<void> _saveMessages() async {
    // This method is called when undoing a delete action
    // No need to save to backend as the delete was already handled
    // The UI will update through the stream subscription
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
  
  Future<void> _markAllAsRead() async {
    try {
      final unreadMessages = _messages.where((m) => !m.isRead).toList();
      
      if (unreadMessages.isNotEmpty) {
        await _supabase
            .from(_tableName)
            .update({'is_read': true})
            .inFilter('id', unreadMessages.map((m) => m.id).toList());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark all as read')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Special Offers'),
        actions: [
          if (_messages.any((msg) => !msg.isRead))
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? Center(
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
                )
              : ListView.builder(
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
                            content: Text('Deleted: ${message.title}'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                setState(() {
                                  _messages.insert(index, message);
                                });
                                _saveMessages();
                              },
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: message.isRead
                              ? Colors.grey[300]
                              : Theme.of(context).primaryColor,
                          child: Icon(
                            Icons.local_offer,
                            color: message.isRead ? Colors.grey[600] : Colors.white,
                          ),
                        ),
                        title: Text(
                          message.title,
                          style: TextStyle(
                            fontWeight: message.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message.body),
                            const SizedBox(height: 4),
                            Text(
                              '${message.storeName != null ? '${message.storeName} • ' : ''}${timeago.format(message.timestamp, locale: 'en_short')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!message.isRead) {
                            _markAsRead(message);
                          }
                          // Handle message tap (e.g., navigate to offer details)
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
