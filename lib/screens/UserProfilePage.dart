import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'editprofile_screen.dart';
import 'BuyPackages&MyOrders.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and edit profile
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage('assets/images/usericon.png'),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.userMetadata?['full_name'] ?? 'Shubhalina Radu Kakaty',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'View and Edit Profile',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // 2 steps left section
                  //
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.info_outline, color: Colors.blue),
                  //       SizedBox(width: 8),
                  //       Expanded(
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             Text(
                  //               '2 steps left',
                  //               style: TextStyle(
                  //                 fontWeight: FontWeight.bold,
                  //               ),
                  //             ),
                  //             Text(
                  //               'We are built on trust. Help one another to get to know each other better',
                  //               style: TextStyle(
                  //                 fontSize: 12,
                  //                 color: Colors.grey.shade600,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                    // Uncomment and complete the child Row above if needed
                ],
              ),
              SizedBox(height: 24),
              // Menu items
              _buildMenuItem(
                title: 'Buy Packages & My Orders',
                subtitle: 'Packages, orders, invoices & billing information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BuyPackagesOrdersScreen(),
                    ),
                  );
                },
               ),
              _buildDivider(),
              _buildMenuItem(
                title: 'Wishlist',
                subtitle: 'View your liked items here',
              ),
              _buildDivider(),
              _buildMenuItem(
                title: 'Settings',
                subtitle: 'Privacy and logout',
              ),
              _buildDivider(),
              _buildMenuItem(
                title: 'Help and Support',
                subtitle: 'Help center, Terms and conditions, Privacy policy',
              ),
              _buildDivider(),
            
              // Logout button
              SizedBox(height: 24),
              Center(
                child: OutlinedButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (_) => false,
                      );
                    }
                  },
                  child: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update the _buildMenuItem function to include onTap parameter:
Widget _buildMenuItem({
  required String title,
  required String subtitle,
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
    );
  }
}