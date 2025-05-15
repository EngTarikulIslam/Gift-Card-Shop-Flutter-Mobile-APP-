import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ShippingAddressPage extends StatelessWidget {
  const ShippingAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("User not logged in!"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shipping Addresses"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("shipping_addresses")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No shipping addresses found."));
          }

          final addresses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return ListTile(
                title: Text(address["name"]),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Phone: ${address["phone"]}"),
                    Text("Street: ${address["street"]}"),
                    Text("City: ${address["city"]}, State: ${address["state"]}"),
                    Text("Zip: ${address["zip"]}"),
                    Text("Category: ${address["address_category"]}"),
                    Text("Default Billing: ${address["is_default_billing"] ? "Yes" : "No"}"),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        // Navigate to the edit page with the selected address
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditShippingAddressPage(
                              addressId: address.id,
                              currentData: address,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection("users")
                            .doc(user.uid)
                            .collection("shipping_addresses")
                            .doc(address.id)
                            .delete();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddShippingAddressPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}



class AddShippingAddressPage extends StatefulWidget {
  const AddShippingAddressPage({super.key});

  @override
  _AddShippingAddressPageState createState() => _AddShippingAddressPageState();
}

class _AddShippingAddressPageState extends State<AddShippingAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  String _addressCategory = 'Home'; // Default category
  bool _isDefaultBilling = false; // Default billing address

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _addAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in!")),
      );
      return;
    }

    final userId = user.uid;

    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("shipping_addresses")
          .add({
        "name": _nameController.text,
        "phone": _phoneController.text,
        "street": _streetController.text,
        "city": _cityController.text,
        "state": _stateController.text,
        "zip": _zipController.text,
        "address_category": _addressCategory,
        "is_default_billing": _isDefaultBilling,
      });
      Navigator.pop(context); // Return to the address list page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Shipping Address"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Recipient Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter the recipient name.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a valid phone number.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: "Street Address"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your street address.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: "City"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your city.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: "State"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your state.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipController,
                decoration: const InputDecoration(labelText: "Zip Code"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your zip code.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _addressCategory,
                decoration: const InputDecoration(labelText: "Address Category"),
                items: ['Home', 'Work', 'Other']
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _addressCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Set as Default Billing Address"),
                value: _isDefaultBilling,
                onChanged: (bool value) {
                  setState(() {
                    _isDefaultBilling = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addAddress,
                child: const Text("Add Address"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditShippingAddressPage extends StatefulWidget {
  final String addressId;
  final DocumentSnapshot currentData;

  const EditShippingAddressPage({
    super.key,
    required this.addressId,
    required this.currentData,
  });

  @override
  State<EditShippingAddressPage> createState() =>
      _EditShippingAddressPageState();
}

class _EditShippingAddressPageState extends State<EditShippingAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  String _addressCategory = 'Home';
  bool _isDefaultBilling = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentData["name"];
    _phoneController.text = widget.currentData["phone"];
    _streetController.text = widget.currentData["street"];
    _cityController.text = widget.currentData["city"];
    _stateController.text = widget.currentData["state"];
    _zipController.text = widget.currentData["zip"];
    _addressCategory = widget.currentData["address_category"];
    _isDefaultBilling = widget.currentData["is_default_billing"];
  }

  void _updateAddress() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("shipping_addresses")
          .doc(widget.addressId)
          .update({
        "name": _nameController.text,
        "phone": _phoneController.text,
        "street": _streetController.text,
        "city": _cityController.text,
        "state": _stateController.text,
        "zip": _zipController.text,
        "address_category": _addressCategory,
        "is_default_billing": _isDefaultBilling,
      });
      Navigator.pop(context); // Return to address list page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Shipping Address"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Recipient Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter the recipient name.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a valid phone number.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: "Street Address"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your street address.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: "City"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your city.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: "State"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your state.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipController,
                decoration: const InputDecoration(labelText: "Zip Code"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your zip code.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _addressCategory,
                decoration: const InputDecoration(labelText: "Address Category"),
                items: ['Home', 'Work', 'Other']
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _addressCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Set as Default Billing Address"),
                value: _isDefaultBilling,
                onChanged: (bool value) {
                  setState(() {
                    _isDefaultBilling = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _updateAddress,
                child: const Text("Update Address"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
