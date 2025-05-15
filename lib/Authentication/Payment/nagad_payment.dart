import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gift_shop/Authentication/Home.dart';

class NagadPaymentPage extends StatefulWidget {
  final String userId;

  const NagadPaymentPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<NagadPaymentPage> createState() => _NagadPaymentPageState();
}

class _NagadPaymentPageState extends State<NagadPaymentPage> {
  final TextEditingController NagadNumberController = TextEditingController();
  final TextEditingController transactionIdController = TextEditingController();

  double totalAmount = 0.0;

  String? nagadNumber; // Holds the Bkash number fetched from the database
  bool isLoading = true; // Show loading spinner while fetching data

  @override
  void initState() {
    super.initState();
    _fetchBkashNumber();
    _fetchTotalPrice();
  }

  Future<void> _fetchBkashNumber() async {
    try {
      // Query all documents in the payment_methods collection
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('payment_methos')
          .where('status', isEqualTo: 'active') // Filter for active status
          .get();

      // Find the first document with a valid bkash number
      for (var doc in querySnapshot.docs) {
        if (doc.data().containsKey('nagad') && doc.data()['nagad'] != null) {
          setState(() {
            nagadNumber = doc.data()['nagad'];
            isLoading = false;
          });
          return;
        }
      }


      setState(() {
        nagadNumber = null;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        nagadNumber = null; // Error fetching data
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching Nagad number: $error')),
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


  void _confirmPayment() {
    final enteredNagadNumber = NagadNumberController.text.trim();
    final transactionId = transactionIdController.text.trim();

    if (enteredNagadNumber.isEmpty || transactionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all the fields.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment confirmed!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green, // Bkash Pink
        elevation: 0,
        title: const Text(
          'Nagad Payment',
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
          ? const Center(child: CircularProgressIndicator()) // Show loader while fetching
          : Padding(
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
              nagadNumber != null
                  ? 'Nagad Personal: $nagadNumber\nTotal Amount: ${totalAmount.toStringAsFixed(1)}'
                  : 'Nagad number not available.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
            ),
            ),
            const SizedBox(height: 16),
            const Text(
              'At first, copy this Nagad personal number and send the equivalent amount to this number. '
                  'After completing, fill up this form by entering the Nagad number and transaction ID, then press Confirm.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            // Nagad Number Input
            TextField(
              controller: NagadNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nagad Number',
                hintText: 'Enter your Nagad Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Transaction ID Input
            TextField(
              controller: transactionIdController,
              decoration: InputDecoration(
                labelText: 'Transaction ID',
                hintText: 'Enter Send Money TrxID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Confirm Button
            ElevatedButton(
              onPressed: _confirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Bkash Pink
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
