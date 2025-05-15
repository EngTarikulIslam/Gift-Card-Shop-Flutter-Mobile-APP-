import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';





/*_____________________________________________________________________________*/

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});
  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Wishlist'),
        ),
        body: const Center(
          child: Text('Please log in to view your wishlist.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('whitelist')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Your wishlist is empty.'),
            );
          }

          final wishlistItems = snapshot.data!.docs;

          return ListView.builder(
            itemCount: wishlistItems.length,
            itemBuilder: (context, index) {
              final item = wishlistItems[index];
              return WishlistItemCard(
                productTitle: item['product_title'] ?? 'Unknown',
                productPrice: double.tryParse(item['product_price'].toString()) ?? 0.0, // Convert price to double
                productRating: double.tryParse(item['product_rating'].toString()) ?? 0.0, // Convert rating to double
                imageReference: item['image_reference'] ?? '',
                onRemove: () async {
                  await item.reference.delete();
                },
              );
            },
          );
        },
      ),
    );
  }
}



class WishlistItemCard extends StatelessWidget {
  final String productTitle;
  final double productPrice;
  final double productRating;
  final String imageReference;
  final VoidCallback onRemove;

  const WishlistItemCard({
    Key? key,
    required this.productTitle,
    required this.productPrice,
    required this.productRating,
    required this.imageReference,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imageReference,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Per Unit Price: \৳${productPrice.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rating: ${productRating.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const Icon(Icons.star, color: Colors.redAccent, size: 16,),
                      const SizedBox(width: 3),

                    ],
                  ),
                ],
              ),
            ),

            // Remove Button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
