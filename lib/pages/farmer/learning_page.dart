import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'dart:convert'; // No longer needed

class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> with TickerProviderStateMixin {
  late TabController _tabController;
  // Initialize Firestore, though it's mock here, the structure is correct.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Dynamic user ID for progress tracking/testing
  final String currentUser = 'farmer_${DateTime.now().millisecondsSinceEpoch % 1000}';

  String _searchQuery = '';
  String _selectedCategory = 'all';
  List<LearningModule> _allModules = [];
  List<LearningModule> _filteredModules = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeLearningContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeLearningContent() {
    // --- Learning Modules Data (Kept the same structure) ---
    _allModules = [
      // Poultry Farming Modules
      LearningModule(
        id: '1',
        title: 'Poultry Housing and Setup',
        description: 'Learn how to design and build proper housing for chickens and other poultry.',
        category: 'poultry',
        difficulty: 'Beginner',
        duration: '25 min',
        type: 'video',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        videoUrl: 'https://youtu.be/wuOd5_M9yDQ?si=ZWGctOt66ctNGYzk',
        topics: ['Housing design', 'Ventilation', 'Space requirements', 'Equipment setup'],
        learningObjectives: [
          'Understand optimal housing dimensions',
          'Learn proper ventilation techniques',
          'Master equipment placement',
          'Ensure biosecurity measures'
        ],
      ),
      LearningModule(
        id: '2',
        title: 'Chicken Nutrition and Feeding',
        description: 'Complete guide to feeding chickens at different life stages.',
        category: 'poultry',
        difficulty: 'Intermediate',
        duration: '30 min',
        type: 'video',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        topics: ['Feed types', 'Nutritional requirements', 'Feeding schedules', 'Water management'],
        learningObjectives: [
          'Calculate proper feed ratios',
          'Understand nutritional needs by age',
          'Implement feeding schedules',
          'Manage water quality'
        ],
      ),
      LearningModule(
        id: '3',
        title: 'Poultry Health and Disease Prevention',
        description: 'Comprehensive guide to keeping your flock healthy and preventing common diseases.',
        category: 'poultry',
        difficulty: 'Advanced',
        duration: '45 min',
        type: 'video',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        topics: ['Vaccination programs', 'Disease symptoms', 'Biosecurity', 'Treatment protocols'],
        learningObjectives: [
          'Implement vaccination schedules',
          'Recognize disease symptoms early',
          'Apply biosecurity measures',
          'Administer basic treatments'
        ],
      ),
      LearningModule(
        id: '4',
        title: 'Egg Production Optimization',
        description: 'Maximize egg production with proper management techniques.',
        category: 'poultry',
        difficulty: 'Intermediate',
        duration: '35 min',
        type: 'video',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        topics: ['Laying cycles', 'Nest box management', 'Lighting programs', 'Nutrition for layers'],
        learningObjectives: [
          'Optimize laying conditions',
          'Manage lighting programs',
          'Improve egg quality',
          'Reduce mortality rates'
        ],
      ),

      // Pig Farming Modules
      LearningModule(
        id: '5',
        title: 'Pig Housing and Facility Design',
        description: 'Design efficient and comfortable housing systems for pigs.',
        category: 'pig',
        difficulty: 'Beginner',
        duration: '40 min',
        type: 'video',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        topics: ['Pen design', 'Flooring systems', 'Ventilation', 'Waste management'],
        learningObjectives: [
          'Design appropriate pen sizes',
          'Choose proper flooring materials',
          'Install ventilation systems',
          'Plan waste management systems'
        ],
      ),
      LearningModule(
        id: '6',
        title: 'Pig Nutrition and Feed Management',
        description: 'Learn about pig nutrition requirements and feeding strategies.',
        category: 'pig',
        difficulty: 'Intermediate',
        duration: '50 min',
        type: 'video',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        topics: ['Growth phases', 'Feed formulation', 'Feeding systems', 'Water requirements'],
        learningObjectives: [
          'Formulate age-appropriate feeds',
          'Calculate daily feed requirements',
          'Optimize feed conversion ratios',
          'Manage feeding schedules'
        ],
      ),
      LearningModule(
        id: '7',
        title: 'Pig Breeding and Reproduction',
        description: 'Master pig breeding techniques and reproductive management.',
        category: 'pig',
        difficulty: 'Advanced',
        duration: '60 min',
        type: 'video',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        topics: ['Breeding selection', 'Estrus detection', 'Pregnancy management', 'Farrowing care'],
        learningObjectives: [
          'Select quality breeding stock',
          'Detect estrus cycles accurately',
          'Manage pregnant sows',
          'Assist in farrowing process'
        ],
      ),
      LearningModule(
        id: '8',
        title: 'Pig Health and Biosecurity',
        description: 'Comprehensive pig health management and disease prevention.',
        category: 'pig',
        difficulty: 'Advanced',
        duration: '55 min',
        type: 'video',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        topics: ['Common diseases', 'Vaccination protocols', 'Biosecurity measures', 'Health monitoring'],
        learningObjectives: [
          'Identify disease symptoms',
          'Implement biosecurity protocols',
          'Create vaccination schedules',
          'Monitor herd health effectively'
        ],
      ),

      // General Farming Modules
      LearningModule(
        id: '9',
        title: 'Farm Business Management',
        description: 'Learn to manage your farm as a profitable business.',
        category: 'general',
        difficulty: 'Intermediate',
        duration: '45 min',
        type: 'video',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        topics: ['Financial planning', 'Record keeping', 'Marketing', 'Risk management'],
        learningObjectives: [
          'Create business plans',
          'Maintain financial records',
          'Develop marketing strategies',
          'Assess and manage risks'
        ],
      ),
      LearningModule(
        id: '10',
        title: 'Sustainable Farming Practices',
        description: 'Implement environmentally friendly and sustainable farming methods.',
        category: 'general',
        difficulty: 'Intermediate',
        duration: '40 min',
        type: 'video',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        topics: ['Environmental impact', 'Renewable energy', 'Waste reduction', 'Organic practices'],
        learningObjectives: [
          'Reduce environmental footprint',
          'Implement renewable energy solutions',
          'Minimize waste production',
          'Adopt organic farming methods'
        ],
      ),
    ];

    _filterModules();
  }

