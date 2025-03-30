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
      if (currentUser == null) return;

      final usersRef = FirebaseFirestore.instance.collection('users');
      
      // Search by username
      final usernameQuery = await usersRef
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();

      // Search by name
      final nameQuery = await usersRef
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      // Combine and deduplicate results
      final Set<String> seenUids = {};
      final List<Map<String, dynamic>> results = [];

      // Process username results
      for (var doc in usernameQuery.docs) {
        if (doc.id != currentUser.uid && !seenUids.contains(doc.id)) {
          seenUids.add(doc.id);
          results.add({
            'uid': doc.id,
            'username': doc.data()['username'] ?? '',
            'name': doc.data()['name'] ?? '',
            'profilePic': doc.data()['profilePic'] ?? '',
          });
        }
      }

      // Process name results
      for (var doc in nameQuery.docs) {
        if (doc.id != currentUser.uid && !seenUids.contains(doc.id)) {
          seenUids.add(doc.id);
          results.add({
            'uid': doc.id,
            'username': doc.data()['username'] ?? '',
            'name': doc.data()['name'] ?? '',
            'profilePic': doc.data()['profilePic'] ?? '',
          });
        }
      }

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
