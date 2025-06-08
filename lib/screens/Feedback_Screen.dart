import 'package:flutter/material.dart';
import 'ShippingTracking_Screen.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int rating = 0;
  final TextEditingController feedbackController = TextEditingController();

  void setRating(int value) {
    setState(() {
      rating = value;
    });
  }
  final DatabaseService _dbService = DatabaseService(
  'your-db-host', 
  5432, 
  'your-db-name', 
  'your-username', 
  'your-password'
);

@override
void initState() {
  super.initState();
  _initializeDatabase();
}

Future<void> _initializeDatabase() async {
  await _dbService.connect();
}

@override
void dispose() {
  _dbService.close();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Experience'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderDetails(),
            const SizedBox(height: 24),
            const Text("How was your experience?", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            _buildStarRating(),
            const Center(child: Text("Tap to rate", style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 24),
            const Text("Share your thoughts", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            _buildFeedbackField(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _orderDetailRow(label: 'Order ID', value: '#123456789'),
          const SizedBox(height: 8),
          _orderDetailRow(label: 'Date', value: 'Jan 15, 2024'),
          const SizedBox(height: 8),
          _orderDetailRow(label: 'Amount', value: '\$125.00'),
        ],
      ),
    );
  }

  Widget _orderDetailRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w400)),
      ],
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          onPressed: () => setRating(index + 1),
          icon: Icon(
            Icons.star,
            size: 32,
            color: index < rating ? Colors.amber : Colors.grey.shade400,
          ),
        );
      }),
    );
  }

  Widget _buildFeedbackField() {
    return TextFormField(
      controller: feedbackController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Tell us about your experience (optional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        fillColor: Colors.grey.shade100,
        filled: true,
      ),
    );
  }

 Widget _buildSubmitButton() {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () async {
        if (rating == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please provide a rating')),
          );
          return;
        }

        try {
          await _dbService.saveFeedback({
            'offerId': (ModalRoute.of(context)?.settings.arguments as Map?)?['offerId'],
            'rating': rating,
            'comments': feedbackController.text,
          });

          Navigator.of(context).popUntil((route) => route.isFirst);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting feedback: $e')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text("Submit Feedback", style: TextStyle(fontSize: 16)),
    ),
  );
}

}