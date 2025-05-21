import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sells/screens/AddProductPage.dart';
import 'package:sells/screens/product_details.dart';
import 'package:sells/screens/UserProfilePage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final categories = [
    'All',
    'Electronics',
    'Fashion',
    'Home',
    'Accessories',
    'Books',
  ];

  final categoryIcons = {
    'All': Icons.apps,
    'Electronics': Icons.electrical_services,
    'Fashion': Icons.checkroom,
    'Home': Icons.home,
    'Accessories': Icons.watch,
    'Books': Icons.menu_book,
  };

  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  String selectedCategory = 'All';
  bool isLoading = true;

  Future<void> fetchProducts() async {
    try {
      final response =
          await Supabase.instance.client
              .from('products')
              .select(); // fetch all products regardless of user

      setState(() {
        allProducts = List<Map<String, dynamic>>.from(response);
        filterProducts(); // Apply category filter
        isLoading = false;
      });
    } catch (e) {
      print('Failed to fetch products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterProducts() {
    if (selectedCategory == 'All') {
      filteredProducts = [...allProducts];
    } else {
      filteredProducts =
          allProducts
              .where(
                (product) =>
                    product['category']?.toString().toLowerCase() ==
                    selectedCategory.toLowerCase(),
              )
              .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen()),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/usericon.png'),
            ),
          ),
        ),

        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search products...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.grey.shade200,
              filled: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        actions: const [
          Icon(Icons.notifications_none, color: Colors.black),
          SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                        filterProducts();
                      });
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              isSelected ? Colors.blue : Colors.blue.shade50,
                          child: Icon(
                            categoryIcons[category],
                            color: isSelected ? Colors.white : Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color: isSelected ? Colors.blue : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Featured Deals",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                ? const Center(child: Text("No products found."))
                : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final price =
                        product['price'] != null
                            ? (product['price'] is num
                                ? product['price']
                                : double.tryParse(
                                      product['price'].toString(),
                                    ) ??
                                    0)
                            : 0;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsPage(
                              productId: product['id'],
                              title: product['product_title'],
                              price: product['price'],
                              image: product['product_image'],
                            ),
                          ),
                        );

                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  product['product_image'] ?? '',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder:
                                      (_, __, ___) =>
                                          const Icon(Icons.image, size: 60),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['product_title'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₹${price.toString()}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    "Negotiable",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
