import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gift_shop/Authentication/Settings/ShippingAddress.dart';
import 'package:gift_shop/language_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.black),
                Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: const Text(
                      "10",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _SettingsSection(title: "Account", children: [
            _SettingsTile(
              title: "Shipping Address",
              icon: Icons.location_on,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShippingAddressPage(),
                  ),
                );
              },
            ),
            _SettingsTile(
              title: "Payment Method",
              icon: Icons.credit_card,
              onTap: () {
                // Navigate to payment method page
              },
            ),
            _SettingsTile(
              title: "Payment Currency",
              icon: Icons.monetization_on,
              trailing: const Text("BDT"),
              onTap: () {
                // Navigate to currency selection page
              },
            ),
            _SettingsTile(
              title: "Language",
              icon: Icons.language,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showLanguageDialog(context);
              },
            ),
          ]),
          const SizedBox(height: 20),
          _SettingsSection(title: "More", children: [
            _SettingsTile(
              title: "Notification Settings",
              icon: Icons.notifications,
              onTap: () {
                // Navigate to notification settings
              },
            ),
            _SettingsTile(
              title: "Privacy Policy",
              icon: Icons.lock,
              onTap: () {
                // Navigate to privacy policy
              },
            ),
            _SettingsTile(
              title: "Frequently Asked Questions",
              icon: Icons.question_answer,
              onTap: () {
                // Navigate to FAQ
              },
            ),
            _SettingsTile(
              title: "Legal Information",
              icon: Icons.info,
              onTap: () {
                // Navigate to legal information
              },
            ),
          ]),
        ],
      ),
    );
  }

  /// Shows a dialog with a dropdown to change the app language
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Language"),
          content: _LanguageDropdown(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

class _LanguageDropdown extends StatefulWidget {
  @override
  _LanguageDropdownState createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<_LanguageDropdown> {
  final Map<String, Locale> languages = {
    "English": const Locale('en', 'US'),
    "Español": const Locale('es', 'ES'),
    "Français": const Locale('fr', 'FR'),
    "Deutsch": const Locale('de', 'DE'),
    "বাংলা": const Locale('bn', 'BD'),
    "हिन्दी": const Locale('hi', 'IN'),
    "العربية": const Locale('ar', 'AE'),
    "中文": const Locale('zh', 'CN'),
  };

  String selectedLanguage = "English";

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedLanguage,
      isExpanded: true,
      items: languages.keys.map((String language) {
        return DropdownMenuItem<String>(
          value: language,
          child: Text(language),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            selectedLanguage = newValue;
          });
          Provider.of<LanguageProvider>(context, listen: false)
              .changeLanguage(languages[newValue]!);
        }
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.icon,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
