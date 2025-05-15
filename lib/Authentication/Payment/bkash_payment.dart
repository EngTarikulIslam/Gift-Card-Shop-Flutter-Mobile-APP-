import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:gift_shop/Authentication/Payment/success.dart';
import 'package:gift_shop/Authentication/Home.dart';

class BkashPaymentPage extends StatefulWidget {
  final String userId;

  const BkashPaymentPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<BkashPaymentPage> createState() => _BkashPaymentPageState();
}

class _BkashPaymentPageState extends State<BkashPaymentPage> {
  final TextEditingController bkashNumberController = TextEditingController();
  final TextEditingController transactionIdController = TextEditingController();
  final TextEditingController emailIdController = TextEditingController();

  double totalAmount = 0.0;

  String? bkashNumber; // Holds the Bkash number fetched from the database
  bool isLoading = true; // Show loading spinner while fetching data

  @override
  void initState() {
    super.initState();
    _fetchBkashNumber();
    _fetchTotalPrice();
  }

  Future<void> _fetchBkashNumber() async {
    try {
      QuerySnapshot<
          Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('payment_methos')
          .where('status', isEqualTo: 'active') // Filter for active status
          .get();

      for (var doc in querySnapshot.docs) {
        if (doc.data().containsKey('bkash') && doc.data()['bkash'] != null) {
          setState(() {
            bkashNumber = doc.data()['bkash'];
            isLoading = false;
          });
          return;
        }
      }

      setState(() {
        bkashNumber = null;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        bkashNumber = null;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching Bkash number: $error')),
      );
    }
  }

  Future<void> _fetchTotalPrice() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        totalAmount = 0.0; // Handle case where user is not logged in
      });
      return;
    }

    try {
      // Retrieve all documents in the "order" subcollection
      final orderSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("order")
          .get();

      // Check if there are any orders
      if (orderSnapshot.docs.isEmpty) {
        setState(() {
          totalAmount = 0.0; // No orders available
        });
        return;
      }

      // Calculate the sum of total_price fields
      double sum = 0.0;
      for (var doc in orderSnapshot.docs) {
        final data = doc.data();
        final totalPrice = data["total_price"];

        // Safely add total_price to the sum
        if (totalPrice != null) {
          sum += totalPrice is double
              ? totalPrice
              : double.tryParse(totalPrice.toString()) ?? 0.0;
        }
      }

      // Update the totalAmount state with the calculated sum
      setState(() {
        totalAmount = sum;
      });
    } catch (error) {
      // Handle errors gracefully
      print("Error fetching total price: $error");
      setState(() {
        totalAmount = 0.0; // Default to 0.0 on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating total price: $error')),
      );
    }
  }

  Future<void> _confirmPayment() async {
    final enteredBkashNumber = bkashNumberController.text.trim();
    final transactionId = transactionIdController.text.trim();
    final emailid = emailIdController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (enteredBkashNumber.isEmpty || transactionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all the fields.'),
        ),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in.'),
        ),
      );
      return;
    }

    try {
      final orderSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("order")
          .get();

      if (orderSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No items found in your order.'),
          ),
        );
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in orderSnapshot.docs) {
        final data = doc.data();
        final productTitle = data['title'] ?? 'Unknown';
        final image_path = data['image_path'] ?? 'Unknown';
        final quantity = data['quantity'] ?? 1;
        final size = data['size'] ?? 5;
        final status = data['status'] ?? 'pending';
        final delivery = data['delivery'] ?? 'No';

        final newOrderRef = FirebaseFirestore.instance.collection('order')
            .doc();
        batch.set(newOrderRef, {
          'userId': user.uid,
          'product_title': productTitle,
          'image_path': image_path,
          'quantity': quantity,
          'size': size,
          'email': emailid,
          'bkash_number': enteredBkashNumber,
          'transaction_id': transactionId,
          'total_amount': totalAmount,
          'status': status,
          'delivery': delivery,
          'timestamp': FieldValue.serverTimestamp(),
        });
        // Delete the document from the user's subcollection
        for (var doc in orderSnapshot.docs) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .collection("order")
              .doc(doc.id)
              .delete();
        }
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed and order placed!'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SuccessPage()),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming payment: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // Prevents bottom overflow
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF0077),
        // Bkash Pink
        elevation: 0,
        title: const Text(
          'Bkash Payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Payment Info',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              bkashNumber != null
                  ? 'Bkash Personal: $bkashNumber\nTotal Amount: ${totalAmount
                  .toStringAsFixed(1)}'
                  : 'Bkash number not available.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'At first, copy this Bkash personal number and send the equivalent amount to this number. '
                  'After completing, fill up this form by entering the Bkash number and transaction ID, then press Confirm.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: emailIdController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter Your Email Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bkashNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Bkash Number',
                hintText: 'Enter Your Bkash Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: transactionIdController,
              keyboardType: TextInputType.text,
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
                // Limit to 10 characters
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                // Uppercase letters and digits only
              ],
              decoration: InputDecoration(
                labelText: 'Transaction ID',
                hintText: 'Enter Send Money TrxID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                if (value.length < 10) {
                  print('Transaction ID must be exactly 10 characters');
                } else if (value.length == 10) {
                  print('Valid Transaction ID');
                } else {
                  print('Invalid Transaction ID');
                }
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _confirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0077), // Bkash Pink
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 15),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirm',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
