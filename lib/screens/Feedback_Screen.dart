import 'package:flutter/material.dart';

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
        children: const [
          _OrderDetailRow(label: 'Order ID', value: '#123456789'),
          SizedBox(height: 8),
          _OrderDetailRow(label: 'Date', value: 'Jan 15, 2024'),
          SizedBox(height: 8),
          _OrderDetailRow(label: 'Amount', value: '\$125.00'),
        ],
      ),
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
        onPressed: () {
          // You can handle feedback submission here
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

class _OrderDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _OrderDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
