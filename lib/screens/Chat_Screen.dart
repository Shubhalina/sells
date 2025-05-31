import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatSupportScreen extends StatefulWidget {
  final String productId;
  final String productTitle;
  final double productPrice;
  final String? productImage;
  final String sellerId;
  final String sellerName;

  const ChatSupportScreen({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    this.productImage,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _controller = TextEditingController();
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    final response = await _supabase
        .from('chat_messages')
        .select()
        .eq('product_id', widget.productId)
        .eq('seller_id', widget.sellerId)
        .order('created_at')
        .execute();

    setState(() {
      messages = response.data as List<Map<String, dynamic>>;
      isLoading = false;
    });
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final msg = {
      'sender': 'user',
      'message': message.trim(),
      'product_id': widget.productId,
      'seller_id': widget.sellerId,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('chat_messages').insert(msg);

    _controller.clear();
    fetchMessages(); // Refresh
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
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg['sender'] == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            msg['message'],
                            style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
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
                    Text(widget.sellerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text("Online • Product Owner", style: TextStyle(color: Colors.green)),
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
              decoration: const InputDecoration(
                hintText: "Type your message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => sendMessage(_controller.text),
          ),
        ],
      ),
    );
  }
}