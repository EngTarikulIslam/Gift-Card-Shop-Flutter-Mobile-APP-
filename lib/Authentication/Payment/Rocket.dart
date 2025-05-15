import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gift_shop/Authentication/Chackout.dart';

/*________________________________________________________________________________________*/
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItemModel> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _cartItems = [];
        _isLoading = false;
      });
      return;
    }

    try {
      QuerySnapshot cartItemsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('cart_items')
          .get();

      List<CartItemModel> fetchedItems = cartItemsSnapshot.docs.map((doc) {
        return CartItemModel(
          id: doc.id,
          title: doc['product_title'],
          size: doc['size'],
          price: doc['total_price'],
          imagePath: doc['image_reference'],
          quantity: doc['quantity'],
          selected: false,
        );
      }).toList();

      setState(() {
        _cartItems = fetchedItems;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching cart items: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String cartItemId) {
    setState(() {
      _cartItems.firstWhere((item) => item.id == cartItemId).selected =
      !_cartItems.firstWhere((item) => item.id == cartItemId).selected;
    });
  }

  Future<void> _updateQuantity(String cartItemId, int newQuantity) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('cart_items')
          .doc(cartItemId)
          .update({'quantity': newQuantity});

      setState(() {
        _cartItems.firstWhere((item) => item.id == cartItemId).quantity =
            newQuantity;
      });
    } catch (e) {
      print("Error updating quantity: $e");
    }
  }

  double _getTotalPrice() {
    return _cartItems.fold(0.0, (sum, item) {
      if (item.selected) {
        return sum + (item.price * item.quantity);
      }
      return sum;
    });
  }

  Future<void> _deleteCartItem(String cartItemId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('cart_items')
          .doc(cartItemId)
          .delete();

      setState(() {
        _cartItems.removeWhere((item) => item.id == cartItemId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item removed from cart')),
      );
    } catch (e) {
      print("Error deleting item: $e");
    }
  }

  Future<void> _handleCheckout() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Get selected items
      List<CartItemModel> selectedItems =
      _cartItems.where((item) => item.selected).toList();

      if (selectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select items to checkout')),
        );
        return;
      }

      // Store selected items in the `checkout_items` collection
      for (var item in selectedItems) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('checkout_items')
            .doc(item.id) // Using the same ID as the cart item
            .set({
          'product_ID': item.id,
          'title': item.title,
          'quantity': item.quantity,
          'unit_price': item.price,
          'total_price': item.price * item.quantity,
          'image_path': item.imagePath,
          'category': 'YourCategory', // Update with the actual category if available
        });
      }

      // Navigate to the Checkout Page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CheckoutApp()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Items moved to checkout')),
      );
    } catch (e) {
      print("Error during checkout: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to checkout items. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? Center(child: Text('Your cart is empty'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                CartItemModel cartItem = _cartItems[index];
                return CartItemWidget(
                  cartItem: cartItem,
                  onDelete: () => _deleteCartItem(cartItem.id),
                  onIncrease: () =>
                      _updateQuantity(cartItem.id, cartItem.quantity + 1),
                  onDecrease: () =>
                      _updateQuantity(cartItem.id, cartItem.quantity - 1),
                  onSelect: () => _toggleSelection(cartItem.id),
                );
              },
            ),
          ),
          Divider(),
          Row(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 30),
                  child: Text(
                    'BDT- ${_getTotalPrice().toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 70, vertical: 14),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            onPressed: _handleCheckout, // Updated checkout function
            child: Text(
              'Checkout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final CartItemModel cartItem;
  final VoidCallback onDelete;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onSelect;

  const CartItemWidget({
    required this.cartItem,
    required this.onDelete,
    required this.onIncrease,
    required this.onDecrease,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Checkbox(
              value: cartItem.selected,
              onChanged: (_) => onSelect(),
            ),
            SizedBox(width: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(cartItem.imagePath),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Size: \$${cartItem.size}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'BDT: ${cartItem.price.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: cartItem.quantity > 1 ? onDecrease : null,
                    ),
                    Text('${cartItem.quantity}'),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: onIncrease,
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CartItemModel {
  final String id;
  final String title;
  final String size;
  final double price;
  final String imagePath;
  int quantity;
  bool selected;

  CartItemModel({
    required this.id,
    required this.title,
    required this.size,
    required this.price,
    required this.imagePath,
    required this.quantity,
    this.selected = false,
  });
}



//build checkout item store in database














