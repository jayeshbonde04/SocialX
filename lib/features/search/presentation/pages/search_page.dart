import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socialx/features/profile/presentation/pages/profile_page.dart';

// Reuse the same color scheme from home_page.dart
const Color primaryColor = Color(0xFF1A1A1A);
const Color secondaryColor = Color(0xFF2D2D2D);
const Color accentColor = Color(0xFF6C63FF);
const Color backgroundColor = Color(0xFF121212);
const Color surfaceColor = Color(0xFF1E1E1E);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0xFFB3B3B3);
const Color dividerColor = Color(0xFF2D2D2D);
const Color errorColor = Color(0xFFFF4B4B);

// Text styles
final TextStyle titleStyle = GoogleFonts.poppins(
  color: textPrimary,
  fontWeight: FontWeight.bold,
  fontSize: 24,
  letterSpacing: 0.5,
);

final TextStyle subtitleStyle = GoogleFonts.poppins(
  color: textSecondary,
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

final TextStyle bodyStyle = GoogleFonts.poppins(
  color: textSecondary,
  fontSize: 14,
);

final TextStyle buttonStyle = GoogleFonts.poppins(
  color: accentColor,
  fontSize: 12,
  fontWeight: FontWeight.w600,
);

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No current user found');
        return;
      }

      final usersRef = FirebaseFirestore.instance.collection('users');
      
      // Convert search query to lowercase for case-insensitive search
      final lowercaseQuery = query.toLowerCase();
      print('Searching for query: $lowercaseQuery');
      
      // Get all users first
      final allUsersSnapshot = await usersRef.get();
      print('Total users in database: ${allUsersSnapshot.docs.length}');
      
      // Filter users based on username or name
      final List<Map<String, dynamic>> results = [];
      
      for (var doc in allUsersSnapshot.docs) {
        if (doc.id == currentUser.uid) continue; // Skip current user
        
        final userData = doc.data();
        final username = userData['username']?.toString().toLowerCase() ?? '';
        final name = userData['name']?.toString().toLowerCase() ?? '';
        
        print('Checking user: $username (${userData['name']})');
        
        if (username.contains(lowercaseQuery) || name.contains(lowercaseQuery)) {
          results.add({
            'uid': doc.id,
            'username': userData['username'] ?? '',
            'name': userData['name'] ?? '',
            'profilePic': userData['profilePic'] ?? '',
          });
        }
      }

      print('Found ${results.length} matching users');
      
      // Sort results to prioritize exact matches
      results.sort((a, b) {
        final aUsername = a['username'].toString().toLowerCase();
        final bUsername = b['username'].toString().toLowerCase();
        final aName = a['name'].toString().toLowerCase();
        final bName = b['name'].toString().toLowerCase();
        
        // Check for exact matches first
        if (aUsername == lowercaseQuery) return -1;
        if (bUsername == lowercaseQuery) return 1;
        if (aName == lowercaseQuery) return -1;
        if (bName == lowercaseQuery) return 1;
        
        // Then check for starts with matches
        if (aUsername.startsWith(lowercaseQuery)) return -1;
        if (bUsername.startsWith(lowercaseQuery)) return 1;
        if (aName.startsWith(lowercaseQuery)) return -1;
        if (bName.startsWith(lowercaseQuery)) return 1;
        
        // Finally, sort alphabetically
        return aUsername.compareTo(bUsername);
      });

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Search error: $e'); // Debug print
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error searching users: ${e.toString()}',
            style: bodyStyle,
          ),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: textPrimary),
        elevation: 0,
        backgroundColor: surfaceColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Search Users',
              style: titleStyle,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: bodyStyle,
              decoration: InputDecoration(
                hintText: 'Search by username or name...',
                hintStyle: bodyStyle.copyWith(
                  color: textSecondary.withOpacity(0.5),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: textSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _searchResults = [];
                        },
                      )
                    : null,
                filled: true,
                fillColor: secondaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _searchUsers(value);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 3,
                    ),
                  )
                : _searchResults.isEmpty && _searchQuery.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: subtitleStyle,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: bodyStyle,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundImage: user['profilePic'] != null &&
                                        user['profilePic'].isNotEmpty
                                    ? NetworkImage(user['profilePic'])
                                    : null,
                                child: user['profilePic'] == null ||
                                        user['profilePic'].isEmpty
                                    ? const Icon(
                                        Icons.person_rounded,
                                        color: textSecondary,
                                        size: 24,
                                      )
                                    : null,
                              ),
                              title: Text(
                                user['name'] ?? '',
                                style: subtitleStyle,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProfilePage(uid: user['uid']),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
