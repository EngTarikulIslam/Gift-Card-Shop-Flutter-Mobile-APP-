import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gift_shop/Authentication/Login.dart';
import 'package:gift_shop/Authentication/Home.dart';
import 'package:gift_shop/Authentication/Settings/EiditProfile.dart';
import 'package:gift_shop/Authentication/Settings.dart';
import 'package:gift_shop/Authentication/Settings/pendingPayment.dart';
import 'package:gift_shop/Authentication/Settings/pendingShipment.dart';
import 'package:gift_shop/Authentication/Settings/FinishedOrder.dart';
import 'package:gift_shop/Authentication/Settings/AllOrders.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  String email = "";
  String gender = "";
  String profileImage = 'assets/other_profile.png'; // Default profile picture

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Function to load user data from Firebase
  void _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch the user's Firestore document
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          // Assuming the Firestore document has 'username', 'gender', and 'email' fields
          name = userDoc['username'] ?? "Username not set";
          email = user.email ?? "user@example.com";
          gender = userDoc['gender'] ?? "other"; // Default to "other" if gender is not set

          // Set the profile picture based on gender
          if (gender == "Male") {
            profileImage = 'assets/male_profile.png'; // Male profile picture
          } else if (gender == "Female") {
            profileImage = 'assets/female_profile.png'; // Female profile picture
          } else {
            profileImage = 'assets/other_profile.png'; // Other or default profile picture
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()), // Navigate to HomePage
            );
          },
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black),
                onPressed: () {
                  // Handle notifications
                },
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(profileImage), // Use dynamic profile image
              ),
              const SizedBox(height: 10),
              Text(
                name.isEmpty ? 'Loading...' : name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                email.isEmpty ? 'Loading...' : email,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Edit Profile"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _logout(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xfff24848),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Log Out",
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              // Profile Menu Items
              ProfileMenuItem(
                icon: Icons.list_alt,
                title: "All My Orders",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllOrders(),
                    ),
                  );
                },
              ),
              ProfileMenuItem(
                icon: Icons.local_shipping,
                title: "Pending Shipments",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PendingShipment(),
                    ),
                  );
                },
              ),

              ProfileMenuItem(
                icon: Icons.check_circle,
                title: "Pending Payments",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PendingPaymentListPage(),
                    ),
                  );
                },
              ),
              ProfileMenuItem(
                icon: Icons.payment,
                title: "Finished Orders",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Finishedorder(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              ProfileMenuItem(
                icon: Icons.settings,
                title: "Settings",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
              const ProfileMenuItem(
                icon: Icons.group,
                title: "Invite Friends",
              ),
              const ProfileMenuItem(
                icon: Icons.star,
                title: "Rate Our App",
              ),
              const ProfileMenuItem(
                icon: Icons.support,
                title: "Customer Support",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Logout function
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); // Log out from Firebase
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()), // Redirect to Login
    );
  }
}

// Profile Menu Item Widget
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap; // Add onTap as an optional parameter

  const ProfileMenuItem({
    required this.icon,
    required this.title,
    this.onTap, // Initialize it
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap, // Trigger the onTap callback
    );
  }
}
