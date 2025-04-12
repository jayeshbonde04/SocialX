import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/presentation/components/my_textfield.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/posts/domain/entities/post.dart';
import 'package:socialx/features/posts/presentation/cubits/post_cubit.dart';
import 'package:socialx/features/posts/presentation/cubits/post_states.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:extended_image/extended_image.dart';
import 'package:socialx/themes/app_colors.dart';
import 'package:socialx/storage/domain/storage_repo.dart';

// Dark mode color scheme
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

class UploadPostPage extends StatefulWidget {
  const UploadPostPage({super.key});

  @override
  State<UploadPostPage> createState() => _UploadPostPageState();
}

class _UploadPostPageState extends State<UploadPostPage> {
  //mobile image pick
  PlatformFile? imagePickedFile;
  XFile? pickedXFile;

  //web image pick
  Uint8List? webImage;

  //text controller -> caption
  final textEditingController = TextEditingController();

  //current user
  AppUsers? currentUser;

  //get current user
  void getCurrentUser() async {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentuser;
  }

  //select image
  Future<void> pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Image Source',
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImageFromSource(ImageSource.gallery);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImageFromSource(ImageSource.camera);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
        // For camera captures, show the editor immediately
        if (source == ImageSource.camera) {
          final editedImage = await _showImageEditor(image.path);
          if (editedImage != null && context.mounted) {
            setState(() {
              pickedXFile = editedImage;
              imagePickedFile = PlatformFile(
                name: editedImage.name,
                path: editedImage.path,
                size: File(editedImage.path).lengthSync(),
                bytes: kIsWeb ? File(editedImage.path).readAsBytesSync() : null,
              );
              if (kIsWeb) {
                webImage = imagePickedFile?.bytes;
              }
            });
          }
        } else {
          // For gallery images, show the preview dialog first
          final editedImage = await _showPreviewDialog(image.path);
          if (editedImage != null && context.mounted) {
            setState(() {
              pickedXFile = editedImage;
              imagePickedFile = PlatformFile(
                name: editedImage.name,
                path: editedImage.path,
                size: File(editedImage.path).lengthSync(),
                bytes: kIsWeb ? File(editedImage.path).readAsBytesSync() : null,
              );
              if (kIsWeb) {
                webImage = imagePickedFile?.bytes;
              }
            });
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error picking image: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<XFile?> _showImageEditor(String imagePath) async {
    try {
      // Create a temporary file for the edited image
      final String targetPath = '${imagePath}_edited.jpg';
      final File editedFile = File(targetPath);
      
      // Show image editor
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => _SimpleImageEditorScreen(
            imagePath: imagePath,
            onSave: (Uint8List imageData) async {
              try {
                // Save the edited image data to a file
                await editedFile.writeAsBytes(imageData);
                
                // Compress the edited image
                final compressedPath = '${targetPath}_compressed.jpg';
                final result = await FlutterImageCompress.compressAndGetFile(
                  editedFile.path,
                  compressedPath,
                  quality: 85,
                  minWidth: 800,
                  minHeight: 800,
                );
                
                if (result != null) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to compress image',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error saving image: $e',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ),
      );
      
      if (result == true) {
        // Return the compressed image file
        final compressedPath = '${targetPath}_compressed.jpg';
        if (File(compressedPath).existsSync()) {
          return XFile(compressedPath);
        }
      }
    } catch (e) {
      print('Error editing image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error editing image: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    return null;
  }

  Widget _buildFilterButton(String label, ColorFilter? filter, ColorFilter? currentFilter, Function(ColorFilter?) onFilterSelected, String imagePath) {
    final bool isSelected = filter == currentFilter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => onFilterSelected(filter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.2),
                  width: isSelected ? 3 : 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ColorFiltered(
                  colorFilter: filter ?? const ColorFilter.mode(
                    Colors.transparent,
                    BlendMode.srcOver,
                  ),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<XFile?> _showPreviewDialog(String imagePath) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final editedImage = await _showImageEditor(imagePath);
                          if (editedImage != null && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                        icon: Icon(
                          Icons.edit,
                          color: AppColors.primary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context, false),
                    icon: Icon(Icons.close, color: AppColors.textPrimary),
                    label: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(color: AppColors.textPrimary),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check),
                    label: Text(
                      'Use Photo',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
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
    
    return result == true ? XFile(imagePath) : null;
  }

  //compress image
  // Future<void> compressImage() async {
  //   final result = await FlutterImageCompress.compressWithFile(
  //     imagePickedFile!.path!,
  //     minWidth: 800,
  //     minHeight: 800,
  //     quality: 80,
  //   );
  //
  //   setState(() {
  //     webImage = result;
  //   });
  // }

  //create & upload post
  void uploadPost() async {
    if (imagePickedFile == null || textEditingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select an image and write a caption',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // Show loading state
      setState(() {});

      // Create post first
      final newPost = Post(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser!.uid,
        userName: currentUser!.name,
        text: textEditingController.text,
        imageUrl: '', // Initially empty
        timestamp: DateTime.now(),
        likes: [],
        comment: [],
      );

      if (kIsWeb) {
        // Upload image for web
        await context.read<PostCubit>().createPost(
          newPost,
          imageBytes: imagePickedFile?.bytes,
        );
      } else {
        // Upload image for mobile
        await context.read<PostCubit>().createPost(
          newPost,
          imagePath: imagePickedFile?.path,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error creating post: ${e.toString()}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostCubit, PostState>(
      builder: (context, state) {
        if (state is PostsLoading || state is PostsUploading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    state is PostsUploading ? 'Creating your post...' : 'Loading...',
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return buildUploadPage();
      },
      listener: (context, state) {
        if (state is PostsLoaded) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget buildUploadPage() {
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
          'Create Post',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: uploadPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Share',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: imagePickedFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to add a photo',
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Share your moments with others',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              kIsWeb
                                  ? Image.memory(
                                      webImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(imagePickedFile!.path!),
                                      fit: BoxFit.cover,
                                    ),
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: IconButton.filled(
                                  onPressed: pickImage,
                                  icon: const Icon(Icons.edit),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: textEditingController,
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Write a caption...',
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleImageEditorScreen extends StatefulWidget {
  final String imagePath;
  final Function(Uint8List) onSave;

  const _SimpleImageEditorScreen({
    required this.imagePath,
    required this.onSave,
  });

  @override
  State<_SimpleImageEditorScreen> createState() => _SimpleImageEditorScreenState();
}

class _SimpleImageEditorScreenState extends State<_SimpleImageEditorScreen> {
  ColorFilter? currentFilter;
  double _scale = 1.0;
  double _rotation = 0.0;
  Offset _offset = Offset.zero;
  Offset _startOffset = Offset.zero;
  bool _isDragging = false;
  final GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Edit Image',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () async {
              try {
                // Capture the rendered image with the filter applied
                final RenderRepaintBoundary boundary = _imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                final image = await boundary.toImage(pixelRatio: 3.0);
                final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                
                if (byteData != null) {
                  final Uint8List imageBytes = byteData.buffer.asUint8List();
                  widget.onSave(imageBytes);
                } else {
                  throw Exception('Failed to capture image data');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error saving image: $e',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _imageKey,
              child: GestureDetector(
                onScaleStart: (details) {
                  setState(() {
                    _isDragging = true;
                    _startOffset = details.focalPoint;
                  });
                },
                onScaleUpdate: (details) {
                  setState(() {
                    if (details.scale != 1.0) {
                      _scale = (_scale * details.scale).clamp(0.5, 3.0);
                    }
                    
                    if (details.rotation != 0.0) {
                      _rotation += details.rotation;
                    }
                    
                    if (_isDragging) {
                      _offset += details.focalPoint - _startOffset;
                      _startOffset = details.focalPoint;
                    }
                  });
                },
                onScaleEnd: (details) {
                  setState(() {
                    _isDragging = false;
                  });
                },
                child: Center(
                  child: Transform(
                    transform: Matrix4.identity()
                      ..scale(_scale)
                      ..rotateZ(_rotation)
                      ..translate(_offset.dx, _offset.dy),
                    child: ColorFiltered(
                      colorFilter: currentFilter ?? const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.srcOver,
                      ),
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterButton(
                  'Normal',
                  null,
                  currentFilter,
                  (filter) {
                    setState(() {
                      currentFilter = filter;
                    });
                  },
                  widget.imagePath,
                ),
                _buildFilterButton(
                  'Grayscale',
                  ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  currentFilter,
                  (filter) {
                    setState(() {
                      currentFilter = filter;
                    });
                  },
                  widget.imagePath,
                ),
                _buildFilterButton(
                  'Sepia',
                  ColorFilter.matrix([
                    0.393, 0.769, 0.189, 0, 0,
                    0.349, 0.686, 0.168, 0, 0,
                    0.272, 0.534, 0.131, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  currentFilter,
                  (filter) {
                    setState(() {
                      currentFilter = filter;
                    });
                  },
                  widget.imagePath,
                ),
                _buildFilterButton(
                  'Invert',
                  ColorFilter.matrix([
                    -1, 0, 0, 0, 255,
                    0, -1, 0, 0, 255,
                    0, 0, -1, 0, 255,
                    0, 0, 0, 1, 0,
                  ]),
                  currentFilter,
                  (filter) {
                    setState(() {
                      currentFilter = filter;
                    });
                  },
                  widget.imagePath,
                ),
                _buildFilterButton(
                  'Brightness',
                  ColorFilter.matrix([
                    1.2, 0, 0, 0, 0,
                    0, 1.2, 0, 0, 0,
                    0, 0, 1.2, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  currentFilter,
                  (filter) {
                    setState(() {
                      currentFilter = filter;
                    });
                  },
                  widget.imagePath,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, ColorFilter? filter, ColorFilter? currentFilter, Function(ColorFilter?) onFilterSelected, String imagePath) {
    final bool isSelected = filter == currentFilter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => onFilterSelected(filter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.2),
                  width: isSelected ? 3 : 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ColorFiltered(
                  colorFilter: filter ?? const ColorFilter.mode(
                    Colors.transparent,
                    BlendMode.srcOver,
                  ),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
