import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class OffersNegotiationsPage extends StatefulWidget {
  final String productId;

  const OffersNegotiationsPage({super.key, required this.productId});

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
      final offersData = await supabase
          .from('offers')
          .select('*')
          .eq('product_id', widget.productId) // FILTER BY product_id
          .order('date_time', ascending: false);

      // Fetch product details for the productId (optional if you want to show product info)
      final productsData = await supabase
          .from('products')
          .select('*')
          .eq('product_id', widget.productId)
          .single();

      final enrichedOffers = List<Map<String, dynamic>>.from(offersData).map((offer) {
        return {
          ...offer,
          'product_title': productsData['title'] ?? 'Unknown Product',
          'product_image': productsData['image_url'] ?? 'https://via.placeholder.com/150',
          'product_price': productsData['price'] ?? 0,
        };
      }).toList();

      setState(() {
        _offers = enrichedOffers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    await supabase
        .from('offers')
        .update({'status': newStatus})
        .eq('offer_id', id);
    await _fetchOffers();
  }

  List<Map<String, dynamic>> get _active =>
      _offers.where((e) => e['status'] == 'pending').toList();
  List<Map<String, dynamic>> get _previous =>
      _offers.where((e) => e['status'] != 'pending').toList();

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
    final currency = NumberFormat.simpleCurrency().format(offer['offer_price']);
    final received = timeago.format(DateTime.parse(offer['date_time']));
    final status = offer['status'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    offer['product_image'],
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(Icons.storefront, color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer['product_title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        offer['message'] ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currency,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Received $received',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _actionBtn(
                    label: 'Accept',
                    color: Colors.green,
                    onTap: () => _updateStatus(offer['offer_id'], 'accepted'),
                  ),
                  _actionBtn(
                    label: 'Counter',
                    color: Colors.blue,
                    onTap: () => _counterOffer(offer),
                  ),
                  _actionBtn(
                    label: 'Decline',
                    color: Colors.grey.shade800,
                    onTap: () => _updateStatus(offer['offer_id'], 'declined'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onTap,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ),
      );

  Future<void> _counterOffer(Map<String, dynamic> offer) async {
    final newPrice =
        (offer['offer_price'] * (1 + Random().nextInt(10) / 100)).round();

    await supabase.from('offers').insert({
      'offer_id': UniqueKey().toString(),
      'product_id': widget.productId,
      'offer_price': newPrice,
      'date_time': DateTime.now().toIso8601String(),
      'status': 'pending',
      'message': 'Counter offer',
    });
    await _fetchOffers();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Counter offer sent')));
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers & Negotiations'),
        leading: const BackButton(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _fetchOffers,
                  child: ListView(
                    children: [
                      _sectionHeader('Active Offers'),
                      if (_active.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('No active offers'),
                        )
                      else
                        ..._active.map(_offerCard).toList(),
                      _sectionHeader('Previous Offers'),
                      if (_previous.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('No previous offers'),
                        )
                      else
                        ..._previous.map(_offerCard).toList(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}
