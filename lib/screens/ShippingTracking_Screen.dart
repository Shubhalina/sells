import 'package:flutter/material.dart';

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
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Submit Details", style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.help_outline),
              label: const Text("Need Help?"),
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
      items: ['Speed Post', 'Delhivery', 'BlueDart', 'DHL']
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
