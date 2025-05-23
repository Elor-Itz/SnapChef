import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'widgets/friends_list.dart';
import 'widgets/settings_menu.dart';
import '../../utils/image_util.dart';
import '../../viewmodels/friend_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch the user profile when the screen is initialized
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      userViewModel.fetchUserData();
      // Fetch friends when the screen is initialized
      final friendViewModel =
          Provider.of<FriendViewModel>(context, listen: false);
      friendViewModel.fetchFriends();
    });
  }

  // Open the side menu with a sliding animation
  void _openSideMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SettingsMenu();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset(0.0, 0.0);
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  // Open the friends list with a sliding animation
  void _openFriendsList(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,                
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Header with Close Button
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 26),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Friends',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Expanded(child: FriendsList()),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset(0.0, 0.0);
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  // Format the join date
  String _formatJoinDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final date = DateTime.parse(rawDate);
      return 'Joined ${DateFormat.yMMMMd().format(date)}';
    } catch (e) {
      return rawDate; // fallback to raw if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    final friendViewModel = Provider.of<FriendViewModel>(context);

    final int friendCount = friendViewModel.friends.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _openSideMenu(context),
          ),
        ],
      ),
      body: userViewModel.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile data...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : userViewModel.user == null
              ? const Center(
                  child: Text(
                    'Failed to load profile data',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Picture
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 80,
                              backgroundImage: userViewModel
                                          .user?.profilePicture !=
                                      null
                                  ? NetworkImage(ImageUtil().getFullImageUrl(
                                          userViewModel.user!.profilePicture!))
                                      as ImageProvider
                                  : const AssetImage(
                                          'assets/images/default_profile.png')
                                      as ImageProvider,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // User Full Name
                        Text(
                          userViewModel.user?.fullName ?? 'Unknown User',
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        // User Email and Join Date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: const Icon(Icons.email,
                                      color: Colors.grey, size: 20),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  userViewModel.user?.email ?? 'No Email',
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: const Icon(Icons.calendar_today,
                                      color: Colors.grey, size: 20),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatJoinDate(userViewModel.user?.joinDate),
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Friends count button
                        Center(
                          child: GestureDetector(
                            onTap: () => _openFriendsList(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.group,
                                      color: Colors.black, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    '$friendCount Friend${friendCount == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.black54, size: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // ... (rest of your profile content)
                      ],
                    ),
                  ),
                ),
    );
  }
}
