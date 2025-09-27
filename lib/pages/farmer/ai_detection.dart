import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:math';

class AIDetectionPage extends StatefulWidget {
  const AIDetectionPage({super.key});

  @override
  State<AIDetectionPage> createState() => _AIDetectionPageState();
}

class _AIDetectionPageState extends State<AIDetectionPage> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _selectedImage;
  bool _isAnalyzing = false;
  DetectionResult? _result;
  String _selectedAnimalType = 'poultry';

  final String currentUser = 'farmer_${DateTime.now().millisecondsSinceEpoch % 1000}';

  // Mock disease database for demo
  final Map<String, List<DiseaseInfo>> _diseaseDatabase = {
    'poultry': [
      DiseaseInfo(
        name: 'Newcastle Disease',
        confidence: 0.89,
        severity: 'High',
        symptoms: ['Respiratory distress', 'Drooping wings', 'Twisted neck', 'Green diarrhea'],
        treatment: 'Immediate isolation, vaccination of healthy birds, supportive care with antibiotics',
        prevention: 'Regular vaccination, biosecurity measures, quarantine new birds',
        urgency: 'URGENT - Contact veterinarian immediately',
      ),
      DiseaseInfo(
        name: 'Avian Influenza',
        confidence: 0.76,
        severity: 'Critical',
        symptoms: ['Sudden death', 'Respiratory symptoms', 'Drop in egg production', 'Swollen head'],
        treatment: 'Immediate quarantine, depopulation may be required, contact authorities',
        prevention: 'Strict biosecurity, limit wild bird contact, regular monitoring',
        urgency: 'CRITICAL - Report to authorities immediately',
      ),
      DiseaseInfo(
        name: 'Fowl Pox',
        confidence: 0.82,
        severity: 'Medium',
        symptoms: ['Skin lesions', 'Scabs on comb and wattles', 'Reduced appetite'],
        treatment: 'Supportive care, wound cleaning, prevent secondary infections',
        prevention: 'Vaccination, mosquito control, good ventilation',
        urgency: 'Monitor closely - Consult veterinarian',
      ),
      DiseaseInfo(
        name: 'Healthy Bird',
        confidence: 0.91,
        severity: 'None',
        symptoms: ['Alert and active', 'Bright eyes', 'Good appetite', 'Normal behavior'],
        treatment: 'Continue regular care and monitoring',
        prevention: 'Maintain good nutrition, clean water, proper housing',
        urgency: 'No action needed - Continue monitoring',
      ),
    ],
    'pig': [
      DiseaseInfo(
        name: 'African Swine Fever',
        confidence: 0.85,
        severity: 'Critical',
        symptoms: ['High fever', 'Skin discoloration', 'Loss of appetite', 'Difficulty breathing'],
        treatment: 'No treatment available - immediate quarantine and reporting required',
        prevention: 'Strict biosecurity, prevent contact with wild boars, proper disposal',
        urgency: 'CRITICAL - Contact authorities immediately',
      ),
      DiseaseInfo(
        name: 'Foot and Mouth Disease',
        confidence: 0.78,
        severity: 'High',
        symptoms: ['Blisters on feet', 'Mouth lesions', 'Lameness', 'Fever'],
        treatment: 'Supportive care, isolation, wound management',
        prevention: 'Vaccination, quarantine new animals, disinfection',
        urgency: 'URGENT - Veterinary consultation required',
      ),
      DiseaseInfo(
        name: 'Porcine Respiratory Disease',
        confidence: 0.73,
        severity: 'Medium',
        symptoms: ['Coughing', 'Labored breathing', 'Reduced growth', 'Nasal discharge'],
        treatment: 'Antibiotics as prescribed, improved ventilation, supportive care',
        prevention: 'Good ventilation, vaccination, stress reduction',
        urgency: 'Moderate - Schedule veterinary visit',
      ),
      DiseaseInfo(
        name: 'Healthy Pig',
        confidence: 0.88,
        severity: 'None',
        symptoms: ['Active behavior', 'Good appetite', 'Normal temperature', 'Clear eyes'],
        treatment: 'Continue regular care and monitoring',
        prevention: 'Balanced nutrition, clean environment, regular health checks',
        urgency: 'No action needed - Continue monitoring',
      ),
    ],
  };

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _result = null;
      });
    }
  }

  Future<void> _selectFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _result = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      // Upload image to Firebase Storage
      final ref = _storage.ref().child('ai_detection/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_selectedImage!);
      final imageUrl = await ref.getDownloadURL();

      // Simulate AI analysis delay
      await Future.delayed(const Duration(seconds: 3));

      // Mock AI detection - randomly select a disease based on animal type
      final diseases = _diseaseDatabase[_selectedAnimalType]!;
      final random = Random();
      final selectedDisease = diseases[random.nextInt(diseases.length)];

      // Create detection result
      final result = DetectionResult(
        disease: selectedDisease,
        imageUrl: imageUrl,
        animalType: _selectedAnimalType,
        timestamp: DateTime.now(),
      );

      // Save to Firestore for history
      await _firestore.collection('ai_detections').add({
        'userId': currentUser,
        'disease': selectedDisease.name,
        'confidence': selectedDisease.confidence,
        'severity': selectedDisease.severity,
        'animalType': _selectedAnimalType,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _result = result;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing image: $e')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade800;
      case 'high':
        return Colors.red.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.green.shade600;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.warning;
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.info_outline;
      default:
        return Icons.check_circle;
    }
  }

  Widget _buildResultCard() {
    if (_result == null) return const SizedBox.shrink();

    final disease = _result!.disease;
    final severityColor = _getSeverityColor(disease.severity);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getSeverityIcon(disease.severity),
                  color: severityColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disease.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                      ),
                      Text(
                        'Confidence: ${(disease.confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    disease.severity.toUpperCase(),
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Urgency Alert
            if (disease.severity != 'None')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: severityColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: severityColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        disease.urgency,
                        style: TextStyle(
                          color: severityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Symptoms
            _buildInfoSection('Symptoms', disease.symptoms, Icons.medical_services),

            const SizedBox(height: 12),

            // Treatment
            _buildInfoSection('Treatment', [disease.treatment], Icons.healing),

            const SizedBox(height: 12),

            // Prevention
            _buildInfoSection('Prevention', [disease.prevention], Icons.shield),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showVetContacts(),
                    icon: const Icon(Icons.phone),
                    label: const Text('Contact Vet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareResult(),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Result'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 26, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• '),
              Expanded(child: Text(item)),
            ],
          ),
        )),
      ],
    );
  }

  void _showVetContacts() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Veterinary Contacts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.red),
              title: const Text('Emergency Vet Clinic'),
              subtitle: const Text('24/7 Emergency Service'),
              trailing: const Icon(Icons.phone),
              onTap: () {
                // In real app, make phone call
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling emergency vet...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets, color: Colors.blue),
              title: const Text('Farm Animal Specialist'),
              subtitle: const Text('Livestock & Poultry Expert'),
              trailing: const Icon(Icons.phone),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling specialist...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.green),
              title: const Text('Agricultural Extension'),
              subtitle: const Text('Government Support Service'),
              trailing: const Icon(Icons.phone),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling extension service...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareResult() {
    // In real app, implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result shared with your veterinarian')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Disease Detection'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showDetectionHistory(),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animal type selection
            const Text(
              'Select Animal Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.egg, size: 16),
                        SizedBox(width: 4),
                        Text('Poultry'),
                      ],
                    ),
                    selected: _selectedAnimalType == 'poultry',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedAnimalType = 'poultry';
                          _result = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pets, size: 16),
                        SizedBox(width: 4),
                        Text('Pig'),
                      ],
                    ),
                    selected: _selectedAnimalType == 'pig',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedAnimalType = 'pig';
                          _result = null;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Image capture section
            const Text(
              'Capture or Select Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a clear photo of the animal showing any visible symptoms or concerns.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _captureImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Selected image preview
            if (_selectedImage != null)
              Card(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.file(
                        _selectedImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isAnalyzing ? null : _analyzeImage,
                          icon: _isAnalyzing
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.search),
                          label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Analysis progress
            if (_isAnalyzing)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing image with AI...',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This may take a few moments',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

            // Results
            _buildResultCard(),

            // Tips section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Photography Tips',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('• Ensure good lighting for clear images'),
                    const Text('• Focus on areas showing symptoms'),
                    const Text('• Take multiple angles if needed'),
                    const Text('• Keep the animal calm during photography'),
                    const Text('• Clean the camera lens for better quality'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetectionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetectionHistoryPage(userId: currentUser),
      ),
    );
  }
}

