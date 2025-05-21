import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sells/screens/UserProfilePage.dart'; // adjust path as needed


class UserProfileScreen extends StatelessWidget {
  final user = Supabase.instance.client.auth.currentUser;

  @override
  Widget build(BuildContext context) {
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
                backgroundImage: AssetImage('assets/profile.jpg'),
              ),
              const SizedBox(height: 8),
              const Text('John Smith', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('john.smith@email.com', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () {}, child: const Text('Edit Profile')),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Total Sales', '\$1,245'),
                  _buildStat('Active Listings', '8'),
                  _buildStat('Reviews', '4.8 ⭐'),
                ],
              ),
              const SizedBox(height: 20),
              _buildNavBar(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(Icons.add, 'Add New Listing'),
                  _buildQuickAction(Icons.bar_chart, 'View Analytics'),
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
              _buildActivity('New Order Received', 'Order #12345 - Smart Watch', '2 hours ago'),
              _buildActivity('Payment Completed', 'Transaction ID: 987654', '5 hours ago'),
              _buildActivity('Listing Updated', 'Wireless Headphones - Price Changed', '1 day ago'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String title, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildNavBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavIcon(Icons.list, 'My Listings'),
        _buildNavIcon(Icons.history, 'Purchase History'),
        _buildNavIcon(Icons.payment, 'Payment Methods'),
        _buildNavIcon(Icons.settings, 'Settings'),
        _buildNavIcon(Icons.logout, 'Logout'),
      ],
    );
  }

  Widget _buildNavIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12))
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
        Text(label, style: const TextStyle(fontSize: 12))
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _buildListings() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildListingCard('Smart Watch', '\$299', 'assets/watch.jpg', true),
        _buildListingCard('Wireless Headphones', '\$199', 'assets/headphones.jpg', true),
        _buildListingCard('Camera Lens', '\$499', 'assets/camera.jpg', false),
        _buildListingCard('Sunglasses', '\$129', 'assets/sunglasses.jpg', true),
      ],
    );
  }

  Widget _buildListingCard(String title, String price, String imgPath, bool isActive) {
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
            child: Image.asset(imgPath, height: 100, width: double.infinity, fit: BoxFit.cover),
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
              child: Text(isActive ? 'Active' : 'Sold', style: const TextStyle(fontSize: 10)),
            ),
          )
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
