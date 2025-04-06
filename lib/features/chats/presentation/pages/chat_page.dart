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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.accent),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.poppins(
                    color: AppColors.textPrimary
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromSource(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.accent),
              title: Text(
                'Take a Photo',
                style: GoogleFonts.poppins(
                    color: AppColors.textPrimary
                ),
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<XFile?> _showImagePreviewAndEdit(String imagePath) async {
    return showDialog<XFile>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
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
                    label: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                          color: AppColors.textPrimary
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      // Here you can add image editing functionality
                      // For now, we'll just send the original image
                      Navigator.pop(context, XFile(imagePath));
                    },
                    icon: const Icon(Icons.check, color: AppColors.accent),
                    label: Text(
                      'Send',
                      style: GoogleFonts.poppins(color: AppColors.accent),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: _receiverProfilePic != null
                    ? NetworkImage(_receiverProfilePic!)
                    : null,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: _receiverProfilePic == null
                    ? Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 24,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverUserEmail,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Online',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
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
          _buildMessageInput(),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
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
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading messages',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
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
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
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
                color: isCurrentUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: Radius.circular(isCurrentUser ? 20 : 0),
                  bottomRight: Radius.circular(isCurrentUser ? 0 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.1),
                    blurRadius: 8,
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
                      style: GoogleFonts.poppins(
                        color: isCurrentUser ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    )
                  else if (message.type == MessageType.image)
                    GestureDetector(
                      onTap: () {
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
                                    icon: Icon(
                                      Icons.close,
                                      color: AppColors.textPrimary,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
                          icon: Icon(
                            Icons.play_arrow,
                            color: isCurrentUser
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          onPressed: () => _playAudio(message.mediaUrl!),
                        ),
                        Text(
                          '${message.audioDuration ?? 0}s',
                          style: GoogleFonts.poppins(
                            color: isCurrentUser
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: GoogleFonts.poppins(
                      color: (isCurrentUser ? Colors.white : AppColors.textPrimary)
                          .withOpacity(0.7),
                      fontSize: 10,
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.accent),
              title: Text(
                'Edit Message',
                style: GoogleFonts.poppins(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditMessageDialog(document);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: Text(
                'Delete Message',
                style: GoogleFonts.poppins(color: AppColors.textPrimary),
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
        backgroundColor: AppColors.surface,
        title: Text(
          'Edit Message',
          style: GoogleFonts.poppins(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: editController,
          style: GoogleFonts.poppins(color: AppColors.primary),
          decoration: InputDecoration(
            hintText: 'Edit your message...',
            hintStyle: GoogleFonts.poppins(color: AppColors.textHint),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (editController.text.isNotEmpty) {
                _db.updateMessage(document.id, editController.text);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: AppColors.accent),
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
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Message',
          style: GoogleFonts.poppins(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this message?',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textPrimary) ,
            ),
          ),
          TextButton(
            onPressed: () {
              _db.deleteMessage(document.id);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: AppColors.error),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.photo_outlined,
                  color: AppColors.primary,
                ),
                onPressed: _pickImage,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic_outlined,
                  color: _isRecording ? AppColors.error : AppColors.primary,
                ),
                onPressed: _isRecording ? _stopRecording : _startRecording,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
