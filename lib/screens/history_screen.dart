// import 'package:flutter/material.dart';
// import '../services/history_service.dart';

// class HistoryPage extends StatelessWidget {
//   final HistoryService _historyService = HistoryService();

//   HistoryPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.black),
//             onPressed: () => Navigator.pop(context),
//           ),
//           title: const Text('History', style: TextStyle(color: Colors.black)),
//           centerTitle: true,
//           bottom: const TabBar(
//             labelColor: Colors.black,
//             indicatorColor: Colors.black,
//             unselectedLabelColor: Colors.grey,
//             tabs: [
//               Tab(text: 'All Activity'),
//               Tab(text: 'Purchases'),
//               Tab(text: 'Saved Items'),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             _ActivityTab(fetchData: _historyService.fetchAllActivities),
//             _ActivityTab(fetchData: _historyService.fetchPurchases),
//             _ActivityTab(fetchData: _historyService.fetchSavedItems),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ActivityTab extends StatelessWidget {
//   final Future<List<Map<String, dynamic>>> Function() fetchData;

//   const _ActivityTab({required this.fetchData});

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<Map<String, dynamic>>>(
//       future: fetchData(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         final items = snapshot.data ?? [];

//         if (items.isEmpty) {
//           return const Center(child: Text('No activities found'));
//         }

//         return ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: items.length,
//           itemBuilder: (context, index) {
//             final activity = items[index];
//             final product = activity['products'] as Map<String, dynamic>;
            
//             return HistoryTile(
//               item: HistoryItem(
//                 image: product['image_url'] ?? 'https://via.placeholder.com/150',
//                 title: product['name'] ?? 'Unknown Product',
//                 subtitle: _getSubtitle(activity['activity_type']),
//                 price: '\₹${product['price']?.toStringAsFixed(2) ?? '0.00'}',
//                 time: _formatTime(activity['created_at']),
//                 statusColor: activity['status'] == 'completed' 
//                   ? Colors.green 
//                   : Colors.grey,
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   String _getSubtitle(String activityType) {
//     switch (activityType) {
//       case 'purchase': return 'Purchase completed';
//       case 'saved': return 'Saved to wishlist';
//       case 'viewed': return 'Viewed item';
//       default: return 'Activity';
//     }
//   }

//   String _formatTime(String timestamp) {
//     final dateTime = DateTime.parse(timestamp).toLocal();
//     return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour < 12 ? 'AM' : 'PM'}';
//   }
// }


// class HistoryItem {
//   final String image;
//   final String title;
//   final String subtitle;
//   final String price;
//   final String time;
//   final Color statusColor;

//   HistoryItem({
//     required this.image,
//     required this.title,
//     required this.subtitle,
//     required this.price,
//     required this.time,
//     required this.statusColor,
//   });
// }

// class HistoryTile extends StatelessWidget {
//   final HistoryItem item;

//   const HistoryTile({super.key, required this.item});

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       contentPadding: const EdgeInsets.symmetric(vertical: 4),
//       leading: ClipRRect(
//         borderRadius: BorderRadius.circular(8),
//         child: Image.network(item.image, width: 50, height: 50, fit: BoxFit.cover),
//       ),
//       title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
//       subtitle: Text(item.subtitle, style: TextStyle(color: item.statusColor)),
//       trailing: Column(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           Text(item.price, style: const TextStyle(fontWeight: FontWeight.w500)),
//           Text(item.time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//         ],
//       ),
//     );
//   }
// }
