import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:tencent_calls_uikit/tencent_calls_uikit.dart";
import "package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart";
import "package:tencent_cloud_chat_sdk/enum/log_level_enum.dart";
import "package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart";
import "package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart";
import "package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart";
import "package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart";
import "package:tencent_cloud_chat_uikit/theme/tui_theme.dart";

const int sdkAppId = 20046974;
const String tokenApiUrl = "https://katsklub.top/api/chat/token";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KatsKlubApp());
}

class KatsKlubApp extends StatelessWidget {
  const KatsKlubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "KatsKlub",
      debugShowCheckedModeBanner: false,
      navigatorObservers: [TUICallKit.navigatorObserver],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          surface: const Color(0xFFF9FAFB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        useMaterial3: true,
      ),
      home: const TencentLoginScreen(),
    );
  }
}

/// Custom Theme Provider Widget wrapping TUIKit screens
class TIMUIKitTheme extends StatelessWidget {
  final TUITheme theme;
  final Widget child;

  const TIMUIKitTheme({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    TIMUIKitCore.getInstance().setTheme(theme: theme);
    return child;
  }
}

// ----------------------------------------------------
// 1. LOGIN SCREEN (Sync Profile & Initialize CallKit)
// ----------------------------------------------------
class TencentLoginScreen extends StatefulWidget {
  const TencentLoginScreen({super.key});

  @override
  State<TencentLoginScreen> createState() => _TencentLoginScreenState();
}

class _TencentLoginScreenState extends State<TencentLoginScreen> {
  final TextEditingController _idController = TextEditingController();
  bool _loading = false;
  String _status = "Connected to Tencent Cloud";

  @override
  void initState() {
    super.initState();
    _initTUIKit();
  }

  Future<void> _initTUIKit() async {
    await TIMUIKitCore.getInstance().init(
      sdkAppID: sdkAppId,
      loglevel: LogLevelEnum.V2TIM_LOG_DEBUG,
      listener: V2TimSDKListener(),
      onTUIKitCallbackListener: (dynamic callback) {},
    );
  }

