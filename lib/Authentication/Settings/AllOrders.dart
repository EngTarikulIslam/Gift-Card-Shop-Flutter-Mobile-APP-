import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


/*_____________________________________________________________________________*/
class AllOrders extends StatelessWidget {
  const AllOrders({super.key});

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('All Order'),
        ),
        body: const Center(
          child: Text('Please log in to view.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Order'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('order')
            .where('userId', isEqualTo: currentUser.uid) // Match userId
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Order Not found.'),
            );
          }

          final pendingPayments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pendingPayments.length,
            itemBuilder: (context, index) {
              final item = pendingPayments[index];
              return WishlistItemCard(
                productTitle: item['product_title'] ?? 'Unknown',
                productPrice: double.tryParse(item['total_amount'].toString()) ?? 0.0,
                payment: item['status']??'Unknown',
                status: item['delivery'] ?? 'Unknown',
                imageReference: item['image_path'] ?? '',
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
  final String status;
  final String payment;
  final String imageReference;

  const WishlistItemCard({
    Key? key,
    required this.productTitle,
    required this.productPrice,
    required this.status,
    required this.payment,
    required this.imageReference,
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
                    'Total Price: \৳${productPrice.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payment: $payment',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Delivery: $status',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