  void _filterModules() {
    setState(() {
      _filteredModules = _allModules.where((module) {
        final matchesSearch = module.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            module.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            module.topics.any((topic) => topic.toLowerCase().contains(_searchQuery.toLowerCase()));

        final matchesCategory = _selectedCategory == 'all' || module.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _watchVideo(String videoUrl, String moduleId) async {
    final Uri url = Uri.parse(videoUrl.trim());

    try {
      // Directly launch the URL
      await launchUrl(url, mode: LaunchMode.platformDefault);

      // Track progress in Firestore
      await FirebaseFirestore.instance
          .collection('user_progress')
          .doc('${currentUser}_$moduleId')
          .set({
        'userId': currentUser,
        'moduleId': moduleId,
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
        'lastAccessedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open video: $e')),
      );
    }
  }

  Future<void> _markAsCompleted(String moduleId) async {
    await _firestore.collection('user_progress').doc('${currentUser}_$moduleId').set({
      'userId': currentUser,
      'moduleId': moduleId,
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'lastAccessedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Module marked as completed!')),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'poultry':
        return Icons.egg_alt; // Changed to a slightly better icon for poultry
      case 'pig':
        return Icons.pets;
      case 'general':
        return Icons.agriculture;
      default:
        return Icons.school;
    }
  }

  Widget _buildModuleCard(LearningModule module) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showModuleDetails(module),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail (IMPROVEMENT: Replaced image/gradient with a cleaner icon placeholder)
            Stack(
              children: [
                Container(
                  height: 120, // Reduced height for better card density
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    color: Colors.green.shade700, // Solid primary color background
                  ),
                  child: Center(
                    child: Icon( // Display category icon
                      _getCategoryIcon(module.category),
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      module.duration,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and category
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(module.category),
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          module.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    module.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildTag(module.difficulty, _getDifficultyColor(module.difficulty)),
                      _buildTag(module.category.toUpperCase(), Colors.blue),
                      _buildTag('${module.topics.length} Topics', Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _watchVideo(module.videoUrl, module.id),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Watch'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showModuleDetails(module),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showModuleDetails(LearningModule module) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        module.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Meta info
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildTag(module.difficulty, _getDifficultyColor(module.difficulty)),
                          _buildTag(module.duration, Colors.blue),
                          _buildTag(module.category.toUpperCase(), Colors.green),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        module.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),

                      // Learning Objectives
                      const Text(
                        'Learning Objectives',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...module.learningObjectives.map((objective) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(objective)),
                          ],
                        ),
                      )),
                      const SizedBox(height: 20),

                      // Topics Covered
                      const Text(
                        'Topics Covered',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: module.topics.map((topic) => _buildTag(topic, Colors.purple)).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _watchVideo(module.videoUrl, module.id);
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Watch Video'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _markAsCompleted(module.id);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Mark Complete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('user_progress')
          .where('userId', isEqualTo: currentUser)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final progressDocs = snapshot.data?.docs ?? [];
        final completedCount = progressDocs.where((doc) =>
        (doc.data() as Map<String, dynamic>)['status'] == 'completed').length;
        final inProgressCount = progressDocs.where((doc) =>
        (doc.data() as Map<String, dynamic>)['status'] == 'in_progress').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              '$completedCount',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Text('Completed'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.play_circle, color: Colors.blue, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              '$inProgressCount',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Text('In Progress'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.school, color: Colors.orange, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              '${_allModules.length}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Text('Total'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress List
              const Text(
                'Your Progress',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // IMPROVEMENT: Better empty state message with icon
              if (progressDocs.isEmpty)
                Center(
                  child: Card(
                    color: Colors.grey.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_border, size: 40, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'No progress yet! Start a module to see it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...progressDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Safe access with a check in case a module is deleted but progress remains
                  final moduleIndex = _allModules.indexWhere((m) => m.id == data['moduleId']);

                  if (moduleIndex == -1) {
                    return const SizedBox.shrink(); // Skip if module not found
                  }

                  final module = _allModules[moduleIndex];
                  final status = data['status'] as String;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: status == 'completed' ? Colors.green : Colors.blue,
                        child: Icon(
                          status == 'completed' ? Icons.check : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(module.title),
                      subtitle: Text('Status: ${status.toUpperCase()}'),
                      trailing: IconButton(
                        onPressed: () => _watchVideo(module.videoUrl, module.id),
                        icon: const Icon(Icons.play_arrow),
                        tooltip: 'Continue Watching',
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Learning Center'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Courses'),
            Tab(text: 'My Progress'),
            Tab(text: 'Certificates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Courses Tab
          Column(
            children: [
              // Search and filter
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        _searchQuery = value;
                        _filterModules();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search courses...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // IMPROVEMENT: FilterChip styling for better visual feedback
                          FilterChip(
                            label: Text(
                              'All',
                              style: TextStyle(color: _selectedCategory == 'all' ? Colors.white : Colors.black87),
                            ),
                            selected: _selectedCategory == 'all',
                            selectedColor: Colors.green,
                            backgroundColor: Colors.grey.shade200,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = 'all';
                              });
                              _filterModules();
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text(
                              'Poultry',
                              style: TextStyle(color: _selectedCategory == 'poultry' ? Colors.white : Colors.black87),
                            ),
                            selected: _selectedCategory == 'poultry',
                            selectedColor: Colors.green,
                            backgroundColor: Colors.grey.shade200,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = 'poultry';
                              });
                              _filterModules();
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text(
                              'Pig',
                              style: TextStyle(color: _selectedCategory == 'pig' ? Colors.white : Colors.black87),
                            ),
                            selected: _selectedCategory == 'pig',
                            selectedColor: Colors.green,
                            backgroundColor: Colors.grey.shade200,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = 'pig';
                              });
                              _filterModules();
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text(
                              'General',
                              style: TextStyle(color: _selectedCategory == 'general' ? Colors.white : Colors.black87),
                            ),
                            selected: _selectedCategory == 'general',
                            selectedColor: Colors.green,
                            backgroundColor: Colors.grey.shade200,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = 'general';
                              });
                              _filterModules();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Course list
              Expanded(
                child: _filteredModules.isEmpty
                    ? const Center(
                  child: Text(
                    'No courses found matching your search or filter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: _filteredModules.length,
                  itemBuilder: (context, index) {
                    return _buildModuleCard(_filteredModules[index]);
                  },
                ),
              ),
            ],
          ),

          // Progress Tab
          _buildProgressTab(),

          // Certificates Tab
          const Center(
            child: Text(
              'Certificates feature coming soon!\nComplete courses to earn certificates.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// Data model
class LearningModule {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final String duration;
  final String type;
  final String thumbnailUrl;
  final String videoUrl;
  final List<String> topics;
  final List<String> learningObjectives;

  LearningModule({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.type,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.topics,
    required this.learningObjectives,
  });
}