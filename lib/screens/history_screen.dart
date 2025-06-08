import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: HistoryPage()));
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {}, // Add back navigation
          ),
          title: const Text('History', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.black,
            indicatorColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'All Activity'),
              Tab(text: 'Purchases'),
              Tab(text: 'Saved Items'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AllActivityTab(),
            Center(child: Text('Purchases Tab')),
            Center(child: Text('Saved Items Tab')),
          ],
        ),
      ),
    );
  }
}

class AllActivityTab extends StatelessWidget {
  const AllActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final todayItems = [
      HistoryItem(
        image: 'https://via.placeholder.com/150/FF0000', // Replace with actual image
        title: 'Nike Air Max 270',
        subtitle: 'Purchase completed',
        price: '\$129.99',
        time: '2:30 PM',
        statusColor: Colors.green,
      ),
      HistoryItem(
        image: 'https://via.placeholder.com/150/0000FF', // Replace
        title: 'Vintage Denim Jacket',
        subtitle: 'Saved to wishlist',
        price: '\$45.00',
        time: '11:20 AM',
        statusColor: Colors.grey,
      ),
    ];

    final yesterdayItems = [
      HistoryItem(
        image: 'https://via.placeholder.com/150/FFFFFF', // Replace
        title: 'Adidas Ultra Boost',
        subtitle: 'Viewed item',
        price: '\$159.99',
        time: '4:45 PM',
        statusColor: Colors.grey,
      ),
      HistoryItem(
        image: 'https://via.placeholder.com/150/ADD8E6', // Replace
        title: 'Supreme T-Shirt',
        subtitle: 'Purchase completed',
        price: '\$89.99',
        time: '2:15 PM',
        statusColor: Colors.green,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...todayItems.map((item) => HistoryTile(item: item)).toList(),
        const SizedBox(height: 16),
        const Text('Yesterday', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...yesterdayItems.map((item) => HistoryTile(item: item)).toList(),
      ],
    );
  }
}

class HistoryItem {
  final String image;
  final String title;
  final String subtitle;
  final String price;
  final String time;
  final Color statusColor;

  HistoryItem({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.time,
    required this.statusColor,
  });
}

class HistoryTile extends StatelessWidget {
  final HistoryItem item;

  const HistoryTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(item.image, width: 50, height: 50, fit: BoxFit.cover),
      ),
      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(item.subtitle, style: TextStyle(color: item.statusColor)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(item.price, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(item.time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
