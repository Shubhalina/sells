import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';


class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  /// Holds up to 8 image paths / URLs in the order they were selected
  final List<String> _imageUrls = [];

  String? _selectedCategory;
  bool _bestOffer = false;

  final List<String> _categories = const [
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
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_imageUrls.length >= 8) return;

    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    setState(() => _imageUrls.add(file.path));
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add a product')),
      );
      return;
    }

    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product photo')),
      );
      return;
    }

    final product = {
      'user_id': user.id,
      'product_title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'images': _imageUrls, // store as array column in Supabase
      'category': _selectedCategory,
      'price': double.parse(_priceController.text.trim()),
      'best_offer': _bestOffer,
    };

    try {
      final inserted = await Supabase.instance.client
          .from('products')
          .insert(product)
          .select()
          .single();

      debugPrint('Inserted product: $inserted');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    }
  }

  Widget _buildImagePlaceholder() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _pickImages,
      child: DottedBorder(
        color: theme.dividerColor,
        dashPattern: const [6, 4],
        strokeWidth: 1.5,
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        child: SizedBox(
          height: 160,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 36),
              const SizedBox(height: 8),
              const Text('Add up to 8 photos', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('First image will be the cover photo', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String path) => Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(path),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () => setState(() => _imageUrls.remove(path)),
              child: const Icon(Icons.close, size: 18, color: Colors.white),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('List Your Product'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: Text('Step 3 of 4', style: theme.textTheme.bodySmall),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      _imageUrls.isEmpty
                          ? _buildImagePlaceholder()
                          : Column(
                              children: [
                                // Cover photo is first image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_imageUrls.first),
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Thumbnails row
                                SizedBox(
                                  height: 80,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _imageUrls.length < 8
                                        ? _imageUrls.length + 1
                                        : 8,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      if (index < _imageUrls.length) {
                                        return _buildThumbnail(_imageUrls[index]);
                                      }
                                      // plus tile
                                      return GestureDetector(
                                        onTap: _pickImages,
                                        child: DottedBorder(
                                          color: theme.dividerColor,
                                          dashPattern: const [6, 4],
                                          strokeWidth: 1.2,
                                          borderType: BorderType.RRect,
                                          radius: const Radius.circular(8),
                                          child: SizedBox(
                                            width: 72,
                                            height: 72,
                                            child: const Center(child: Icon(Icons.add)),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Product Title',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 100,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Please enter product title' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        maxLength: 500,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                        validator: (value) => value == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Pricing',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter price';
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) return 'Please enter a valid price';
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Enable Best Offer',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          CupertinoSwitch(
                            value: _bestOffer,
                            onChanged: (val) => setState(() => _bestOffer = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _submit,
                  child: const Text('List Product'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
