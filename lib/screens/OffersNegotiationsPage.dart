import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class OffersNegotiationsPage extends StatefulWidget {
  const OffersNegotiationsPage({super.key});

  @override
  State<OffersNegotiationsPage> createState() => _OffersNegotiationsPageState();
}

class _OffersNegotiationsPageState extends State<OffersNegotiationsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _offers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    try {
      // Fetch offers with product details using JOIN
      final rows = await supabase
          .from('offers')
          .select('''
            offer_id,
            product_id,
            user_id,
            offer_price,
            status,
            message,
            date_time,
            products (
              id,
              product_title,
              product_image,
              description,
              category,
              price
            )
          ''')
          .order('date_time', ascending: false);

      final fetched = List<Map<String, dynamic>>.from(rows);

      // If no data from database, use demo data
      if (fetched.isEmpty) {
        fetched.addAll(_demoOffers());
      }

      setState(() {
        _offers = fetched;
        _loading = false;
      });
    } catch (e) {
      // Fallback to demo data if there's an error
      setState(() {
        _offers = _demoOffers();
        _loading = false;
        _error = null; // Don't show error, just use demo data
      });
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await supabase
          .from('offers')
          .update({'status': newStatus})
          .eq('offer_id', id);
      await _fetchOffers();

      if (!mounted) return;
      String message =
          newStatus == 'accepted'
              ? 'Offer accepted successfully!'
              : 'Offer declined';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: newStatus == 'accepted' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _counterOffer(Map<String, dynamic> offer) async {
    final controller = TextEditingController();
    final currentPrice =
        offer['offer_price'] ?? offer['products']?['price'] ?? 100000;

    // Show dialog to enter counter offer
    final result = await showDialog<double>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Counter Offer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current offer: ${NumberFormat.simpleCurrency().format(currentPrice)}',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Your counter offer',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final price = double.tryParse(controller.text);
                  if (price != null && price > 0) {
                    Navigator.pop(context, price);
                  }
                },
                child: const Text('Send Counter'),
              ),
            ],
          ),
    );

    if (result != null) {
      try {
        await supabase.from('offers').insert({
          'offer_id': 'counter_${DateTime.now().millisecondsSinceEpoch}',
          'product_id': offer['product_id'],
          'user_id': offer['user_id'],
          'offer_price': result.round(),
          'date_time': DateTime.now().toIso8601String(),
          'status': 'pending',
          'message': 'Counter offer',
        });

        // Update original offer status
        await _updateStatus(offer['offer_id'], 'countered');
        await _fetchOffers();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Counter offer sent successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending counter offer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _buyNow(Map<String, dynamic> offer) async {
    try {
      // Navigate to payment screen with offer details
      Navigator.pushNamed(
        context,
        '/payment',
        arguments: {
          'offer': offer,
          'amount': offer['offer_price'],
          'productTitle':
              offer['products']?['product_title'] ?? 'Unknown Product',
          'productImage': offer['products']?['product_image'],
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating to payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _active =>
      _offers.where((e) => e['status'] == 'pending').toList();

  List<Map<String, dynamic>> get _previous =>
      _offers.where((e) => e['status'] != 'pending').toList();

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'countered':
        return Colors.orange;
      case 'purchased':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _offerCard(Map<String, dynamic> offer) {
    final product = offer['products'];
    final offerPrice = offer['offer_price'];
    final currency = NumberFormat.simpleCurrency().format(offerPrice);
    final received = timeago.format(DateTime.parse(offer['date_time']));
    final status = offer['status'] as String;

    // Get product details
    final productTitle = product?['product_title'] ?? 'Unknown Product';
    final productImage = product?['product_image'];
    final category = product?['category'] ?? 'General';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        productImage != null
                            ? Image.network(
                              productImage,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => _defaultProductImage(),
                            )
                            : _defaultProductImage(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              currency,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Received $received',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _actionBtn(
                    label: 'Accept',
                    color: Colors.green.shade600,
                    onTap: () => _updateStatus(offer['offer_id'], 'accepted'),
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    label: 'Counter',
                    color: Colors.blue.shade600,
                    onTap: () => _counterOffer(offer),
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    label: 'Decline',
                    color: Colors.grey.shade600,
                    onTap: () => _updateStatus(offer['offer_id'], 'declined'),
                  ),
                ],
              ),
            ] else if (status == 'accepted') ...[
              const SizedBox(height: 16),
              // Buy Now button for accepted offers
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => _buyNow(offer),
                  icon: const Icon(Icons.shopping_cart_rounded, size: 20),
                  label: const Text(
                    'Buy Now',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Offer accepted! Ready for purchase.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (status == 'purchased') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.purple.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Purchase completed successfully!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to order details/receipt
                      },
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _defaultProductImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        color: Colors.grey.shade600,
        size: 28,
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => Expanded(
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
  );

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    ),
  );

  List<Map<String, dynamic>> _demoOffers() => [
    {
      'offer_id': '1',
      'product_id': 1,
      'user_id': 'demo-user',
      'offer_price': 130000,
      'date_time':
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'status': 'pending',
      'message': 'Initial offer',
      'products': {
        'id': 1,
        'product_title': 'Senior Software Engineer',
        'product_image': null,
        'description': 'Full-time position at TechCorp Inc.',
        'category': 'Technology',
        'price': 120000,
      },
    },
    {
      'offer_id': '2',
      'product_id': 2,
      'user_id': 'demo-user',
      'offer_price': 115000,
      'date_time':
          DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      'status': 'pending',
      'message': 'Initial offer',
      'products': {
        'id': 2,
        'product_title': 'Full Stack Developer',
        'product_image': null,
        'description': 'Remote position at InnovateLabs',
        'category': 'Technology',
        'price': 110000,
      },
    },
    {
      'offer_id': '3',
      'product_id': 3,
      'user_id': 'demo-user',
      'offer_price': 105000,
      'date_time':
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'status': 'pending',
      'message': 'Initial offer',
      'products': {
        'id': 3,
        'product_title': 'Frontend Engineer',
        'product_image': null,
        'description': 'Hybrid position at Future Systems',
        'category': 'Technology',
        'price': 100000,
      },
    },
    {
      'offer_id': '4',
      'product_id': 4,
      'user_id': 'demo-user',
      'offer_price': 95000,
      'date_time':
          DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'status': 'accepted',
      'message': 'Initial offer',
      'products': {
        'id': 4,
        'product_title': 'Software Engineer',
        'product_image': null,
        'description': 'Full-time at Tech Solutions',
        'category': 'Technology',
        'price': 90000,
      },
    },
    {
      'offer_id': '5',
      'product_id': 5,
      'user_id': 'demo-user',
      'offer_price': 85000,
      'date_time':
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      'status': 'declined',
      'message': 'Initial offer',
      'products': {
        'id': 5,
        'product_title': 'Frontend Developer',
        'product_image': null,
        'description': 'Remote at Digital Dynamics',
        'category': 'Technology',
        'price': 80000,
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Offers & Negotiations',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement filter functionality
            },
            icon: const Icon(Icons.tune_rounded, color: Colors.black87),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchOffers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _offers.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No offers yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your offers will appear here',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        if (_active.isNotEmpty) ...[
                          _sectionHeader('Active Offers (${_active.length})'),
                          ..._active.map(_offerCard),
                        ],
                        if (_previous.isNotEmpty) ...[
                          _sectionHeader(
                            'Previous Offers (${_previous.length})',
                          ),
                          ..._previous.map(_offerCard),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Navigate to create new counter offer page
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'New Counter Offer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
