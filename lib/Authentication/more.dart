import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  _MorePageState createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  List<String> categories = []; // To store categories

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Fetch categories from Firestore
  void _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .get();

    // Extract unique categories from products
    final categorySet = <String>{};  // Use a set to ensure uniqueness
    for (var doc in snapshot.docs) {
      categorySet.add(doc['category']);
    }

    setState(() {
      categories = categorySet.toList(); // Convert to a list and update the state
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Layer
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Content Layer
          Align(
            alignment: Alignment.centerRight, // Align content to the right
            child: Container(
              width: MediaQuery.of(context).size.width * 0.65, // 70% width
              padding: const EdgeInsets.all(16.0),
              color: Colors.white.withOpacity(0.9), // Semi-transparent background for content
              child: Column(
                children: [
                  // AppBar Replacement
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'All Products',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Categories Section
                  categories.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : Expanded(
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];

                        return ExpansionTile(
                          title: Text(category.toUpperCase()),
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('products')
                                  .where('category', isEqualTo: category)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return const Center(child: Text('No products available in this category.'));
                                }

                                final products = snapshot.data!.docs;
                                return Column(
                                  children: products.map((product) {
                                    return ProductCard(
                                      productTitle: product['title'] ?? 'No title',
                                      product: product,
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String productTitle;
  final QueryDocumentSnapshot product;

  const ProductCard({
    Key? key,
    required this.productTitle,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  productTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*________________________________________________________________________________________*/
class ProductDetailPage extends StatefulWidget {
  final QueryDocumentSnapshot product;

  const ProductDetailPage({required this.product, Key? key}) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String? selectedSize;
  bool isWhitelisted = false;

  @override
  void initState() {
    super.initState();
    checkWhitelistStatus();
  }

  // Check if the product is in the user's whitelist
  void checkWhitelistStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('whitelist')
          .where('product_title', isEqualTo: widget.product['title'])
          .get();

      setState(() {
        isWhitelisted = snapshot.docs.isNotEmpty;
      });
    } catch (error) {
      print('Error while checking whitelist status: $error');
    }
  }

  // Add or remove product from wishlist
  void toggleWishlist() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first!')),
      );
      return;
    }

    try {
      if (isWhitelisted) {
        // Remove from whitelist
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('whitelist')
            .where('product_title', isEqualTo: widget.product['title'])
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

      } else {
        // Add to whitelist
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('whitelist')
            .add({
          'product_title': widget.product['title'],
          'product_price': widget.product['unitprice'],
          'product_rating': widget.product['rating'],
          'image_reference': widget.product['imagePath'],
          'timestamp': FieldValue.serverTimestamp(),
        });

      }

      setState(() {
        isWhitelisted = !isWhitelisted;
      });
    } catch (error) {
      print('Error while updating wishlist: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again!')),
      );
    }
  }

  // Add to cart function
  void addToCart() async {
    if (selectedSize != null) {
      double priceInUsd = double.parse(selectedSize!);
      double priceInTaka = priceInUsd * 122;

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first!')),
        );
        return;
      }

      int quantity = 1;

      CartItem newItem = CartItem(
        product: widget.product,
        size: selectedSize!,
        price: priceInTaka,
        quantity: quantity,
        imagePath: widget.product['imagePath'],
        unitprice: widget.product['unitprice'],
      );

      await addToCartToFirebase(currentUser.uid, newItem);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a size first')),
      );
    }
  }

  // Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(widget.product['imagePath']),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      widget.product['title'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isWhitelisted ? Icons.favorite : Icons.favorite_border,
                  ),
                  onPressed: toggleWishlist,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 5),
                  Text(
                    'Rating: ${widget.product['rating']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TabButton(title: 'Product', isActive: true),
                  _TabButton(title: 'Details', isActive: false),
                  _TabButton(title: 'Reviews', isActive: false),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Size (US)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PriceButton(label: '\$5', isSelected: selectedSize == '5', onPressed: () {
                  setState(() {
                    selectedSize = '5';
                  });
                }),
                _PriceButton(label: '\$10', isSelected: selectedSize == '10', onPressed: () {
                  setState(() {
                    selectedSize = '10';
                  });
                }),
                _PriceButton(label: '\$15', isSelected: selectedSize == '15', onPressed: () {
                  setState(() {
                    selectedSize = '15';
                  });
                }),
                _PriceButton(label: '\$20', isSelected: selectedSize == '20', onPressed: () {
                  setState(() {
                    selectedSize = '20';
                  });
                }),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Share logic
                    },
                    label: const Text('Share This'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: addToCart,
                    child: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Tab Button widget for navigation
class _TabButton extends StatelessWidget {
  final String title;
  final bool isActive;

  const _TabButton({required this.title, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: isActive ? Colors.red : Colors.black,
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onPressed: () {
        // Tab switching logic
      },
      child: Text(title),
    );
  }
}

// Price button widget for selecting product sizes
class _PriceButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _PriceButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.red : Colors.black,
        side: BorderSide(
          color: isSelected ? Colors.red : Colors.grey,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

// Function to add cart item to Firestore under the logged-in user's document
Future<void> addToCartToFirebase(String userId, CartItem cartItem) async {
  try {
    // Firestore path where cart data will be saved
    await FirebaseFirestore.instance
        .collection('users')              // The 'users' collection
        .doc(userId)                       // The document ID will be the user's UID
        .collection('cart_items')          // The 'cart_items' sub-collection for that user
        .add({
      'product_title': cartItem.product['title'],   // Product title
      'size': cartItem.size,                     // Selected Size
      'total_price': cartItem.price * cartItem.quantity,  // Total price based on quantity
      'quantity': cartItem.quantity,             // Product Quantity
      'image_reference': cartItem.imagePath,     // Image reference (Path to image)
      'unitprice': cartItem.unitprice,
      'timestamp': FieldValue.serverTimestamp(), // Timestamp when added
    });

    print("Item added to user's cart successfully");
  } catch (error) {
    print("Failed to add item to cart: $error");
  }
}

// CartItem Model Class
class CartItem {
  final QueryDocumentSnapshot product;
  final String size;
  final double price;
  final int quantity; // New field for quantity
  final String unitprice;
  final String imagePath; // New field for image reference

  CartItem({
    required this.product,
    required this.size,
    required this.price,
    required this.quantity, // Include quantity in constructor
    required this.unitprice,
    required this.imagePath, // Include imagePath in constructor
  });
}
