import 'package:flutter/material.dart';
import 'package:sells/screens/Feedback_Screen.dart';
import 'package:sells/services/database_service.dart';

// Dummy DatabaseService class for demonstration.
// Replace this with your actual DatabaseService implementation or import.
class DatabaseService {
  final String host;
  final int port;
  final String dbName;
  final String username;
  final String password;

  DatabaseService(this.host, this.port, this.dbName, this.username, this.password);

  Future<void> connect() async {
    // Dummy implementation for demonstration.
    // Replace with actual database connection logic.
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void close() {
    // Dummy implementation for demonstration.
    // Replace with actual database close logic.
  }

  Future<void> saveShippingDetails(Map<String, dynamic> details) async {
    // Dummy implementation for demonstration.
    // Replace with actual logic to save shipping details to your database.
    await Future.delayed(const Duration(milliseconds: 100));
  }

  saveFeedback(Map<String, dynamic> map) {}
}

class ShippingTrackingScreen extends StatefulWidget {
  const ShippingTrackingScreen({super.key});

  @override
  State<ShippingTrackingScreen> createState() => _ShippingTrackingScreenState();
}

class _ShippingTrackingScreenState extends State<ShippingTrackingScreen> {
  String selectedView = 'Seller';
  String? selectedCourier;

  final _trackingController = TextEditingController();
  final _shippingDateController = TextEditingController();
  final _deliveryDateController = TextEditingController();
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
        title: const Text("Shipping & Tracking"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildToggleButtons(),
            const SizedBox(height: 24),
            const Text("Enter Courier Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDropdown(),
            const SizedBox(height: 12),
            _buildTextField(_trackingController, "Enter tracking number"),
            const SizedBox(height: 12),
            _buildDateField("Shipping Date", _shippingDateController),
            const SizedBox(height: 12),
            _buildDateField("Estimated Delivery", _deliveryDateController),
            const SizedBox(height: 24),
            const Text("Package Photo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildUploadBox(),
            const SizedBox(height: 24),
           ElevatedButton(
              onPressed: () async {
                if (selectedCourier == null || 
                    _trackingController.text.isEmpty || 
                    _shippingDateController.text.isEmpty || 
                    _deliveryDateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  await _dbService.saveShippingDetails({
                    'offerId': (ModalRoute.of(context)?.settings.arguments as Map?)?['offerId'],
                    'courier': selectedCourier,
                    'trackingNumber': _trackingController.text,
                    'shippingDate': _shippingDateController.text,
                    'estimatedDelivery': _deliveryDateController.text,
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FeedbackScreen(),
                      settings: RouteSettings(arguments: {
                        'offerId': (ModalRoute.of(context)?.settings.arguments as Map?)?['offerId'],
                      }),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving shipping details: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Submit Details", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedView = 'Seller'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selectedView == 'Seller' ? Colors.blue : Colors.grey.shade200,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
              alignment: Alignment.center,
              child: Text("Seller View", style: TextStyle(color: selectedView == 'Seller' ? Colors.white : Colors.black)),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedView = 'Buyer'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selectedView == 'Buyer' ? Colors.blue : Colors.grey.shade200,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
              ),
              alignment: Alignment.center,
              child: Text("Buyer View", style: TextStyle(color: selectedView == 'Buyer' ? Colors.white : Colors.black)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Courier Service'),
      items: ['Speed Post', 'Delivery', 'BlueDart', 'DHL']
          .map((courier) => DropdownMenuItem(value: courier, child: Text(courier)))
          .toList(),
      onChanged: (value) {
        setState(() => selectedCourier = value);
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          firstDate: DateTime(2023),
          lastDate: DateTime(2030),
          initialDate: DateTime.now(),
        );
        if (pickedDate != null) {
          controller.text = "${pickedDate.year}/${pickedDate.month}/${pickedDate.day}";
        }
      },
    );
  }

  Widget _buildUploadBox() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text("Upload Package Photo"),
            Text("Photo will be shared with buyer", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
