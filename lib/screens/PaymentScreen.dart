import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}


class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();

  String _selectedPaymentMethod = 'card';
  bool _savePaymentInfo = false;
  bool _isProcessing = false;

  // Payment method options
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'card',
      'title': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'subtitle': 'Visa, Mastercard, American Express',
    },
    {
      'id': 'paypal',
      'title': 'PayPal',
      'icon': Icons.account_balance_wallet,
      'subtitle': 'Pay with your PayPal account',
    },
    {
      'id': 'apple_pay',
      'title': 'Apple Pay',
      'icon': Icons.phone_iphone,
      'subtitle': 'Touch ID or Face ID',
    },
    {
      'id': 'google_pay',
      'title': 'Google Pay',
      'icon': Icons.android,
      'subtitle': 'Pay with Google',
    },
  ];

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isProcessing = true);

  try {
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Get the offer details from arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final offerId = args?['offerId'];

    // Here you would typically:
    // 1. Process the actual payment with your payment provider
    // 2. Update the offer status to 'purchased' in your database
    // For demo purposes, we'll just show the success dialog

    // Show success dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.green.shade600,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your payment has been processed successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            if (offerId != null) ...[
              const SizedBox(height: 8),
              Text(
                'Order ID: ${offerId.toString().substring(0, 8)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'You will receive a confirmation email shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed:₹$e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}
   @override
Widget build(BuildContext context) {
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  final offer = args?['offer'];
  final amount = args?['amount'] ?? 0;
  final productTitle = args?['productTitle'] ?? 'Unknown Product';
  final productImage = args?['productImage'];
  final productDescription = args?['productDescription'];
  final productCategory = args?['productCategory'];

  return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary Card
                    _buildOrderSummary(productTitle, productImage, amount, 
                        productDescription, productCategory),
                    const SizedBox(height: 24),

                    // Payment Method Selection
                    _buildSectionTitle('Payment Method'),
                    const SizedBox(height: 12),
                    ..._paymentMethods.map(_buildPaymentMethodTile),
                    const SizedBox(height: 24),

                    // Card Details (show only if card is selected)
                    if (_selectedPaymentMethod == 'card') ...[
                      _buildSectionTitle('Card Details'),
                      const SizedBox(height: 12),
                      _buildCardForm(),
                      const SizedBox(height: 24),
                    ],

                    // Billing Information
                    _buildSectionTitle('Billing Information'),
                    const SizedBox(height: 12),
                    _buildBillingForm(),
                    const SizedBox(height: 24),

                    // Save Payment Info
                    _buildSavePaymentOption(),
                  ],
                ),
              ),
            ),

            // Payment Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isProcessing
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                                'Pay ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildOrderSummary(
  String productTitle,
  String? productImage,
  int amount,
  String? productDescription,
  String? productCategory,
) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: productImage != null
                      ? Image.network(
                          productImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.grey.shade600,
                            size: 28,
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.grey.shade600,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (productCategory != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        productCategory,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Accepted Offer',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
              NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (productDescription != null) ...[
            const SizedBox(height: 12),
            Text(
              productDescription,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                'Pay ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPaymentMethodTile(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedPaymentMethod = method['id']),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isSelected ? Colors.blue : Colors.grey).shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    method['icon'],
                    color:
                        isSelected
                            ? Colors.blue.shade600
                            : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color:
                              isSelected
                                  ? Colors.blue.shade600
                                  : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        method['subtitle'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.credit_card),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            }
            if (value.length < 13) {
              return 'Card number must be at least 13 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length != 5) {
                    return 'Invalid format';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length < 3) {
                    return 'Invalid CVV';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name on Card',
            hintText: 'John Doe',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter name on card';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBillingForm() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'john@example.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter email address';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            hintText: '123 Main Street',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'New York',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _zipController,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code',
                  hintText: '10001',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSavePaymentOption() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: const Text(
          'Save payment information',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Securely save for faster checkout'),
        value: _savePaymentInfo,
        onChanged: (value) => setState(() => _savePaymentInfo = value),
        activeColor: Colors.blue.shade600,
      ),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length >= 3 && text[2] != '/') {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    }
    return newValue;
  }
}