// Data classes
class DiseaseInfo {
  final String name;
  final double confidence;
  final String severity;
  final List<String> symptoms;
  final String treatment;
  final String prevention;
  final String urgency;

  DiseaseInfo({
    required this.name,
    required this.confidence,
    required this.severity,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
    required this.urgency,
  });
}

class DetectionResult {
  final DiseaseInfo disease;
  final String imageUrl;
  final String animalType;
  final DateTime timestamp;

  DetectionResult({
    required this.disease,
    required this.imageUrl,
    required this.animalType,
    required this.timestamp,
  });
}

// History page
class DetectionHistoryPage extends StatelessWidget {
  final String userId;

  const DetectionHistoryPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection History'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ai_detections')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final detections = snapshot.data?.docs ?? [];

          if (detections.isEmpty) {
            return const Center(
              child: Text(
                'No detection history yet.\nStart analyzing images to see results here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: detections.length,
            itemBuilder: (context, index) {
              final data = detections[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: data['severity'] == 'Critical'
                        ? Colors.red
                        : data['severity'] == 'High'
                        ? Colors.orange
                        : Colors.green,
                    child: Icon(
                      data['animalType'] == 'poultry' ? Icons.egg : Icons.pets,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(data['disease'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${data['animalType']?.toUpperCase()} • ${data['severity']}'),
                      Text('Confidence: ${((data['confidence'] ?? 0) * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                  trailing: Text(
                    data['timestamp'] != null
                        ? _formatDate((data['timestamp'] as Timestamp).toDate())
                        : 'Recent',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}