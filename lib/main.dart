import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart";

const int sdkAppId = 20046974;
const String tokenApiUrl = "https://katsklub.top/api/chat/token";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TencentLoginScreen(),
  ));
}

class TencentLoginScreen extends StatefulWidget {
  const TencentLoginScreen({super.key});

  @override
  State<TencentLoginScreen> createState() => _TencentLoginScreenState();
}

class _TencentLoginScreenState extends State<TencentLoginScreen> {
  final TextEditingController _idController = TextEditingController();
  bool _loading = false;
  String _status = "Ready";

  @override
  void initState() {
    super.initState();
    _initTUIKit();
  }

  Future<void> _initTUIKit() async {
    await TIMUIKitCore.getInstance().init(
      sdkAppID: sdkAppId,
      language: LanguageEnum.en,
      onTUIKitCallbackListener: (dynamic callback) {},
    );
  }

  Future<void> _login() async {
    final userId = _idController.text.trim();
    if (userId.isEmpty) return;

    setState(() {
      _loading = true;
      _status = "Fetching token...";
    });

    try {
      final res = await http.post(
        Uri.parse(tokenApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );

      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        final userSig = data["userSig"] as String;
        setState(() => _status = "Logging in to TUIKit...");

        final loginRes = await TIMUIKitCore.getInstance().login(
          userID: userId,
          userSig: userSig,
        );

        if (loginRes.code == 0 && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ConversationListScreen(currentUserId: userId),
            ),
          );
        } else {
          setState(() => _status = "Login failed: ${loginRes.desc}");
        }
      } else {
        setState(() => _status = "API Error: ${data["error"]}");
      }
    } catch (e) {
      setState(() => _status = "Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("KatsKlub Chat")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: "User ID (e.g. user1, user2)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Open Chat"),
              ),
            ),
            const SizedBox(height: 16),
            Text(_status, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class ConversationListScreen extends StatelessWidget {
  final String currentUserId;
  const ConversationListScreen({super.key, required this.currentUserId});

  void _startDirectChat(BuildContext context) {
    final targetController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Chat"),
        content: TextField(
          controller: targetController,
          decoration: const InputDecoration(labelText: "Target User ID"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final target = targetController.text.trim();
              if (target.isNotEmpty) {
                Navigator.pop(ctx);
                final conv = V2TimConversation(
                  conversationID: "c2c_$target",
                  type: 1,
                  userID: target,
                  showName: target,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(conversation: conv),
                  ),
                );
              }
            },
            child: const Text("Start"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats ($currentUserId)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await TIMUIKitCore.getInstance().logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TencentLoginScreen()),
                );
              }
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startDirectChat(context),
        child: const Icon(Icons.message),
      ),
      body: TIMUIKitConversation(
        onTapItem: (conv) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(conversation: conv),
            ),
          );
        },
      ),
    );
  }
}

class ChatRoomScreen extends StatelessWidget {
  final V2TimConversation conversation;
  const ChatRoomScreen({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(conversation.showName ?? conversation.userID ?? "Chat")),
      body: TIMUIKitChat(
        conversation: conversation,
      ),
    );
  }
}
