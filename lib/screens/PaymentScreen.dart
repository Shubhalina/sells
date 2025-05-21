import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum PaymentMethod { upi, cod }

class PaymentScreen extends StatefulWidget {
  /// Pass the prices from previous screen
  final double subtotal;
  final double deliveryFee;
  final double tax;

  const PaymentScreen({
    Key? key,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late double _total;
  PaymentMethod _selectedMethod = PaymentMethod.upi;

  @override
  void initState() {
    super.initState();
    _total = widget.subtotal + widget.deliveryFee + widget.tax;
  }

  Future<void> _confirmPayment() async {
    final supabase = Supabase.instance.client;

    try {
      // Insert a new order/payment record (adjust the table & columns to match your schema)
      await supabase.from('payments').insert({
        'user_id': supabase.auth.currentUser!.id,
        'amount': _total,
        'method': _selectedMethod.name,
        'status': _selectedMethod == PaymentMethod.cod ? 'pending' : 'paid',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful ✅')),
      );
      Navigator.pop(context, true); // return success flag
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildPaymentTile({
    required IconData icon,
    required String label,
    required PaymentMethod method,
  }) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300, width: 1.2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade50,
              child: Icon(icon, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        centerTitle: true,
        title: const Text('Payment'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildPaymentTile(icon: Icons.account_balance_wallet_rounded, label: 'UPI Payment', method: PaymentMethod.upi),
              _buildPaymentTile(icon: Icons.local_shipping_rounded, label: 'Cash on Delivery', method: PaymentMethod.cod),
              const SizedBox(height: 24),
              const Text('Fee Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildPriceRow('Subtotal', '\$${widget.subtotal.toStringAsFixed(2)}'),
              _buildPriceRow('Delivery Fee', '\$${widget.deliveryFee.toStringAsFixed(2)}'),
              _buildPriceRow('Tax', '\$${widget.tax.toStringAsFixed(2)}'),
              const Divider(height: 30),
              _buildPriceRow('Total', '\$${_total.toStringAsFixed(2)}', isBold: true),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _confirmPayment,
                  child: Text('Confirm Payment • \$${_total.toStringAsFixed(2)}'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
