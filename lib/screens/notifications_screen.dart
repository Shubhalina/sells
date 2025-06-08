import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> notifications = [];
  String selectedCategory = 'All';
  bool isLoading = true;

  final categories = ['All', 'Offers', 'Orders', 'Updates', 'Me'];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }
Future<void> _fetchNotifications() async {
  try {
    setState(() => isLoading = true);

    var query = supabase.from('notifications');

   // if (selectedCategory != 'All') {
   //   query = query.eq('type', selectedCategory.toLowerCase());
   // }

    final data = await query
        .select()
        .order('created_at', ascending: false);

    setState(() {
      notifications = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    });
  } catch (e) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching notifications: $e')),
    );
  }
}

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final createdAt = DateTime.parse(notification['created_at']).toLocal();
    final isToday = DateTime.now().difference(createdAt).inDays == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isToday && notifications.indexOf(notification) == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (!isToday && 
            (notifications.indexOf(notification) == 0 || 
             DateTime.parse(notifications[notifications.indexOf(notification) - 1]['created_at'])
                 .toLocal()
                 .day != createdAt.day))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              DateFormat('MMMM d').format(createdAt),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _getNotificationIcon(notification['type']),
          title: Text(
            notification['title'],
            style: TextStyle(
              fontWeight: notification['is_read'] ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification['message']),
              const SizedBox(height: 4),
              Text(
                _formatTimeAgo(createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          onTap: () async {
            // Mark as read and handle notification tap
            if (!notification['is_read']) {
              await supabase
                  .from('notifications')
                  .update({'is_read': true})
                  .eq('id', notification['id']);
              setState(() {
                notification['is_read'] = true;
              });
            }
            _handleNotificationTap(notification);
          },
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'offer':
        icon = Icons.local_offer;
        color = Colors.orange;
        break;
      case 'order':
        icon = Icons.shopping_bag;
        color = Colors.blue;
        break;
      case 'update':
        icon = Icons.update;
        color = Colors.green;
        break;
      case 'system':
        icon = Icons.notifications;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications_none;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Handle navigation based on notification type
    switch (notification['type']) {
      case 'offer':
        // Navigate to offer screen
        break;
      case 'order':
        // Navigate to order details
        break;
      case 'update':
        // Navigate to update screen
        break;
      default:
        // Default action
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                        _fetchNotifications();
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? const Center(
                        child: Text('No notifications found'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationItem(notifications[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}