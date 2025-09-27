import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class FarmerCommunityPage extends StatefulWidget {
  const FarmerCommunityPage({super.key});

  @override
  State<FarmerCommunityPage> createState() => _FarmerCommunityPageState();
}

class _FarmerCommunityPageState extends State<FarmerCommunityPage> {
  final TextEditingController _postController = TextEditingController();
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, bool> _expandedPosts = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // For post creation
  List<File> _selectedImages = [];
  File? _selectedVideo;
  bool _isUploading = false;

  // Mock user (in real app, get from authentication)
  final String currentUser = 'farmer_${DateTime.now().millisecondsSinceEpoch % 1000}';

  @override
  void dispose() {
    _postController.dispose();
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((image) => File(image.path)).toList();
        _selectedVideo = null; // Clear video if images selected
      });
    }
  }

  Future<void> _pickVideo({bool fromCamera = false}) async {
    final XFile? video = await _picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(minutes: 2), // Limit video length
    );
    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
        _selectedImages.clear(); // Clear images if video selected
      });
    }
  }

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages = [File(image.path)];
        _selectedVideo = null;
      });
    }
  }

  void _clearMedia() {
    setState(() {
      _selectedImages.clear();
      _selectedVideo = null;
    });
  }

  Future<List<String>> _uploadImages(List<File> images) async {
    List<String> downloadUrls = [];

    for (int i = 0; i < images.length; i++) {
      final ref = _storage.ref().child('posts/images/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      final uploadTask = ref.putFile(images[i]);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }

    return downloadUrls;
  }

  Future<String> _uploadVideo(File video) async {
    final ref = _storage.ref().child('posts/videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
    final uploadTask = ref.putFile(video);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _addPost() async {
    if (_postController.text.trim().isEmpty && _selectedImages.isEmpty && _selectedVideo == null) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      List<String> imageUrls = [];
      String? videoUrl;

      // Upload images
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages(_selectedImages);
      }

      // Upload video
      if (_selectedVideo != null) {
        videoUrl = await _uploadVideo(_selectedVideo!);
      }

      await _firestore.collection('posts').add({
        'author': currentUser,
        'text': _postController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'downvotes': 0,
        'voters': <String>[],
        'imageUrls': imageUrls,
        'videoUrl': videoUrl,
      });

      _postController.clear();
      _clearMedia();

      // Close the bottom sheet after posting successfully
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding post: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _addComment(String postId) async {
    final controller = _commentControllers[postId];
    if (controller == null || controller.text.trim().isEmpty) return;

    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'author': currentUser,
        'text': controller.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    }
  }

  Future<void> _votePost(String postId, bool isUpvote) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final voters = List<String>.from(data['voters'] ?? []);

        // Determine user's current vote
        final String currentVoteType = voters.firstWhere(
              (voter) => voter.startsWith(currentUser),
          orElse: () => '',
        ).split('_').last; // 'up', 'down', or ''

        // The vote tag to add
        final String newVoteTag = isUpvote ? '${currentUser}_up' : '${currentUser}_down';

        int upvotes = data['upvotes'] ?? 0;
        int downvotes = data['downvotes'] ?? 0;

        if (currentVoteType == (isUpvote ? 'up' : 'down')) {
          // User is trying to vote the same way: remove the vote (un-vote)
          voters.remove(newVoteTag);
          if (isUpvote) {
            upvotes = (upvotes > 0) ? upvotes - 1 : 0;
          } else {
            downvotes = (downvotes > 0) ? downvotes - 1 : 0;
          }
        } else {
          // User is voting, potentially changing vote
          // 1. Remove opposite vote if it exists
          if (currentVoteType == (isUpvote ? 'down' : 'up')) {
            voters.remove('${currentUser}_${isUpvote ? 'down' : 'up'}');
            if (isUpvote) {
              downvotes = (downvotes > 0) ? downvotes - 1 : 0;
            } else {
              upvotes = (upvotes > 0) ? upvotes - 1 : 0;
            }
          }

          // 2. Add the new vote
          voters.add(newVoteTag);
          if (isUpvote) {
            upvotes++;
          } else {
            downvotes++;
          }
        }

        transaction.update(postRef, {
          'upvotes': upvotes,
          'downvotes': downvotes,
          'voters': voters,
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error voting: $e')),
        );
      }
    }
  }


  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Now';
    final date = timestamp.toDate();
    final now = DateTime.now();

    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }
  }

  // --- NEW: Post Creation Logic (for the Bottom Sheet) ---
  void _showPostBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        // Wrap with StateBuilder to update state within the bottom sheet
        // without affecting the main FarmerCommunityPage build method for non-post-related updates.
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateInSheet) {
            // A local copy of setState to use within the bottom sheet scope
            void localSetState(VoidCallback fn) {
              // Call both the main and the sheet setState
              setState(fn);
              setStateInSheet(fn);
            }

            // Functions to update local state and call main state functions
            Future<void> localPickImages() async {
              await _pickImages();
              localSetState(() {});
            }

            Future<void> localPickVideo({bool fromCamera = false}) async {
              await _pickVideo(fromCamera: fromCamera);
              localSetState(() {});
            }

            Future<void> localCaptureImage() async {
              await _captureImage();
              localSetState(() {});
            }

            void localClearMedia() {
              _clearMedia();
              localSetState(() {});
            }

            Future<void> localAddPost() async {
              await _addPost();
            }

            Widget buildMediaPreviewInSheet() {
              if (_selectedImages.isEmpty && _selectedVideo == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(top: 8),
                height: 120,
                child: Row(
                  children: [
                    // Images preview
                    if (_selectedImages.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_selectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Video preview
                    if (_selectedVideo != null)
                      Expanded(
                        child: Container(
                          // ------------------- FIX 1 -------------------
                          // Removed 'color: Colors.black,' from Container and put it in BoxDecoration.
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black, // Color moved here
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),

                    // Clear button
                    IconButton(
                      onPressed: localClearMedia,
                      icon: const Icon(Icons.close),
                      color: Colors.red,
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create New Post',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.green),
                  ),
                  const Divider(),
                  TextField(
                    controller: _postController,
                    decoration: InputDecoration(
                      hintText: 'Share your farming experience...',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      // Add maxLines: null to allow multiline input
                      alignLabelWithHint: true,
                      suffixIcon: _isUploading
                          ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : IconButton(
                        onPressed: localAddPost,
                        icon: const Icon(Icons.send),
                        color: Colors.green,
                      ),
                    ),
                    maxLines: null,
                  ),

                  // Media preview
                  buildMediaPreviewInSheet(),

                  // Media buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        onPressed: localCaptureImage,
                        icon: const Icon(Icons.camera_alt),
                        color: Colors.green,
                      ),
                      IconButton(
                        onPressed: localPickImages,
                        icon: const Icon(Icons.photo_library),
                        color: Colors.green,
                      ),
                      IconButton(
                        onPressed: () => localPickVideo(fromCamera: true),
                        icon: const Icon(Icons.videocam),
                        color: Colors.green,
                      ),
                      IconButton(
                        onPressed: () => localPickVideo(fromCamera: false),
                        icon: const Icon(Icons.video_library),
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  // --- END: Post Creation Logic ---

  Widget _buildPostMedia(Map<String, dynamic> data) {
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final videoUrl = data['videoUrl'] as String?;

    if (imageUrls.isEmpty && videoUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Images
          if (imageUrls.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

          // Video
          if (videoUrl != null)
            VideoPlayerWidget(videoUrl: videoUrl),
        ],
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>;
    final postId = post.id;
    final isExpanded = _expandedPosts[postId] ?? false;
    final String userVote = List<String>.from(data['voters'] ?? []).firstWhere(
          (voter) => voter.startsWith(currentUser),
      orElse: () => '',
    ).split('_').last;


    // Ensure comment controller exists
    _commentControllers[postId] ??= TextEditingController();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green,
                  child: Text(
                    data['author']?.substring(0, 1).toUpperCase() ?? 'F',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['author'] ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatTimestamp(data['timestamp']),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Post content
            if (data['text']?.toString().isNotEmpty == true)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedPosts[postId] = !isExpanded;
                  });
                },
                child: Text(
                  data['text'] ?? '',
                  maxLines: isExpanded ? null : 3,
                  overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16),
                ),
              ),

            // Media content
            _buildPostMedia(data),

            const SizedBox(height: 12),

            // Vote buttons
            Row(
              children: [
                IconButton(
                  onPressed: () => _votePost(postId, true),
                  icon: Icon(Icons.arrow_upward,
                      color: userVote == 'up' ? Colors.green : Colors.grey),
                  iconSize: 20,
                ),
                Text('${data['upvotes'] ?? 0}'),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _votePost(postId, false),
                  icon: Icon(Icons.arrow_downward,
                      color: userVote == 'down' ? Colors.red : Colors.grey),
                  iconSize: 20,
                ),
                Text('${data['downvotes'] ?? 0}'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _expandedPosts[postId] = !isExpanded;
                    });
                  },
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  label: const Text('Comments'),
                ),
              ],
            ),

            // Comments section (expanded)
            if (isExpanded) ...[
              const Divider(),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('posts')
                    .doc(postId)
                    .collection('comments')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final comments = snapshot.data?.docs ?? [];

                  return Column(
                    children: [
                      // Comments list
                      ...comments.map((comment) {
                        final commentData = comment.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.blue,
                                child: Text(
                                  commentData['author']?.substring(0, 1).toUpperCase() ?? 'F',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          commentData['author'] ?? 'Anonymous',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatTimestamp(commentData['timestamp']),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      commentData['text'] ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Add comment field
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentControllers[postId],
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _addComment(postId),
                            icon: const Icon(Icons.send),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Community'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      // Use a Stack to layer the content feed and the persistent post bar
      body: Stack(
        children: [
          // Posts feed (Occupies the entire screen space below AppBar)
          Positioned.fill(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final posts = snapshot.data?.docs ?? [];

                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No posts yet. Be the first to share!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                // Add padding at the bottom for the post creation bar
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // Reserve space for the bottom bar
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return _buildPostCard(posts[index]);
                  },
                );
              },
            ),
          ),

          // Persistent Post Creation Bar at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              // REMOVE 'color: Colors.white,' from here
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white, // Keep color here, inside decoration
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SafeArea( // Protects from device system bars (e.g., iPhone home indicator)
                top: false,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green,
                      child: Text(
                        currentUser.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showPostBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Share your farming experience...',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _showPostBottomSheet,
                      icon: const Icon(Icons.add_box_rounded),
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Video player widget
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        // Optional: Loop video
        _controller.setLooping(true);
      }).catchError((error) {
        // Handle initialization error
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading video: $error')),
          );
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      // ------------------- FIX 2 -------------------
      // Removed 'color: Colors.black,' from Container and put it in BoxDecoration.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black, // Color moved here
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              Center(
                child: AnimatedOpacity(
                  opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                      });
                    },
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            : const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}