  Future<void> _login() async {
    final userId = _idController.text.trim();
    if (userId.isEmpty) return;

    setState(() {
      _loading = true;
      _status = "Fetching profile & token...";
    });

    try {
      final res = await http.post(
        Uri.parse(tokenApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );

      final data = jsonDecode(res.body);
      final userSig = data["userSig"] as String?;
      final nickName = data["nickName"] as String? ?? userId;
      final avatarUrl = data["avatarUrl"] as String? ?? "";

      if (userSig != null && userSig.isNotEmpty) {
        setState(() => _status = "Logging in to Chat & CallKit...");

        final loginRes = await TIMUIKitCore.getInstance().login(
          userID: userId,
          userSig: userSig,
        );

        if (loginRes.code == 0) {
          // Sync Nickname & Avatar to Tencent IM
          await TencentImSDKPlugin.v2TIMManager.setSelfInfo(
            userFullInfo: V2TimUserFullInfo(
              nickName: nickName,
              faceUrl: avatarUrl,
            ),
          );

          // Initialize Voice & Video CallKit
          await TUICallKit.instance.login(sdkAppId, userId, userSig);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MainNavigationScreen(
                  currentUserId: userId,
                  displayName: nickName,
                  avatarUrl: avatarUrl,
                ),
              ),
            );
          }
        } else {
          setState(() => _status = "Login failed: ${loginRes.desc}");
        }
      } else {
        setState(() => _status = "Token error: No userSig returned");
      }
    } catch (e) {
      setState(() => _status = "Connection error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
                  const Icon(Icons.forum_rounded, size: 64, color: Color(0xFF6366F1)),
                  const SizedBox(height: 12),
                  const Text(
                    "Welcome to KatsKlub",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Sign in to start messaging & calls",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      labelText: "User ID",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Sign In & Open Chat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

// ----------------------------------------------------
// 2. MAIN NAVIGATION SCREEN (Tabs: Chats, Contacts, Profile)
// ----------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  final String currentUserId;
  final String displayName;
  final String avatarUrl;

  const MainNavigationScreen({
    super.key,
    required this.currentUserId,
    required this.displayName,
    required this.avatarUrl,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ConversationTab(currentUserId: widget.currentUserId, displayName: widget.displayName),
      const ContactsTab(),
      ProfileTab(
        userId: widget.currentUserId,
        displayName: widget.displayName,
        avatarUrl: widget.avatarUrl,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: "Chats"),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: "Contacts"),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 3. CONVERSATION LIST (Direct Messages & Create Groups)
// ----------------------------------------------------
class ConversationTab extends StatelessWidget {
  final String currentUserId;
  final String displayName;

  const ConversationTab({
    super.key,
    required this.currentUserId,
    required this.displayName,
  });

  void _showNewChatMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person_add, color: Color(0xFF6366F1)),
              title: const Text("Direct Chat"),
              onTap: () {
                Navigator.pop(ctx);
                _openDirectChatDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: Color(0xFF6366F1)),
              title: const Text("Create Group Chat"),
              onTap: () {
                Navigator.pop(ctx);
                _openCreateGroupDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDirectChatDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Direct Chat"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Target User ID",
            hintText: "e.g. user2",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final target = controller.text.trim();
              if (target.isNotEmpty) {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModernChatRoomScreen(
                      conversation: V2TimConversation(
                        conversationID: "c2c_$target",
                        type: 1,
                        userID: target,
                        showName: target,
                      ),
                    ),
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

  void _openCreateGroupDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create New Group"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: "Group Name",
            hintText: "e.g. KatsKlub Lounge",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final groupName = nameCtrl.text.trim();
              if (groupName.isNotEmpty) {
                Navigator.pop(ctx);
                final res = await TencentImSDKPlugin.v2TIMManager.getGroupManager().createGroup(
                  groupType: "Public",
                  groupName: groupName,
                );
                if (res.code == 0 && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ModernChatRoomScreen(
                        conversation: V2TimConversation(
                          conversationID: "group_${res.data}",
                          groupID: res.data,
                          type: 2,
                          showName: groupName,
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats ($displayName)", style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: () => _showNewChatMenu(context),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: TIMUIKitConversation(
        onTapItem: (conv) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ModernChatRoomScreen(conversation: conv),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------
// 4. CONTACTS & GROUPS DIRECTORY
// ----------------------------------------------------
class ContactsTab extends StatelessWidget {
  const ContactsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts & Groups", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: TIMUIKitContact(
        onTapItem: (item) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ModernChatRoomScreen(
                conversation: V2TimConversation(
                  conversationID: "c2c_${item.userID}",
                  type: 1,
                  userID: item.userID,
                  showName: (item.friendRemark != null && item.friendRemark!.isNotEmpty)
                      ? item.friendRemark
                      : (item.userProfile?.nickName ?? item.userID),
                  faceUrl: item.userProfile?.faceUrl,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------
// 5. PROFILE & SETTINGS
// ----------------------------------------------------
class ProfileTab extends StatelessWidget {
  final String userId;
  final String displayName;
  final String avatarUrl;

  const ProfileTab({
    super.key,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0x1A6366F1),
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 48, color: Color(0xFF6366F1)) : null,
            ),
            const SizedBox(height: 16),
            Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("@$userId", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Sign Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  await TIMUIKitCore.getInstance().logout();
                  await TUICallKit.instance.logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const TencentLoginScreen()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 6. MODERN CHAT ROOM (Audio Call, Video Call, Single Clean Header)
// ----------------------------------------------------
class ModernChatRoomScreen extends StatelessWidget {
  final V2TimConversation conversation;
  const ModernChatRoomScreen({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final isGroup = conversation.type == 2;
    final targetId = isGroup ? conversation.groupID : conversation.userID;

    return TIMUIKitTheme(
      theme: const TUITheme(
        primaryColor: Color(0xFF6366F1),
        secondaryColor: Color(0xFF4F46E5),
        chatMessageItemFromSelfBgColor: Color(0xFF6366F1),
        chatMessageItemFromOthersBgColor: Color(0xFFF3F4F6),
        chatBgColor: Color(0xFFFAFAFA),
      ),
      child: Scaffold(
        body: TIMUIKitChat(
          conversation: conversation,
          config: const TIMUIKitChatConfig(
            isShowAvatar: true,
            isAllowClickAvatar: true,
            isShowReadingStatus: false,
          ),
          appBarConfig: AppBar(
            actions: isGroup
                ? []
                : [
                    // Voice Call
                    IconButton(
                      icon: const Icon(Icons.phone_rounded, color: Color(0xFF6366F1)),
                      tooltip: "Voice Call",
                      onPressed: () {
                        if (targetId != null) {
                          TUICallKit.instance.calls([targetId], TUICallMediaType.audio);
                        }
                      },
                    ),
                    // Video Call
                    IconButton(
                      icon: const Icon(Icons.videocam_rounded, color: Color(0xFF6366F1)),
                      tooltip: "Video Call",
                      onPressed: () {
                        if (targetId != null) {
                          TUICallKit.instance.calls([targetId], TUICallMediaType.video);
                        }
                      },
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

