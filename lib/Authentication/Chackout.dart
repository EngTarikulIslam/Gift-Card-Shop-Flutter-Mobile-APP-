import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gift_shop/Authentication/Home.dart';
import 'package:gift_shop/Authentication/Payment/bkash_payment.dart';
import 'package:gift_shop/Authentication/Payment/nagad_payment.dart';

class CheckoutApp extends StatefulWidget {
  const CheckoutApp({super.key});

  @override
  State<CheckoutApp> createState() => _CheckoutAppState();
}

class _CheckoutAppState extends State<CheckoutApp> {
  String selectedPaymentMethod = 'Bkash';
  final TextEditingController promoCodeController = TextEditingController();
  double totalAmount = 0.0; // Variable to store total amount dynamically

  @override
  void initState() {
    super.initState();
    _calculateTotalAmount(); // Calculate total amount when screen initializes
  }

  // Calculate the total amount based on checkout_items subcollection
  Future<void> _calculateTotalAmount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final checkoutItemsSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("checkout_items")
          .get();

      if (checkoutItemsSnapshot.docs.isEmpty) {
        setState(() {
          totalAmount = 0.0; // No checkout items
        });
        return;
      }

      double sum = 0.0;
      for (var doc in checkoutItemsSnapshot.docs) {
        try {
          final totalPrice = doc.data()["total_price"];
          if (totalPrice != null) {
            sum += totalPrice is double
                ? totalPrice
                : double.tryParse(totalPrice.toString()) ?? 0.0;
          }
        } catch (e) {
          print("Error parsing total_price for document ${doc.id}: $e");
        }
      }

