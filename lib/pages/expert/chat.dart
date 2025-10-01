import 'package:flutter/material.dart';

void main() {
  runApp(const VetFarmerChatPage());
}

class VetFarmerChatPage extends StatelessWidget {
  const VetFarmerChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vet-Farmer Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
        fontFamily: 'Roboto',
      ),
      home: const ChatListScreen(),
    );
  }
}

// Chat List Screen
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _chats = [
    {
      'id': 'F001',
      'name': 'Rajesh Kumar',
      'farmId': 'FARM-2145',
      'avatar': 'R',
      'lastMessage': 'My cow is showing signs of fever and not eating properly',
      'timestamp': '10:30 AM',
      'unread': 3,
      'online': true,
    },
    {
      'id': 'F002',
      'name': 'Priya Sharma',
      'farmId': 'FARM-3421',
      'avatar': 'P',
      'lastMessage': 'Thank you doctor, the medication is working well',
      'timestamp': 'Yesterday',
      'unread': 0,
      'online': false,
    },
    {
      'id': 'F003',
      'name': 'Amit Patel',
      'farmId': 'FARM-1892',
      'avatar': 'A',
      'lastMessage': 'When should I schedule the next vaccination?',
      'timestamp': 'Yesterday',
      'unread': 1,
      'online': true,
    },
    {
      'id': 'F004',
      'name': 'Lakshmi Devi',
      'farmId': 'FARM-5632',
      'avatar': 'L',
      'lastMessage': 'Voice message',
      'timestamp': '2 days ago',
      'unread': 0,
      'online': false,
    },
    {
      'id': 'F005',
      'name': 'Suresh Reddy',
      'farmId': 'FARM-4521',
      'avatar': 'S',
      'lastMessage': 'Photo',
      'timestamp': '3 days ago',
      'unread': 2,
      'online': false,
    },
  ];

  List<Map<String, dynamic>> get filteredChats {
    if (_searchQuery.isEmpty) return _chats;
    return _chats.where((chat) {
      final name = chat['name'].toString().toLowerCase();
      final farmId = chat['farmId'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || farmId.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2D5F3F),
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: const Color(0xFF2D5F3F),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search farmers by name or farm ID...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),

          // Chat List
          Expanded(
            child: filteredChats.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No farmers found',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                return _buildChatListItem(filteredChats[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListItem(Map<String, dynamic> chat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(farmer: chat),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF6B8E23),
                      child: Text(
                        chat['avatar'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    if (chat['online'])
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            chat['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            chat['timestamp'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chat['farmId'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat['lastMessage'],
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat['unread'] > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D5F3F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chat['unread'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Chat Detail Screen
class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> farmer;

  const ChatDetailScreen({Key? key, required this.farmer}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [
    {
      'text': 'Hello Doctor, I need your help',
      'time': '10:15 AM',
      'isSender': false,
      'status': 'read',
      'type': 'text',
    },
    {
      'text': 'Hi Rajesh! How can I help you today?',
      'time': '10:16 AM',
      'isSender': true,
      'status': 'read',
      'type': 'text',
    },
    {
      'text': 'My cow is showing signs of fever and not eating properly',
      'time': '10:18 AM',
      'isSender': false,
      'status': 'read',
      'type': 'text',
    },
    {
      'imageUrl': 'image',
      'time': '10:19 AM',
      'isSender': false,
      'status': 'read',
      'type': 'image',
    },
    {
      'text': 'I can see the symptoms. How long has this been happening?',
      'time': '10:22 AM',
      'isSender': true,
      'status': 'read',
      'type': 'text',
    },
    {
      'audioUrl': 'voice_note',
      'duration': '0:45',
      'time': '10:25 AM',
      'isSender': false,
      'status': 'read',
      'type': 'voice',
    },
    {
      'text': 'Based on your description, this might be a case of mastitis. I recommend immediate treatment.',
      'time': '10:28 AM',
      'isSender': true,
      'status': 'delivered',
      'type': 'text',
    },
    {
      'text': 'Should I bring the cow to the clinic?',
      'time': '10:30 AM',
      'isSender': false,
      'status': 'sent',
      'type': 'text',
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        'text': _messageController.text,
        'time': TimeOfDay.now().format(context),
        'isSender': true,
        'status': 'sent',
        'type': 'text',
      });
      _messageController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2D5F3F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF6B8E23),
                  child: Text(
                    widget.farmer['avatar'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.farmer['online'])
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2D5F3F), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.farmer['name'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    widget.farmer['farmId'],
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'report') {
                _showReportDiseaseDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.add_alert, color: Color(0xFF2D5F3F)),
                    SizedBox(width: 8),
                    Text('Report Disease Case'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block Farmer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Input Area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
                  onPressed: () => _showAttachmentOptions(),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D5F3F),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isSender = message['isSender'] as bool;
    final type = message['type'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6B8E23),
              child: Text(
                widget.farmer['avatar'],
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSender ? const Color(0xFF2D5F3F) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSender ? 16 : 4),
                  bottomRight: Radius.circular(isSender ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (type == 'text')
                    Text(
                      message['text'],
                      style: TextStyle(
                        color: isSender ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    )
                  else if (type == 'image')
                    _buildImageMessage()
                  else if (type == 'voice')
                      _buildVoiceMessage(message['duration']),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message['time'],
                        style: TextStyle(
                          color: isSender ? Colors.white70 : Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      if (isSender) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(message['status']),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSender) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildImageMessage() {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.image, size: 48, color: Colors.grey.shade600),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.download, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceMessage(String duration) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        Container(
          width: 120,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          duration,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'sent':
        icon = Icons.check;
        color = Colors.white70;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.white70;
        break;
      case 'read':
        icon = Icons.done_all;
        color = Colors.blue.shade300;
        break;
      default:
        icon = Icons.access_time;
        color = Colors.white70;
    }

    return Icon(icon, size: 16, color: color);
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.photo_camera, 'Camera', const Color(0xFF6B8E23)),
                _buildAttachmentOption(Icons.photo_library, 'Gallery', const Color(0xFF8B6F47)),
                _buildAttachmentOption(Icons.mic, 'Voice Note', const Color(0xFF2D5F3F)),
                _buildAttachmentOption(Icons.insert_drive_file, 'Document', Colors.blue.shade700),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showReportDiseaseDialog() {
    final TextEditingController diseaseController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_alert, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Report Disease Case'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farmer: ${widget.farmer['name']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Farm ID: ${widget.farmer['farmId']}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: diseaseController,
              decoration: InputDecoration(
                labelText: 'Disease Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.local_hospital),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.notes),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Disease case reported successfully'),
                  backgroundColor: Color(0xFF2D5F3F),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5F3F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}