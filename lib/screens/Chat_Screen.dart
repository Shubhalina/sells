import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Add this import

class ChatSupportScreen extends StatefulWidget {
  final String productId; // Keep as String for now
  final String productTitle;
  final double productPrice;
  final String? productImage;
  final String sellerId; // Keep as String for now
  final String sellerName;
  final bool isSellerVerified;
  final String? orderId;
  // ... rest of your parameters

  const ChatSupportScreen({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    this.productImage,
    required this.sellerId,
    required this.sellerName,
    this.isSellerVerified = false,
    this.orderId,
  });

  factory ChatSupportScreen.validated({
    Key? key,
    required String productId,
    required String productTitle,
    required double productPrice,
    String? productImage,
    required String sellerId,
    required String sellerName,
    bool isSellerVerified = false,
    String? orderId,
  }) {
    assert(_isValidUUID(productId), 'Product ID must be a valid UUID');
    assert(_isValidUUID(sellerId), 'Seller ID must be a valid UUID');
    return ChatSupportScreen(
      key: key,
      productId: productId,
      productTitle: productTitle,
      productPrice: productPrice,
      productImage: productImage,
      sellerId: sellerId,
      sellerName: sellerName,
      isSellerVerified: isSellerVerified,
      orderId: orderId,
    );
  }

  static bool _isValidUUID(String? uuid) {
    if (uuid == null) return false;
    try {
      Uuid.parse(uuid);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _controller = TextEditingController();
  final _supabase = Supabase.instance.client;
  late final RealtimeChannel _chatChannel;

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _chatChannel = _supabase.channel('chat_${widget.productId}_${widget.sellerId}');
    _setupRealtimeSubscription();
    fetchMessages();
  }

  void _setupRealtimeSubscription() {
  _chatChannel
    .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'chat_messages',
        filter: 'product_id=eq.${widget.productId}', // Keep as raw string
      ),
      (payload, [ref]) {
        if (mounted) {
          setState(() {
            messages.insert(0, payload['new']);
          });
        }
      },
    )
      .on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'UPDATE',
          schema: 'public',
          table: 'chat_messages',
          filter: 'product_id=eq.${widget.productId}',
        ),
        (payload, [ref]) {
          if (mounted) {
            setState(() {
              final index = messages.indexWhere((m) => m['id'] == payload['new']['id']);
              if (index != -1) {
                messages[index] = payload['new'];
              }
            });
          }
        },
      )
      .subscribe();
  }
Future<void> fetchMessages() async {
  try {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Validate UUIDs before query
    if (!Uuid.isValidUUID(fromString: widget.productId) || 
        !Uuid.isValidUUID(fromString: widget.sellerId)) {
      throw Exception('Invalid UUID format');
    }

    final response = await _supabase
        .from('chat_messages')
        .select()
        .or('and(sender_id.eq.$userId,receiver_id.eq.${widget.sellerId}),and(sender_id.eq.${widget.sellerId},receiver_id.eq.$userId)')
        .eq('product_id', widget.productId) // Send as raw string
        .order('created_at', ascending: false);

    if (mounted) {
      setState(() {
        messages = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    }
  } catch (e) {
    // Enhanced error handling
    debugPrint('Error fetching messages: ${e.toString()}');
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e is PostgrestException ? e.message : e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

 
Future<void> sendMessage(String message) async {
  if (message.trim().isEmpty) return;

  try {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Validate all UUIDs
    if (!Uuid.isValidUUID(fromString: userId) ||
        !Uuid.isValidUUID(fromString: widget.sellerId) ||
        !Uuid.isValidUUID(fromString: widget.productId)) {
      throw Exception('One or more IDs are not valid UUIDs');
    }

    setState(() => isSending = true);

    final msg = {
      'sender_id': userId,
      'receiver_id': widget.sellerId,
      'product_id': widget.productId,
      'order_id': widget.orderId,
      'message': message.trim(),
    };

    await _supabase.from('chat_messages').insert(msg);
    _controller.clear();
  } catch (e) {
    debugPrint('Error sending message: ${e.toString()}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e is PostgrestException ? e.message : e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => isSending = false);
    }
  }
}

  @override
  void dispose() {
    _controller.dispose();
    _chatChannel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Chat"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isUser = msg['sender_id'] == _supabase.auth.currentUser?.id;
                          final sender = msg['sender'] as Map<String, dynamic>?;

                          return Column(
                            crossAxisAlignment: isUser 
                                ? CrossAxisAlignment.end 
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isUser)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                                  child: Text(
                                    sender?['name'] ?? 'Seller',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              Align(
                                alignment: isUser 
                                    ? Alignment.centerRight 
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser 
                                        ? Theme.of(context).primaryColor 
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: isUser 
                                          ? const Radius.circular(16) 
                                          : Radius.zero,
                                      bottomRight: isUser 
                                          ? Radius.zero 
                                          : const Radius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    msg['message'],
                                    style: TextStyle(
                                      color: isUser ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: isUser
                                    ? const EdgeInsets.only(right: 8.0)
                                    : const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  _formatTime(msg['created_at']),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    final time = DateTime.parse(isoTime).toLocal();
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage('assets/images/usericon.png'),
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.sellerName, 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (widget.isSellerVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0),
                            child: Icon(Icons.verified, 
                                color: Colors.blue, size: 16),
                          ),
                      ],
                    ),
                    const Text("Online • Product Owner", 
                        style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              if (widget.productImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.productImage!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 48),
                  ),
                )
              else
                const Icon(Icons.image, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.productTitle, 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Product ID: ${widget.productId}"),
                    Text("₹${widget.productPrice.toStringAsFixed(2)}", 
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Type your message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          isSending
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: () => sendMessage(_controller.text),
                ),
        ],
      ),
    );
  }
}