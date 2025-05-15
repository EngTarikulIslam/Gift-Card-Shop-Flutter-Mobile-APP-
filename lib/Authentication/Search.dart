import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<String> recommendations = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchRecommendations();
  }

  Future<void> fetchProducts() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('products').get();

      final List<Map<String, dynamic>> fetchedProducts = querySnapshot.docs.map((doc) {
        return {
          'title': doc['title']?.toString().toLowerCase() ?? "",
          'tags': doc['tags']?.toString().toLowerCase().split(',') ?? [],
          'price': doc['unitprice'],
          'rating': doc['rating'],
          'size': doc['size'],
          'imagePath': doc['imagePath'],
          'category': doc['category'],
          'Product_ID': doc['Product_ID'] ?? "",
        };
      }).toList();

      setState(() {
        products = fetchedProducts;
        filteredProducts = fetchedProducts;
      });
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> fetchRecommendations() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('products').get();

      final List<String> titles = querySnapshot.docs
          .where((doc) => double.tryParse(doc['rating'].toString()) != null &&
          double.parse(doc['rating'].toString()) >= 4.5)
          .map((doc) => doc['title'] as String)
          .toList();

      setState(() {
        recommendations = titles;
      });
    } catch (e) {
      print('Error fetching recommendations: $e');
    }
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredProducts = products;
      });
      return;
    }

    final List<Map<String, dynamic>> results = products.where((product) {
      final List<String> tags = product['tags'];
      final String lowerCaseQuery = query.toLowerCase();
      return product['title'].contains(lowerCaseQuery) ||
          tags.any((tag) => tag.contains(lowerCaseQuery));
    }).toList();

    setState(() {
      filteredProducts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Gift Card',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.filter_alt_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onChanged: (value) {
                searchQuery = value;
              },
              onSubmitted: (value) {
                filterProducts(value);
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailPage(
                          product: Product(
                            title: product['title'],
                            imagePath: product['imagePath'],
                            size: product['size'],
                            rating: product['rating'].toString(),
                            unitprice: product['price'].toString(),
                            category: product['category'],
                            Product_ID: product['Product_ID'],
                          ),
                        ),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 2,
                    child: Column(
                      children: [
                        Flexible(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(10.0)),
                              image: DecorationImage(
                                image: AssetImage(product['imagePath']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['title'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Size: ', // Label for size
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        Text(
                                          (() {
                                            // Check the category to determine the display format
                                            if (product['category'].trim().toLowerCase() == 'digital') {
                                              return '\$' + product['size']; // Add dollar symbol for digital products
                                            } else if (product['category'].trim().toLowerCase() == 'physical') {
                                              return product['size']; // No dollar symbol for physical products
                                            } else {
                                              return 'Invalid category'; // Handle unexpected categories
                                            }
                                          })(),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            size: 12, color: Colors.orange),
                                        const SizedBox(width: 2),
                                        Text(
                                          product['rating'].toString(),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                                Row(
                                  children: [
                                    const Text(
                                      'Price: ',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      (() {
                                        // Check the category to determine the display format
                                        if (product['category'].trim().toLowerCase() == 'physical') {
                                          return '\৳' + product['price'].toString(); // Use unit price for physical products
                                        } else if (product['category'].trim().toLowerCase() == 'digital') {
                                          // Ensure price and size are valid numbers
                                          try {
                                            double price = double.parse(product['price'].toString());
                                            double sizeValue = double.parse(product['size'].toString());
                                            return '\৳' + (price * sizeValue).toStringAsFixed(1); // Format the total price
                                          } catch (e) {
                                            return 'Invalid price or size'; // Handle invalid price or size values
                                          }
                                        } else {
                                          return 'Invalid categor'; // Handle unexpected categories
                                        }
                                      })(),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),


                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'RECOMMENDED',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              children: recommendations.isNotEmpty
                  ? recommendations.map((title) => Chip(label: Text(title))).toList()
                  : [const Text('Loading...')],
            ),
          ),
        ],
      ),
    );
  }
}

class Product {
  final String title;
  final String imagePath;
  final String size;
  final String rating;
  final String unitprice;
  final String category;
  final String Product_ID;

  Product({
    required this.title,
    required this.imagePath,
    required this.size,
    required this.rating,
    required this.unitprice,
    required this.category,
    required this.Product_ID,
  });
}



/*________________________________________________________________________________________*/
class ProductDetailPage extends StatefulWidget {
  final Product product;

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
          .where('product_title', isEqualTo: widget.product.title)
          .where('Product_ID', isEqualTo: widget.product.Product_ID)
          .where('category', isEqualTo: widget.product.category)
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
            .where('product_title', isEqualTo: widget.product.title)
            .where('Product_ID', isEqualTo: widget.product.Product_ID)
            .where('category', isEqualTo: widget.product.category)
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
          'product_title': widget.product.title,
          'Product_ID': widget.product.Product_ID,
          'category': widget.product.category,
          'product_price': widget.product.unitprice,
          'product_rating': widget.product.rating,
          'image_reference': widget.product.imagePath,
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
        imagePath: widget.product.imagePath,
        unitprice: widget.product.unitprice,
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
        title: Text("Product Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(widget.product.imagePath),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      widget.product.title,
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
                    'Rating: ${widget.product.rating}',
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
      'product_title': cartItem.product.title,   // Product title
      'size': cartItem.size,                     // Selected Size
      'total_price': cartItem.price * cartItem.quantity,  // Total price based on quantity
      'quantity': cartItem.quantity,             // Product Quantity
      'unitprice': cartItem.unitprice,
      'image_reference': cartItem.imagePath,     // Image reference (Path to image)
      'timestamp': FieldValue.serverTimestamp(), // Timestamp when added
    });

    print("Item added to user's cart successfully");
  } catch (error) {
    print("Failed to add item to cart: $error");
  }
}

// CartItem Model Class
class CartItem {
  final Product product;
  final String size;
  final double price;
  final String unitprice;
  final int quantity; // New field for quantity
  final String imagePath; // New field for image reference

  CartItem({
    required this.product,
    required this.size,
    required this.price,
    required this.unitprice,
    required this.quantity, // Include quantity in constructor
    required this.imagePath, // Include imagePath in constructor
  });
}