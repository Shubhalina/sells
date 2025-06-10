import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class LocationSuggestion {
  final String displayName;
  final String shortName;
  final double lat;
  final double lon;
  final String type;
  final String? state;
  final String? city;

  LocationSuggestion({
    required this.displayName,
    required this.shortName,
    required this.lat,
    required this.lon,
    required this.type,
    this.state,
    this.city,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    final addressMap = json['address'] as Map<String, dynamic>? ?? {};
    
    return LocationSuggestion(
      displayName: json['display_name'] ?? '',
      shortName: _buildShortName(addressMap),
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lon: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      type: json['type'] ?? 'location',
      state: addressMap['state'] ?? addressMap['state_district'],
      city: addressMap['city'] ?? addressMap['town'] ?? addressMap['village'],
    );
  }

  static String _buildShortName(Map<String, dynamic> address) {
    List<String> parts = [];
    
    final city = address['city'] ?? address['town'] ?? address['village'];
    final state = address['state'] ?? address['state_district'];
    final country = address['country'];
    
    if (city != null) parts.add(city);
    if (state != null) parts.add(state);
    if (country != null) parts.add(country);
    
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
  }
}

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
  final _addressController = TextEditingController();

  String? _selectedCategory;
  bool _bestOffer = false;
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imageDataList = [];
  final picker = ImagePicker();

  Position? _currentPosition;
  String? _currentAddress;
  bool _isGettingLocation = false;

  // Location autocomplete variables
  List<LocationSuggestion> _locationSuggestions = [];
  bool _isSearchingLocation = false;
  bool _showSuggestions = false;
  String? _selectedState;
  String? _selectedCity;

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
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Location autocomplete using Nominatim API
  Future<void> _searchLocation(String query) async {
    if (query.length < 3) {
      setState(() {
        _locationSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearchingLocation = true;
    });

    try {
      // Using Nominatim API for location search
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&limit=5&q=$query'
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'YourAppName/1.0', // Replace with your app name
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final suggestions = data
            .map((item) => LocationSuggestion.fromJson(item))
            .toList();

        setState(() {
          _locationSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error searching location: $e');
    } finally {
      setState(() {
        _isSearchingLocation = false;
      });
    }
  }

  void _selectLocationSuggestion(LocationSuggestion suggestion) {
    setState(() {
      _addressController.text = suggestion.shortName;
      _showSuggestions = false;
      _selectedState = suggestion.state;
      _selectedCity = suggestion.city;
      _currentPosition = Position(
        latitude: suggestion.lat,
        longitude: suggestion.lon,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    });
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 8) return;

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageData = await pickedFile.readAsBytes();
      setState(() {
        _selectedImages.add(pickedFile);
        _imageDataList.add(imageData);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services in your device settings.');
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Please grant location permission to use this feature.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable location permission in app settings.');
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Validate position
      if (position.latitude == 0.0 && position.longitude == 0.0) {
        throw Exception('Invalid location coordinates received. Please try again.');
      }

      // Get address from coordinates using reverse geocoding with Nominatim
      String address = 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      String? state;
      String? city;
      
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}'
        );

        final response = await http.get(
          url,
          headers: {
            'User-Agent': 'YourAppName/1.0', // Replace with your app name
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final addressMap = data['address'] as Map<String, dynamic>? ?? {};
          
          List<String> addressParts = [];
          
          city = addressMap['city'] ?? addressMap['town'] ?? addressMap['village'];
          state = addressMap['state'] ?? addressMap['state_district'];
          final country = addressMap['country'];
          
          if (city != null) addressParts.add(city);
          if (state != null) addressParts.add(state);
          if (country != null) addressParts.add(country);
          
          if (addressParts.isNotEmpty) {
            address = addressParts.join(', ');
          }
        }
      } catch (e) {
        print('Reverse geocoding failed: $e');
      }

      setState(() {
        _currentPosition = position;
        _currentAddress = address;
        _addressController.text = address;
        _selectedState = state;
        _selectedCity = city;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location obtained successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields and upload at least one image'),
        ),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to add a product'),
        ),
      );
      return;
    }

    try {
      // Upload images to Supabase Storage
      List<String> imageUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        final imageBytes = _imageDataList[i];
        final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}_${i}_${path.basename(image.path)}';

        await Supabase.instance.client.storage.from('product-images').uploadBinary(
          fileName,
          imageBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

        final imageUrl = Supabase.instance.client.storage.from('product-images').getPublicUrl(fileName);
        imageUrls.add(imageUrl);
      }

      final product = {
        'user_id': user.id,
        'product_title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'product_image': imageUrls.isNotEmpty ? imageUrls[0] : '',
        'image_urls': imageUrls,
        'category': _selectedCategory,
        'price': double.parse(_priceController.text.trim()),
        'best_offer': _bestOffer,
        'best_offer_enabled': _bestOffer,
        'status': 'active',
        'address': _addressController.text.trim(),
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'state': _selectedState,
        'city': _selectedCity,
      };

      await Supabase.instance.client
          .from('products')
          .insert(product)
          .select()
          .single();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Product Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter product title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter price';
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) return 'Enter valid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (value) =>
                    value == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _bestOffer,
                    onChanged: (val) =>
                        setState(() => _bestOffer = val ?? false),
                  ),
                  const Text('Best Offer'),
                ],
              ),
              const SizedBox(height: 12),
              // Location field with autocomplete
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      helperText: 'Search for location or tap GPS icon to get current location',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSearchingLocation)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          IconButton(
                            icon: _isGettingLocation 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location),
                            onPressed: _isGettingLocation ? null : _getCurrentLocation,
                            tooltip: 'Get current location',
                          ),
                        ],
                      ),
                    ),
                    onChanged: (value) {
                      _searchLocation(value);
                    },
                    onTap: () {
                      if (_addressController.text.length >= 3) {
                        setState(() {
                          _showSuggestions = _locationSuggestions.isNotEmpty;
                        });
                      }
                    },
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter address' : null,
                  ),
                  // Location suggestions dropdown
                  if (_showSuggestions && _locationSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _locationSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _locationSuggestions[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on, size: 20),
                            title: Text(
                              suggestion.shortName,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              suggestion.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectLocationSuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_currentPosition != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'Product Images (Required)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._imageDataList
                      .asMap()
                      .entries
                      .map((entry) => Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  entry.value,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(entry.key);
                                    _imageDataList.removeAt(entry.key);
                                  });
                                },
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                  if (_selectedImages.length < 8)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.grey),
                            Text('Add', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                '${_selectedImages.length}/8 images selected',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Add Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}