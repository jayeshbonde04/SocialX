import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/services/database/database_service.dart';
import 'package:socialx/themes/app_colors.dart';
import 'package:socialx/models/message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart' as audio_player;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:audio_waveforms/audio_waveforms.dart';

import 'package:http/http.dart' as http;
import 'dart:math';

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
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingFilePath;
  bool _isRecording = false;
  String? _receiverProfilePic;
  late final RecorderController _recorderController;

  @override
  void initState() {
    super.initState();
    _loadReceiverProfilePic();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100
      ..bitRate = 128000;
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _audioRecorder.dispose();
    super.dispose();
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

      if (image != null && context.mounted) {
        // Show sending indicator immediately
        final messageDoc = await _db.createPendingMessage(
          widget.receiverUserID,
          'Sending image...',
          type: MessageType.image,
        );

        // Show image preview and upload in background
        final editedImage = await _showImagePreviewAndEdit(image.path);
        if (editedImage != null) {
          final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}${path.extension(editedImage.path)}';
          final mediaUrl = await _db.uploadMediaFile(editedImage.path, fileName);
          
          if (mediaUrl != null) {
            // Update the pending message with the actual image
            await _db.updatePendingMessage(
              messageDoc,
              'Image message',
              mediaUrl: mediaUrl,
            );
          } else {
            // Delete the pending message if upload failed
            await _db.deletePendingMessage(messageDoc);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to upload image'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        } else {
          // User cancelled, delete the pending message
          await _db.deletePendingMessage(messageDoc);
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending image: $e'),
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
        final filePath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _recordingFilePath = filePath;
        
        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );
        
        setState(() {
          _isRecording = true;
        });
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission not granted'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('Error recording audio: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = _recordingFilePath;
      await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
      });
      
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          // Create pending message immediately
          final messageDoc = await _db.createPendingMessage(
            widget.receiverUserID,
            'Sending audio...',
            type: MessageType.audio,
          );

          // Upload audio in background
          final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          final mediaUrl = await _db.uploadMediaFile(path, fileName);
          
          if (mediaUrl != null) {
            final duration = await _getDuration(path);
            // Update the pending message with the actual audio
            await _db.updatePendingMessage(
              messageDoc,
              'Audio message',
              mediaUrl: mediaUrl,
              audioDuration: duration,
            );
          } else {
            // Delete the pending message if upload failed
            await _db.deletePendingMessage(messageDoc);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to upload audio'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending audio: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<int> _getDuration(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Create a temporary player to get the duration
        final tempPlayer = audio_player.AudioPlayer();
        await tempPlayer.setSourceDeviceFile(filePath);
        final duration = await tempPlayer.getDuration();
        await tempPlayer.dispose();
        return duration?.inSeconds ?? 0;
      }
    } catch (e) {
      print('Error getting audio duration: $e');
    }
    return 0;
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
                    ? const Icon(
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
    final bool isPending = message.status == MessageStatus.pending;

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
                color: isPending 
                    ? AppColors.primary.withOpacity(0.5)
                    : isCurrentUser ? AppColors.primary : AppColors.surface,
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
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: isCurrentUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (message.type == MessageType.text)
                        Text(
                          message.message,
                          style: GoogleFonts.poppins(
                            color: isCurrentUser ? AppColors.third : AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        )
                      else if (message.type == MessageType.image)
                        message.mediaUrl != null
                            ? GestureDetector(
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
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                        : null,
                                                    color: AppColors.primary,
                                                  ),
                                                );
                                              },
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
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return SizedBox(
                                        width: 200,
                                        height: 200,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )
                            : Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Uploading image...',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                      else if (message.type == MessageType.audio)
                        message.mediaUrl != null
                            ? AudioMessageBubble(
                                audioUrl: message.mediaUrl!,
                                isCurrentUser: isCurrentUser,
                                duration: message.audioDuration,
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Uploading audio...',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTimestamp(message.timestamp),
                            style: GoogleFonts.poppins(
                              color: (isCurrentUser ? Colors.white : AppColors.textPrimary)
                                  .withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 4),
                            _buildMessageStatus(message),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (isPending)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
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

  Widget _buildMessageStatus(Message message) {
    final double size = 12;
    final color = Colors.white.withOpacity(0.7);

    switch (message.status) {
      case MessageStatus.pending:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            color: color,
          ),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: size,
          color: color,
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: size,
          color: color,
        );
      case MessageStatus.seen:
        return Icon(
          Icons.done_all,
          size: size,
          color: Colors.blue[300],
        );
    }
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
            if (_isRecording)
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.mic,
                        color: AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AudioWaveforms(
                          enableGesture: true,
                          size: Size(MediaQuery.of(context).size.width * 0.5, 50),
                          recorderController: _recorderController,
                          waveStyle: WaveStyle(
                            waveColor: AppColors.primary,
                            extendWaveform: true,
                            showMiddleLine: false,
                            spacing: 4.0,
                            waveThickness: 2.0,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.stop,
                          color: AppColors.error,
                        ),
                        onPressed: _stopRecording,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.mic_outlined,
                    color: AppColors.primary,
                  ),
                  onPressed: _startRecording,
                ),
              ),
            if (!_isRecording) ...[
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

class AudioMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isCurrentUser;
  final int? duration;

  const AudioMessageBubble({
    Key? key,
    required this.audioUrl,
    required this.isCurrentUser,
    this.duration,
  }) : super(key: key);

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final audio_player.AudioPlayer _audioPlayer = audio_player.AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _localPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _downloadAndPrepareAudio();
  }

  Future<void> _downloadAndPrepareAudio() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final localPath = '${tempDir.path}/$fileName';

      final response = await http.get(Uri.parse(widget.audioUrl));
      if (response.statusCode == 200) {
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _localPath = localPath;
          _isLoading = false;
        });
      } else {
        print('Error downloading audio: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error preparing audio: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == audio_player.PlayerState.playing;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isCurrentUser ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isLoading 
                  ? Icons.hourglass_empty
                  : _isPlaying 
                      ? Icons.pause_rounded 
                      : Icons.play_arrow_rounded,
              color: widget.isCurrentUser ? Colors.white : AppColors.primary,
              size: 28,
            ),
            onPressed: _isLoading 
                ? null 
                : () async {
                    if (_localPath == null) return;
                    
                    if (_isPlaying) {
                      await _audioPlayer.pause();
                    } else {
                      await _audioPlayer.play(audio_player.DeviceFileSource(_localPath!));
                    }
                  },
          ),
          const SizedBox(width: 4),
          Container(
            width: 110,
            height: 40,
            decoration: BoxDecoration(
              color: widget.isCurrentUser 
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: _isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.isCurrentUser 
                            ? Colors.white 
                            : AppColors.primary,
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(
                      painter: WaveformPainter(
                        color: widget.isCurrentUser 
                            ? Colors.white 
                            : AppColors.primary,
                        progress: _isPlaying 
                            ? _position.inMilliseconds / (_duration.inMilliseconds.toDouble().clamp(1, double.infinity))
                            : 0,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _isPlaying
                  ? _formatDuration(_position)
                  : _formatDuration(_duration),
              style: GoogleFonts.poppins(
                color: widget.isCurrentUser ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final Color color;
  final double progress;

  WaveformPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const spacing = 4.0;
    final barWidth = 2.0;
    final numBars = (size.width / (barWidth + spacing)).floor();
    
    for (var i = 0; i < numBars; i++) {
      final x = i * (barWidth + spacing);
      final normalizedX = i / numBars;
      final height = size.height * (0.2 + 0.6 * _generateRandomHeight(normalizedX));
      
      final top = (size.height - height) / 2;
      final bottom = top + height;
      
      if (normalizedX <= progress) {
        canvas.drawLine(
          Offset(x, top),
          Offset(x, bottom),
          progressPaint,
        );
      } else {
        canvas.drawLine(
          Offset(x, top),
          Offset(x, bottom),
          paint,
        );
      }
    }
  }

  double _generateRandomHeight(double x) {
    // Use a simple sine wave to generate pseudo-random heights
    return (sin(x * 5) + 1) / 2;
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
