import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'product_details.dart'; // Import the product details page

// LocationSuggestion class for location autocomplete
class LocationSuggestion {
  final String shortName;
  final String displayName;
  final String? state;
  final String? city;

  LocationSuggestion({
    required this.shortName,
    required this.displayName,
    this.state,
    this.city,
  });
}

class BuyPackagesScreen extends StatefulWidget {
  const BuyPackagesScreen({super.key});

  @override
  State<BuyPackagesScreen> createState() => _BuyPackagesScreenState();
}

class _BuyPackagesScreenState extends State<BuyPackagesScreen> {
  final _locationController = TextEditingController();
  
  List<String> categories = [];
  bool _isLoadingCategories = false;
  String? _selectedCategory;
  
  // Location autocomplete variables
  List<LocationSuggestion> _locationSuggestions = [];
  bool _isSearchingLocation = false;
  bool _showLocationSuggestions = false;
  String? _selectedState;
  String? _selectedCity;
  bool _isGettingLocation = false;
  bool _isLoadingProducts = false;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('name')
          .order('name', ascending: true);

      if (response != null) {
        setState(() {
          categories = List<String>.from(response.map((item) => item['name'] as String));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  // Method to get the current location and update the location controller
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode the coordinates to get address details
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&addressdetails=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'FlutterApp'
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};
        final displayName = data['display_name'] ?? '';
        final state = address['state'];
        final city = address['city'] ?? address['town'] ?? address['village'];

        setState(() {
          _locationController.text = displayName;
          _selectedState = state;
          _selectedCity = city;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get address from location')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  // ... (keep all the location related methods as is: _searchLocation, _selectLocationSuggestion, _getCurrentLocation)

  // Method to search for location suggestions based on user input
  Future<void> _searchLocation(String query) async {
    if (query.length < 3) {
      setState(() {
        _locationSuggestions = [];
        _showLocationSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearchingLocation = true;
    });

    try {
      // Example API call to Nominatim for location suggestions
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=10');
      final response = await http.get(url, headers: {
        'User-Agent': 'FlutterApp'
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final suggestions = data.map((item) {
          final address = item['address'] ?? {};
          return LocationSuggestion(
            shortName: item['display_name']?.split(',')?.first ?? '',
            displayName: item['display_name'] ?? '',
            state: address['state'],
            city: address['city'] ?? address['town'] ?? address['village'],
          );
        }).toList();

        setState(() {
          _locationSuggestions = List<LocationSuggestion>.from(suggestions);
          _showLocationSuggestions = _locationSuggestions.isNotEmpty;
        });
      } else {
        setState(() {
          _locationSuggestions = [];
          _showLocationSuggestions = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationSuggestions = [];
        _showLocationSuggestions = false;
      });
    } finally {
      setState(() {
        _isSearchingLocation = false;
      });
    }
  }

  Future<void> _showPackages() async {
    if (_selectedCategory == null || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and location')),
      );
      return;
    }

    setState(() {
      _isLoadingProducts = true;
    });

    try {
      // Query products based on selected category and location (city or state)
      final query = Supabase.instance.client
          .from('products')
          .select()
          .eq('category', _selectedCategory)
          .eq('status', 'active');

      // Add location filters if available
      if (_selectedCity != null) {
        query.ilike('city', '%$_selectedCity%');
      } else if (_selectedState != null) {
        query.ilike('state', '%$_selectedState%');
      }

      final response = await query;

      if (response != null) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response);
        });

        if (_products.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No products found for the selected criteria'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          // Navigate to the first product or show a list
          _navigateToProduct(_products.first);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  void _navigateToProduct(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          productId: product['id'],
          title: product['product_title'] ?? 'No title',
          price: (product['price'] as num?)?.toDouble() ?? 0.0,
          image: product['product_image'] ?? '',
          description: product['description'],
          category: product['category'],
          bestOffer: product['best_offer'],
          userId: product['user_id'],
        ),
      ),
    );
  }

  // Method to handle location suggestion selection
  void _selectLocationSuggestion(LocationSuggestion suggestion) {
    setState(() {
      _locationController.text = suggestion.displayName;
      _selectedState = suggestion.state;
      _selectedCity = suggestion.city;
      _showLocationSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Packages'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select these options to show the packages',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Category Section
            const Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                hintText: 'Search category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                // Removed the extra dropdown icon
              ),
              items: categories
                  .map((category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) => value == null ? 'Select a category' : null,
            ),
            
            const SizedBox(height: 24),
            
            // Location Section
            const Text(
              'Location',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Search city, area or locality',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearchingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    _searchLocation(value);
                  },
                  onTap: () {
                    if (_locationController.text.length >= 3) {
                      setState(() {
                        _showLocationSuggestions = _locationSuggestions.isNotEmpty;
                      });
                    }
                  },
                ),
                
                // Location suggestions dropdown
                if (_showLocationSuggestions && _locationSuggestions.isNotEmpty)
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
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _locationSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _locationSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, size: 20, color: Colors.blue),
                          title: Text(
                            suggestion.shortName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            suggestion.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectLocationSuggestion(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Current Location Option
            InkWell(
              onTap: _isGettingLocation ? null : _getCurrentLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue.shade50,
                ),
                child: Row(
                  children: [
                    _isGettingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _isGettingLocation ? 'Getting location...' : 'Use current location',
                      style: TextStyle(
                        color: _isGettingLocation ? Colors.grey : Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Info Text
            const Text(
              '1. The package you choose will only be valid for the selected category and location.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Show Packages Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoadingProducts ? null : _showPackages,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoadingProducts
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Show packages',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}