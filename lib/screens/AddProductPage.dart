import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategory;
  bool _bestOffer = false;

  final List<String> _categories = [
    'Electronics',
    'Fashion',
    'Home',
    'Accessories',
    'Books',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to add a product'),
          ),
        );
        return;
      }

      final product = {
        'user_id': user.id,
        'product_title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'product_image': _imageController.text.trim(),
        'category': _selectedCategory,
        'price': double.parse(_priceController.text.trim()),
        'best_offer': _bestOffer,
      };

      try {
        // Insert the product and retrieve the inserted row (optional)
        final inserted =
            await Supabase.instance.client
                .from('products')
                .insert(product)
                .select()
                .single();

        debugPrint('Inserted product: $inserted');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add product: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Product Title',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter product title'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: 'Product Image URL/Path',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter image path or URL'
                            : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categories',
                  border: OutlineInputBorder(),
                ),
                items:
                    _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator:
                    (value) =>
                        value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter price';
                  final price = double.tryParse(value);
                  if (price == null || price <= 0)
                    return 'Please enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Best Offer Available'),
                value: _bestOffer,
                onChanged: (val) => setState(() => _bestOffer = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
