import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart";
import "package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart";
import "package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart";
import "package:tencent_cloud_chat_sdk/enum/log_level_enum.dart";
import "package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart";
import "package:tencent_cloud_chat_sdk/models/v2_tim_message.dart";
import "package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart";

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
  bool _sdkInited = false;
  String _status = "Ready";

  @override
  void initState() {
    super.initState();
    _initSDK();
  }

  Future<void> _initSDK() async {
    final res = await TencentImSDKPlugin.v2TIMManager.initSDK(
      sdkAppID: sdkAppId,
      loglevel: LogLevelEnum.V2TIM_LOG_DEBUG,
      listener: V2TimSDKListener(
        onConnectSuccess: () {
          if (mounted) setState(() => _status = "Connected to Tencent Cloud");
        },
        onConnectFailed: (code, desc) {
          if (mounted) setState(() => _status = "Connect error: $code - $desc");
        },
        onKickedOffline: () {
          if (mounted) setState(() => _status = "Kicked offline");
        },
      ),
    );

    if (res.code == 0) {
      if (mounted) {
        setState(() {
          _sdkInited = true;
          _status = "SDK Initialized";
        });
      }
    } else {
      if (mounted) {
        setState(() => _status = "Init failed: ${res.desc}");
      }
    }
  }

  Future<void> _login() async {
    final userId = _idController.text.trim();
    if (userId.isEmpty) return;

    setState(() {
      _loading = true;
      _status = "Fetching user token...";
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
        setState(() => _status = "Logging in to Tencent...");

        final loginRes = await TencentImSDKPlugin.v2TIMManager.login(
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
      appBar: AppBar(
        title: const Text("KatsKlub Chat"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.forum_rounded, size: 64, color: Colors.indigo),
                  const SizedBox(height: 16),
                  const Text(
                    "Welcome to KaChat",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Enter your user ID to start chatting",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: "User ID (e.g. user1, user2)",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_loading || !_sdkInited) ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Log In & Open Chat", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_status, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConversationListScreen extends StatefulWidget {
  final String currentUserId;
  const ConversationListScreen({super.key, required this.currentUserId});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  List<V2TimConversation> _conversations = [];
  bool _loading = true;
  late final V2TimConversationListener _conversationListener;

  @override
  void initState() {
    super.initState();
    _initListener();
    _loadConversations();
  }

  @override
  void dispose() {
    TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .removeConversationListener(listener: _conversationListener);
    super.dispose();
  }

  void _initListener() {
    _conversationListener = V2TimConversationListener(
      onConversationChanged: (list) {
        _loadConversations();
      },
      onNewConversation: (list) {
        _loadConversations();
      },
    );
    TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .addConversationListener(listener: _conversationListener);
  }

  Future<void> _loadConversations() async {
    final res = await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .getConversationList(count: 50, nextSeq: "0");

    if (res.code == 0 && res.data != null) {
      if (mounted) {
        setState(() {
          _conversations = res.data!.conversationList ?? [];
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startDirectChat(BuildContext context) {
    final targetController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Chat"),
        content: TextField(
          controller: targetController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Target User ID",
            hintText: "Enter user ID to message",
          ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(
                      currentUserId: widget.currentUserId,
                      targetUserId: target,
                      title: target,
                    ),
                  ),
                ).then((_) => _loadConversations());
              }
            },
            child: const Text("Start Chat"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats (${widget.currentUserId})"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await TencentImSDKPlugin.v2TIMManager.logout();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startDirectChat(context),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.message),
        label: const Text("New Chat"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text("No conversations yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _startDirectChat(context),
                        child: const Text("Start a chat"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conv = _conversations[index];
                      final name = conv.showName ?? conv.userID ?? "User";
                      final lastMsg = conv.lastMessage?.textElem?.text ?? "No messages";
                      final unread = conv.unreadCount ?? 0;
                      final targetUser = conv.userID ?? "";

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: unread > 0 ? Colors.black87 : Colors.grey),
                        ),
                        trailing: unread > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "$unread",
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomScreen(
                                currentUserId: widget.currentUserId,
                                targetUserId: targetUser,
                                title: name,
                              ),
                            ),
                          ).then((_) => _loadConversations());
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final String title;

  const ChatRoomScreen({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
    required this.title,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final List<V2TimMessage> _messages = [];
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  late final V2TimAdvancedMsgListener _msgListener;

  @override
  void initState() {
    super.initState();
    _initListener();
    _loadMessages();
    _markRead();
  }

  @override
  void dispose() {
    TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .removeAdvancedMsgListener(listener: _msgListener);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initListener() {
    _msgListener = V2TimAdvancedMsgListener(
      onRecvNewMessage: (V2TimMessage msg) {
        if (msg.sender == widget.targetUserId || msg.userID == widget.targetUserId) {
          if (mounted) {
            setState(() {
              _messages.insert(0, msg);
            });
            _markRead();
          }
        }
      },
    );
    TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .addAdvancedMsgListener(listener: _msgListener);
  }

  Future<void> _markRead() async {
    await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .cleanConversationUnreadMessageCount(
          conversationID: "c2c_${widget.targetUserId}",
          cleanTimestamp: 0,
          cleanSequence: 0,
        );
  }

  Future<void> _loadMessages() async {
    final res = await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .getC2CHistoryMessageList(
          userID: widget.targetUserId,
          count: 50,
        );

    if (res.code == 0 && res.data != null) {
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(res.data!);
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    final createRes = await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .createTextMessage(text: text);

    if (createRes.code == 0 && createRes.data?.messageInfo != null) {
      final msg = createRes.data!.messageInfo!;
      setState(() {
        _messages.insert(0, msg);
      });

      final sendRes = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .sendMessage(
            message: msg,
            receiver: widget.targetUserId,
            groupID: "",
          );

      if (sendRes.code != 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send: ${sendRes.desc}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text("Say hi to start the conversation!", style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.isSelf ?? (msg.sender == widget.currentUserId);
                          final text = msg.textElem?.text ?? "";
                          final timestamp = msg.timestamp != null
                              ? DateTime.fromMillisecondsSinceEpoch(msg.timestamp! * 1000)
                              : DateTime.now();
                          final timeStr = DateFormat("hh:mm a").format(timestamp);

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.indigo : Colors.grey.shade200,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    text,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
