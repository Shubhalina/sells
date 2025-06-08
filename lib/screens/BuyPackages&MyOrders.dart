// buy_packages_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'buypackages_screen.dart';

class BuyPackagesOrdersScreen extends StatelessWidget {
  const BuyPackagesOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Packages & My Orders'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMenuCard(
              context,
              title: 'Buy packages',
              subtitle: 'Sell faster, more & higher margins with packages',
              icon: Icons.shopping_bag_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BuyPackagesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'My Orders',
              subtitle: 'Active, scheduled and expired orders',
              icon: Icons.list_alt_outlined,
              onTap: () {
                // Navigate to My Orders screen
              },
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'Invoices',
              subtitle: 'See and download your invoices',
              icon: Icons.receipt_long_outlined,
              onTap: () {
                // Navigate to Invoices screen
              },
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'Billing information',
              subtitle: 'Edit your billing name, address, etc.',
              icon: Icons.credit_card_outlined,
              onTap: () {
                // Navigate to Billing information screen
              },
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'View Cart',
              subtitle: 'Check out the items in your cart to purchase',
              icon: Icons.shopping_cart_outlined,
              onTap: () {
                // Navigate to Cart screen
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}