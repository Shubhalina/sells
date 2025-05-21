import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/images/usericon.png'),
              ),
              const SizedBox(height: 8),
              Text(
                user?.userMetadata?['full_name'] ?? 'User',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user?.email ?? 'email@example.com',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // Edit profile action
                },
                child: const Text('Edit Profile'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Total Sales', '\$1,245'),
                  _buildStat('Listings', '8'),
                  _buildStat('Reviews', '4.8 ⭐'),
                ],
              ),
              const SizedBox(height: 20),
              _buildNavBar(context),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(Icons.add, 'Add Listing'),
                  _buildQuickAction(Icons.bar_chart, 'Analytics'),
                  _buildQuickAction(Icons.support_agent, 'Support'),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Active Listings'),
              const SizedBox(height: 10),
              _buildListings(),
              const SizedBox(height: 20),
              _buildSectionTitle('Recent Activity'),
              const SizedBox(height: 10),
              _buildActivity(
                'New Order',
                'Order #12345 - Smart Watch',
                '2h ago',
              ),
              _buildActivity('Payment', 'Txn ID: 987654', '5h ago'),
              _buildActivity(
                'Listing Updated',
                'Headphones price updated',
                '1d ago',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavIcon(Icons.list, 'My Listings'),
        _buildNavIcon(Icons.history, 'History'),
        _buildNavIcon(Icons.payment, 'Payments'),
        _buildNavIcon(Icons.settings, 'Settings'),
        GestureDetector(
          onTap: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            }
          },
          child: _buildNavIcon(Icons.logout, 'Logout'),
        ),
      ],
    );
  }

  Widget _buildNavIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildListings() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildListingCard('Smart Watch', '\$299', 'assets/watch.jpg', true),
        _buildListingCard('Headphones', '\$199', 'assets/headphones.jpg', true),
        _buildListingCard('Camera Lens', '\$499', 'assets/camera.jpg', false),
        _buildListingCard('Sunglasses', '\$129', 'assets/sunglasses.jpg', true),
      ],
    );
  }

  Widget _buildListingCard(
    String title,
    String price,
    String imgPath,
    bool isActive,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imgPath,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(price, style: const TextStyle(color: Colors.blue)),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade100 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Active' : 'Sold',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivity(String title, String subtitle, String timeAgo) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Text(timeAgo, style: const TextStyle(color: Colors.grey)),
    );
  }
}
