import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'learning_page.dart';
import 'chatbot.dart';
import 'ai_detection.dart';
import 'chat.dart';
import 'community.dart';
import 'dailys.dart';

// Key to access the state of the DashboardContentPage from the sidebar
final GlobalKey<_DashboardContentPageState> _dashboardContentKey = GlobalKey<_DashboardContentPageState>();

class FarmerDashboardPage extends StatefulWidget {
  const FarmerDashboardPage({super.key});

  @override
  State<FarmerDashboardPage> createState() => _FarmerDashboardPageState();
}

class _FarmerDashboardPageState extends State<FarmerDashboardPage> {
  int _selectedIndex = 2; // Dashboard selected by default

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const LearningPage(),
      const AIDetectionPage(),
      // Assign the key to the DashboardContentPage instance
      DashboardContentPage(key: _dashboardContentKey),
      const ChatBotPage(),
      const FarmerCommunityPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSidebar(context), // Pass context to the sidebar
      body: _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.greenAccent[700],
        elevation: 6,
        child: const Icon(Icons.chat, size: 28, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          );
        },
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.lightGreen[600],
        unselectedItemColor: Colors.grey[400],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Learning'),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera_enhance), label: 'AI Detection'),
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chatbot'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance), label: 'Community'),
        ],
      ),
    );
  }

  // Sidebar UI
  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.green[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5A8D60), Color(0xFF167B47)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person,
                        size: 40, color: Colors.greenAccent),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Farmer Name",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "farmer@example.com",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.task, color: Colors.green),
              title: const Text("Daily Tasks"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailysPage()),
                ).then((_) {
                  // Use the GlobalKey to correctly call _loadTasks
                  _dashboardContentKey.currentState?._loadTasks();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.teal),
              title: const Text("CCTV Monitoring"),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text("Profile Settings"),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardContentPage extends StatefulWidget {
  // Accept the key from the constructor
  const DashboardContentPage({super.key});

  @override
  State<DashboardContentPage> createState() => _DashboardContentPageState();
}

class _DashboardContentPageState extends State<DashboardContentPage> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // This method is now publicly accessible via the GlobalKey
  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      final List<dynamic> decoded = json.decode(tasksJson);
      if (!mounted) return;
      setState(() {
        _tasks = decoded.map((item) => Task.fromJson(item)).toList();
      });
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('tasks', encoded);
  }

  void _toggleComplete(String id) {
    if (!mounted) return;
    setState(() {
      final index = _tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        _tasks[index].isCompleted = !_tasks[index].isCompleted;
      }
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadTasks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSectionTitle('Pending Daily Tasks'),
              const SizedBox(height: 16),
              _buildTasksSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Alerts & Weather'),
              const SizedBox(height: 16),
              _buildAlertsSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Farm Monitoring'),
              const SizedBox(height: 16),
              _buildMonitoringSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pendingTasks = _tasks.where((task) => !task.isCompleted).toList();

    final top3Tasks = pendingTasks.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: pendingTasks.isEmpty
          ? const Center(
        child: Text(
          'No pending tasks 🎉',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : Column(
        children: [
          // --- CHANGE: Iterate over top3Tasks instead of pendingTasks ---
          ...top3Tasks.asMap().entries.map((entry) {
            int index = entry.key;
            Task task = entry.value;
            return Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: task.isCompleted,
                      onChanged: (bool? value) {
                        if (value != null) {
                          _toggleComplete(task.id);
                        }
                      },
                      activeColor: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                // --- CHANGE: Use top3Tasks.length for the divider logic ---
                if (index < top3Tasks.length - 1)
                  const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE0E0E0)),
              ],
            );
          }),
          // --- ADDED: A "View All" button that appears if there are more than 3 tasks ---
          if (pendingTasks.length > 3)
            ListTile(
              contentPadding: const EdgeInsets.only(top: 8),
              title: Center(
                child: Text(
                  'View all ${pendingTasks.length} tasks',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              trailing: Icon(Icons.arrow_forward, color: Colors.green[800]),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailysPage()),
                ).then((_) => _loadTasks());
              },
            )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF212121),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A8D60), Color(0xFF167B47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A8D60).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 30),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Text(
              'Welcome, Farmer',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.notifications_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildAlertCard(
              'Disease Alert', 'Leaf blight detected', Icons.bug_report,
              Colors.orange),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAlertCard(
              'Weather Info', 'Rain expected', Icons.cloudy_snowing,
              Colors.blue),
        ),
      ],
    );
  }

  Widget _buildAlertCard(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242))),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(fontSize: 14, color: Color(0xFF757575))),
        ],
      ),
    );
  }

  Widget _buildMonitoringSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child:
                  _buildStatItem('Soil Moisture', '72%', Icons.water_drop)),
              Expanded(
                  child:
                  _buildStatItem('Temperature', '28°C', Icons.thermostat)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatItem('Humidity', '65%', Icons.opacity)),
              Expanded(child: _buildStatItem('pH Level', '6.8', Icons.science)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.lightGreen[100],
          child: Icon(icon, color: Colors.lightGreen[600], size: 32),
        ),
        const SizedBox(height: 12),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121))),
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF757575))),
      ],
    );
  }
}