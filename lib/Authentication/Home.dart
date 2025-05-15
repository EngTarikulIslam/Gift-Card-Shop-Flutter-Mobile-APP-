import 'package:flutter/material.dart';
import 'package:gift_shop/Authentication/ProfilePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gift_shop/Authentication/Wishlist.dart';
import 'package:gift_shop/Authentication/Cart.dart';
import 'package:gift_shop/Authentication/more.dart';
import 'package:gift_shop/Authentication/Search.dart';




class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class MenuItem {
  final IconData icon;
  final String label;
  final Widget page;

  MenuItem({required this.icon, required this.label, required this.page});
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // Default to Home screen
  String? gender;

  // List of menu items (dynamically loaded)
  final List<MenuItem> menuItems = [
    MenuItem(
      icon: Icons.search,
      label: 'Search',
      page: SearchPage(),
    ),
    MenuItem(
      icon: Icons.favorite,
      label: 'Fav',
      page: const WishlistPage(),
    ),
    MenuItem(
      icon: Icons.home,
      label: 'Home',
      page: const HomePageContent(),
    ),
    MenuItem(
      icon: Icons.shopping_cart,
      label: 'Cart',
      page: const CartPage(),
    ),
    MenuItem(
      icon: Icons.menu,
      label: 'More',
      page: const MorePage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Fetch gender when the page loads
    getGenderFromFirestore().then((genderData) {
      setState(() {
        gender = genderData;
      });
    });
  }

  // Fetch the user's gender from Firestore
  Future<String?> getGenderFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDocument = await FirebaseFirestore.instance
            .collection('users') // Assuming 'users' is your Firestore collection
            .doc(user.uid)
            .get();
        return userDocument['gender']; // Assuming 'gender' is the field in Firestore
      }
    } catch (e) {
      print("Error fetching gender: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Dhaka, Bangladesh',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: CircleAvatar(
              radius: 18,
              backgroundImage: gender == 'Male'
                  ? AssetImage('assets/male_profile.png')
                  : gender == 'Female'
                  ? AssetImage('assets/female_profile.png')
                  : AssetImage('assets/other_profile.png'),
            ),
          ),
          const SizedBox(width: 10),
        ],
        leading: const Icon(Icons.search, color: Colors.black),
      ),
      body: menuItems[_currentIndex].page, // Show the selected page

      // Dynamic Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color.fromARGB(255, 255, 85, 0),
        unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        currentIndex: _currentIndex,
        backgroundColor: Colors.transparent,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the selected index
          });
        },
        items: menuItems
            .map(
              (item) => BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          ),
        )
            .toList(),
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Product',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Add action for "View All"
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CategoryButton(
                  icon: Image.asset('assets/itunes_icon.png'),
                  label: 'iTunes',
                ),
                CategoryButton(
                  icon: Image.asset('assets/amazon_icon.png'),
                  label: 'Amazon',
                ),
                CategoryButton(
                  icon: Image.asset('assets/google_icon.png'),
                  label: 'Google',
                ),
                CategoryButton(
                  icon: Image.asset('assets/razer_icon.png'),
                  label: 'Razer',
                ),
                CategoryButton(
                  icon: Image.asset('assets/PlayStation1.png'),
                  label: 'PlayStation',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.33,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/Offer.png',
                          fit: BoxFit.cover,
                          height: 60,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Discount Up to 50%',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        'All Products',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: fetchProducts(), // Fetch the dynamic products
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No products available'));
                  } else {
                    final products = snapshot.data!;
                    return GridView.builder(
                      itemCount: products.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(product: product),
                              ),
                            );
                          },
                          child: ProductCard(
                            title: product.title,
                            imagePath: product.imagePath,
                            size: product.size,
                            rating: product.rating,
                            unitprice: product.unitprice,
                            category: product.category,
                            Product_ID: product.Product_ID,
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fetch products from Firestore
  Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // Fetch products from Firestore
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products') // Your products collection
          .get();

      return querySnapshot.docs.map((doc) {
        return Product(
          title: doc['title'],
          imagePath: doc['imagePath'], // Correct path for assets in Firestore
          size : doc['size'],
          rating: doc['rating'],
          unitprice: doc['unitprice'],
          category: doc['category'],
          Product_ID: doc['Product_ID'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
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

class ProductCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final String size;
  final String rating;
  final String unitprice;
  final String category;
  final String Product_ID;

  const ProductCard({
    required this.title,
    required this.imagePath,
    required this.size,
    required this.rating,
    required this.unitprice,
    required this.category,
    required this.Product_ID,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    print("Image Path: $imagePath"); // Debugging the image path

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.asset(
                imagePath,  // Use imagePath for product image from assets
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,  // Display the product title
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Space between size and rating
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
                            if (category.trim().toLowerCase() == 'digital') {
                              return '\$' + size; // Add dollar symbol for digital products
                            } else if (category.trim().toLowerCase() == 'physical') {
                              return size; // No dollar symbol for physical products
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
                        const Icon(
                          Icons.star,  // Rating symbol (star)
                          color: Colors.redAccent,  // Star color
                          size: 11,  // Star size
                        ),
                        Text(
                          rating,  // Display the rating
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Price: \৳', // Label for price
                      style: TextStyle(fontSize: 11),
                    ),
                    Text(
                      (() {
                        try {
                          // Ensure `category` is normalized
                          String normalizedCategory = category.trim().toLowerCase();

                          if (normalizedCategory == 'physical') {
                            return unitprice; // Return raw unit price for physical products
                          } else if (normalizedCategory == 'digital') {
                            // Parse and calculate total price for digital products
                            double price = double.parse(unitprice);
                            double sizeValue = double.parse(size);
                            return (price * sizeValue).toString();
                          } else {
                            return 'Invalid category'; // Handle unexpected categories
                          }
                        } catch (e) {
                          // Handle parsing or other runtime errors
                          return 'Invalid input';
                        }
                      })(),
                      style: const TextStyle(fontSize: 11),
                    ),


                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}








//Menu Bard
class CategoryButton extends StatelessWidget {
  final Image icon;
  final String label;

  const CategoryButton({
    required this.icon,
    required this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: icon,
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
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
      'unitprice': cartItem.unitprice,
      'total_price': cartItem.price * cartItem.quantity,  // Total price based on quantity
      'quantity': cartItem.quantity,             // Product Quantity
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