      setState(() {
        totalAmount = sum; // Update state with calculated sum
      });
    } catch (e) {
      print("Error fetching checkout items: $e");
      setState(() {
        totalAmount = 0.0; // Handle error
      });
    }
  }

  // Apply Promo Code
  Future<void> _applyPromoCode() async {
    final coupon = promoCodeController.text.trim(); // Get user input
    if (coupon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a promo code.")),
      );
      return;
    }

    try {
      // Fetch promo code from Firestore
      final couponSnapshot = await FirebaseFirestore.instance
          .collection("coupon")
          .where("coupon", isEqualTo: coupon)
          .where("isActive", isEqualTo: true)
          .get();

      if (couponSnapshot.docs.isEmpty) {
        // No matching promo code found or inactive
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid promo code. Please try again.")),
        );
        return;
      }

      // Promo code found, check validity
      final couponData = couponSnapshot.docs.first.data();
      final discountString = couponData["discount"] ?? "0%";
      final startDate = couponData["startDate"]?.toDate();
      final endDate = couponData["endDate"]?.toDate();
      final currentDate = DateTime.now();

      if (startDate != null && currentDate.isBefore(startDate) ||
          endDate != null && currentDate.isAfter(endDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This promo code is not valid at the moment.")),
        );
        return;
      }

      // Ensure the discount string is a valid percentage
      final discountPercentage = _parseDiscountPercentage(discountString);

      if (discountPercentage > 0) {
        final discountAmount = totalAmount * (discountPercentage / 100);
        final newTotal = totalAmount - discountAmount;

        setState(() {
          totalAmount = newTotal;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Promo code applied! You saved ${discountPercentage.toStringAsFixed(2)}%.",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This promo code has no discount.")),
        );
      }
    } catch (e) {
      // Handle Firestore errors
      print("Error applying promo code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error applying promo code. Please try again.")),
      );
    }
  }

  // Helper method to parse the discount percentage correctly
  double _parseDiscountPercentage(String discountString) {
    try {
      // Remove non-numeric characters (like '%')
      final numericString = discountString.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(numericString) ?? 0.0;
    } catch (e) {
      print("Error parsing discount: $e");
      return 0.0;
    }
  }

  // Handle Place Order for Bkash payment
  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final checkoutItemsSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("checkout_items")
          .get();

      if (checkoutItemsSnapshot.docs.isEmpty) return;

      // Add items to the 'order' collection
      for (var doc in checkoutItemsSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("order")
            .add(doc.data());
      }

      // Delete items from the 'checkout_items' collection
      for (var doc in checkoutItemsSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("checkout_items")
            .doc(doc.id)
            .delete();
      }

      // Navigate to the payment page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BkashPaymentPage(userId: '',)),
      );
    } catch (e) {
      print("Error placing order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error placing order. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in!")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SHIPPING ADDRESS title at the top
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.98,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "SHIPPING ADDRESS",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Address Section
            Container(
              height: 200, // Adjust height as per your UI requirement
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(user.uid)
                    .collection("shipping_addresses")
                    .where('is_default_billing', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No default shipping address found."));
                  }

                  final address = snapshot.data!.docs.first;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                address["name"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward,
                                    color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddressEditPage(addressId: address.id),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Text("Phone: ${address["phone"]}"),
                          Text("Street: ${address["street"]}"),
                          Text("City: ${address["city"]}, State: ${address["state"]}"),
                          Text("Zip: ${address["zip"]}"),
                          Text(
                            "Default Billing: ${address["is_default_billing"] ? "Yes" : "No"}",
                            style: TextStyle(
                              color: address["is_default_billing"]
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Payment Section
            const Padding(
              padding: EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.95,
                  alignment: Alignment.centerRight,
                  child: Text(
                    "PAYMENT METHOD",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            PaymentMethodOption(
              title: 'Bkash',
              icon: Icons.payment,
              isSelected: selectedPaymentMethod == 'Bkash',
              onTap: () => setState(() => selectedPaymentMethod = 'Bkash'),
            ),
            PaymentMethodOption(
              title: 'Rocket',
              icon: Icons.money,
              isSelected: selectedPaymentMethod == 'Rocket',
              onTap: () => setState(() => selectedPaymentMethod = 'Rocket'),
            ),
            PaymentMethodOption(
              title: 'Nagad',
              icon: Icons.account_balance_wallet,
              isSelected: selectedPaymentMethod == 'Nagad',
              onTap: () => setState(() => selectedPaymentMethod = 'Nagad'),
            ),
            PaymentMethodOption(
              title: 'Credit/Debit Card',
              icon: Icons.credit_card,
              isSelected: selectedPaymentMethod == 'Credit/Debit Card',
              onTap: () => setState(() => selectedPaymentMethod = 'Credit/Debit Card'),
            ),
            PaymentMethodOption(
              title: 'Cash on Delivery',
              icon: Icons.local_shipping,
              isSelected: selectedPaymentMethod == 'Cash on Delivery',
              onTap: () => setState(() => selectedPaymentMethod = 'Cash on Delivery'),
            ),

            // Promo Code Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: FractionallySizedBox(
                    widthFactor: 0.9,
                    child: TextField(
                      controller: promoCodeController,
                      decoration: const InputDecoration(
                        hintText: 'Enter Your Promo Code',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_offer),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: ElevatedButton(
                    onPressed: _applyPromoCode,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text(
                      'Apply',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            // Total Amount Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 75.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Amount",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "\৳ ${totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedPaymentMethod == 'Bkash') {
                        _placeOrder();
                      } else if (selectedPaymentMethod == 'Nagad') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                              const NagadPaymentPage(userId: '')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Please select a valid payment method.")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: const Text(
                      'PLACE ORDER',
                      style: TextStyle(fontSize: 14, color: Colors.white),
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

class PaymentMethodOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodOption({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
    );
  }
}







class AddressEditPage extends StatefulWidget {
  final String addressId;

  const AddressEditPage({super.key, required this.addressId});

  @override
  State<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController zipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  void _loadAddressData() async {
    final addressData = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("shipping_addresses")
        .doc(widget.addressId)
        .get();

    final address = addressData.data();
    if (address != null) {
      nameController.text = address["name"];
      phoneController.text = address["phone"];
      streetController.text = address["street"];
      cityController.text = address["city"];
      stateController.text = address["state"];
      zipController.text = address["zip"];
    }
  }

  void _updateAddress() async {
    final updatedAddress = {
      "name": nameController.text,
      "phone": phoneController.text,
      "street": streetController.text,
      "city": cityController.text,
      "state": stateController.text,
      "zip": zipController.text,
    };

    await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("shipping_addresses")
        .doc(widget.addressId)
        .update(updatedAddress);

    Navigator.pop(context); // Go back to the checkout screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Address"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            TextField(
              controller: streetController,
              decoration: const InputDecoration(labelText: "Street"),
            ),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: "City"),
            ),
            TextField(
              controller: stateController,
              decoration: const InputDecoration(labelText: "State"),
            ),
            TextField(
              controller: zipController,
              decoration: const InputDecoration(labelText: "Zip"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateAddress,
              child: const Text("Update Address"),
            ),
          ],
        ),
      ),
    );
  }
}
