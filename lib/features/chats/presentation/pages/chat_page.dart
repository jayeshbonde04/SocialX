import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/services/database/database_service.dart';
import 'package:socialx/themes/app_colors.dart';
import 'package:socialx/models/message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

// Reuse the same color scheme
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
  color: AppColors.textPrimary,
  fontWeight: FontWeight.bold,
  fontSize: 24,
  letterSpacing: 0.5,
);

final TextStyle subtitleStyle = GoogleFonts.poppins(
  color: AppColors.textSecondary,
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

final TextStyle bodyStyle = GoogleFonts.poppins(
  color: AppColors.textSecondary,
  fontSize: 14,
);

class ChatPage extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;
  const ChatPage({
    super.key,
    required this.receiverUserEmail,
    required this.receiverUserID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String? _receiverProfilePic;

  @override
  void initState() {
    super.initState();
    _loadReceiverProfilePic();
    _audioRecorder = AudioRecorder();
  }

  Future<void> _loadReceiverProfilePic() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverUserID)
        .get();
    if (userDoc.exists) {
      setState(() {
        _receiverProfilePic = userDoc.data()?['profileImageUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: accentColor),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromSource(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: accentColor),
              title: const Text(
                'Take a Photo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromSource(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Show image preview and editing options
        if (context.mounted) {
          final editedImage = await _showImagePreviewAndEdit(image.path);
          if (editedImage != null) {
            final fileName = path.basename(editedImage.path);
            final mediaUrl =
                await _db.uploadMediaFile(editedImage.path, fileName);
            if (mediaUrl != null) {
              await _db.sendMessage(
                widget.receiverUserID,
                'Image message',
                type: MessageType.image,
                mediaUrl: mediaUrl,
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  Future<XFile?> _showImagePreviewAndEdit(String imagePath) async {
    return showDialog<XFile>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: surfaceColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      // Here you can add image editing functionality
                      // For now, we'll just send the original image
                      Navigator.pop(context, XFile(imagePath));
                    },
                    icon: const Icon(Icons.check, color: accentColor),
                    label: const Text(
                      'Send',
                      style: TextStyle(color: accentColor),
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

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/audio_message.m4a';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('Error recording audio: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final filePath = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      if (filePath != null) {
        final fileName = path.basename(filePath);
        final mediaUrl = await _db.uploadMediaFile(filePath, fileName);
        if (mediaUrl != null) {
          await _db.sendMessage(
            widget.receiverUserID,
            'Audio message',
            type: MessageType.audio,
            mediaUrl: mediaUrl,
            audioDuration: 0, // You might want to calculate actual duration
          );
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      print('Error playing audio: $e');
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
            CircleAvatar(
              radius: 20,
              backgroundImage: _receiverProfilePic != null
                  ? NetworkImage(_receiverProfilePic!)
                  : null,
              backgroundColor: accentColor.withOpacity(0.1),
              child: _receiverProfilePic == null
                  ? const Icon(
                      Icons.person_rounded,
                      color: accentColor,
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverUserEmail,
                    style: subtitleStyle.copyWith(color: textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          const Divider(height: 1, color: dividerColor),
          _buildMessageInput(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.getMessages(widget.receiverUserID, _auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: errorColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading messages',
                  style: subtitleStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: bodyStyle,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: accentColor,
              strokeWidth: 3,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
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
                    Icons.message_outlined,
                    size: 64,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: subtitleStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: bodyStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final document = snapshot.data!.docs[index];
            return _buildMessageItem(document);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final message = Message.fromMap(data);
    final bool isCurrentUser = message.senderEmail == _auth.currentUser!.uid;

    return GestureDetector(
      onLongPress: isCurrentUser ? () => _showMessageOptions(document) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(
                left: isCurrentUser ? 64 : 0,
                right: isCurrentUser ? 0 : 64,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser ? accentColor : surfaceColor,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 0),
                  bottomRight: Radius.circular(isCurrentUser ? 0 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.text)
                    Text(
                      message.message,
                      style: const TextStyle(color: Colors.white),
                    )
                  else if (message.type == MessageType.image)
                    GestureDetector(
                      onTap: () {
                        // Show full-screen image
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  child: Image.network(
                                    message.mediaUrl!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          message.mediaUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else if (message.type == MessageType.audio)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.play_arrow, color: Colors.white),
                          onPressed: () => _playAudio(message.mediaUrl!),
                        ),
                        Text(
                          '${message.audioDuration ?? 0}s',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
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

  void _showMessageOptions(DocumentSnapshot document) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: accentColor),
              title: const Text(
                'Edit Message',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditMessageDialog(document);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: errorColor),
              title: const Text(
                'Delete Message',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(document);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMessageDialog(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final message = Message.fromMap(data);
    final TextEditingController editController =
        TextEditingController(text: message.message);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: const Text(
          'Edit Message',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Edit your message...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              if (editController.text.isNotEmpty) {
                _db.updateMessage(document.id, editController.text);
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: accentColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(DocumentSnapshot document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: const Text(
          'Delete Message',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this message?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              _db.deleteMessage(document.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo, color: accentColor),
            onPressed: _pickImage,
          ),
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: _isRecording ? errorColor : accentColor,
            ),
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: secondaryColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: accentColor),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                _db.sendMessage(
                  widget.receiverUserID,
                  _messageController.text,
                );
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
