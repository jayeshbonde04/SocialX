import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socialx/features/profile/presentation/pages/profile_page.dart';
import 'package:socialx/themes/app_colors.dart';

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
      final lowercaseQuery = query.toLowerCase();
      final allUsersSnapshot = await usersRef.get();
      final List<Map<String, dynamic>> results = [];
      
      for (var doc in allUsersSnapshot.docs) {
        if (doc.id == currentUser.uid) continue;
        
        final userData = doc.data();
        final username = userData['username']?.toString().toLowerCase() ?? '';
        final name = userData['name']?.toString().toLowerCase() ?? '';
        
        if (username.contains(lowercaseQuery) || name.contains(lowercaseQuery)) {
          results.add({
            'uid': doc.id,
            'username': userData['username'] ?? '',
            'name': userData['name'] ?? '',
            'profilePic': userData['profileImageUrl'] ?? '',
            'bio': userData['bio'] ?? '',
          });
        }
      }
      
      results.sort((a, b) {
        final aUsername = a['username'].toString().toLowerCase();
        final bUsername = b['username'].toString().toLowerCase();
        final aName = a['name'].toString().toLowerCase();
        final bName = b['name'].toString().toLowerCase();
        
        if (aUsername == lowercaseQuery) return -1;
        if (bUsername == lowercaseQuery) return 1;
        if (aName == lowercaseQuery) return -1;
        if (bName == lowercaseQuery) return 1;
        
        if (aUsername.startsWith(lowercaseQuery)) return -1;
        if (bUsername.startsWith(lowercaseQuery)) return 1;
        if (aName.startsWith(lowercaseQuery)) return -1;
        if (bName.startsWith(lowercaseQuery)) return 1;
        
        return aUsername.compareTo(bUsername);
      });

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error searching users: ${e.toString()}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search Users',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
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
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _searchResults.isEmpty && _searchQuery.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
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
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  backgroundImage: user['profilePic'] != null &&
                                          user['profilePic'].isNotEmpty
                                      ? NetworkImage(user['profilePic'])
                                      : null,
                                  child: user['profilePic'] == null ||
                                          user['profilePic'].isEmpty
                                      ? Icon(
                                          Icons.person_rounded,
                                          color: AppColors.primary,
                                          size: 24,
                                        )
                                      : null,
                                ),
                              ),
                              title: Text(
                                user['name'] ?? '',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (user['username'] != null && user['username'].isNotEmpty)
                                    Text(
                                      '@${user['username']}',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (user['bio'] != null && user['bio'].isNotEmpty)
                                    Text(
                                      user['bio'],
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(uid: user['uid']),
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
