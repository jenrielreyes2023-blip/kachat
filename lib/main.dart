import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:tencent_cloud_chat_sdk/enum/log_level_enum.dart";
import "package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart";
import "package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart";
import "package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart";
import "package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart";
import "package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart";
import "package:tencent_cloud_chat_uikit/theme/tui_theme.dart";

const int sdkAppId = 20046974;
const String tokenApiUrl = "https://katsklub.top/api/chat/token";

// Modern Brand Theme Palette (Royal Indigo / Deep Purple & Neutral Light Grays)
const TUITheme customTUITheme = TUITheme(
  primaryColor: Color(0xFF4F46E5), // Royal Indigo Brand
  secondaryColor: Color(0xFF6366F1),
  lightPrimaryColor: Color(0xFF818CF8),
  appbarBgColor: Color(0xFF4F46E5),
  appbarTextColor: Colors.white,
  chatHeaderBgColor: Color(0xFF4F46E5),
  chatHeaderTitleTextColor: Colors.white,
  chatHeaderBackTextColor: Colors.white,
  chatHeaderActionTextColor: Colors.white,
  chatBgColor: Color(0xFFF8FAFC),
  // Sent bubble: Custom brand Deep Purple / Royal Blue
  chatMessageItemFromSelfBgColor: Color(0xFF4F46E5),
  // Received bubble: Neutral soft light-gray card
  chatMessageItemFromOthersBgColor: Color(0xFFF1F5F9),
  // High contrast readability text colors
  chatMessageItemTextColor: Color(0xFF0F172A),
  conversationItemBgColor: Colors.white,
  conversationItemActiveBgColor: Color(0xFFEEF2FF),
  conversationItemTitleTextColor: Color(0xFF0F172A),
  conversationItemLastMessageTextColor: Color(0xFF64748B),
  conversationItemTitmeTextColor: Color(0xFF94A3B8),
  conversationItemBorderColor: Color(0xFFE2E8F0),
  inputFillColor: Color(0xFFF1F5F9),
  weakBackgroundColor: Color(0xFFF8FAFC),
  weakDividerColor: Color(0xFFE2E8F0),
  weakTextColor: Color(0xFF64748B),
  darkTextColor: Color(0xFF1E293B),
  white: Colors.white,
  black: Color(0xFF0F172A),
);

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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: "KaChat",
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
        primary: const Color(0xFF4F46E5),
        surface: const Color(0xFFF8FAFC),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
    ),
    home: const TencentLoginScreen(),
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
    TIMUIKitCore.getInstance().setTheme(theme: customTUITheme);
  }

  Future<void> _login() async {
    final userId = _idController.text.trim();
    if (userId.isEmpty) return;

    setState(() {
      _loading = true;
      _status = "Fetching token & profile...";
    });

    try {
      final res = await http.post(
        Uri.parse(tokenApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );

      final data = jsonDecode(res.body);
      final userSig = data["userSig"] as String?;
      final nickName = (data["nickName"] as String?) ?? userId;
      final avatarUrl = (data["avatarUrl"] as String?) ?? "";

      if (userSig != null && userSig.isNotEmpty) {
        setState(() => _status = "Logging in to TUIKit...");

        final loginRes = await TIMUIKitCore.getInstance().login(
          userID: userId,
          userSig: userSig,
        );

        if (loginRes.code == 0 && mounted) {
          // Sync profile avatar & display name to Tencent Cloud Chat
          await TencentImSDKPlugin.v2TIMManager.setSelfInfo(
            userFullInfo: V2TimUserFullInfo(
              nickName: nickName,
              faceUrl: avatarUrl,
            ),
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ConversationListScreen(
                  currentUserId: userId,
                  nickName: nickName,
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shadowColor: const Color(0x334F46E5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF818CF8), width: 2),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      size: 38,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Welcome to KaChat",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Enter your user ID to start messaging",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF4F46E5)),
                      labelText: "User ID (e.g. admin, user1, user2)",
                      hintText: "Enter user ID or username",
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text(
                              "Log In & Open Chat",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(_status, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConversationListScreen extends StatelessWidget {
  final String currentUserId;
  final String nickName;

  const ConversationListScreen({
    super.key,
    required this.currentUserId,
    required this.nickName,
  });

  void _startDirectChat(BuildContext context) {
    final targetController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text("New Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: targetController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: "Target User ID",
            hintText: "Enter user2, admin, john, etc.",
            prefixIcon: const Icon(Icons.person_search_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
            child: const Text("Start Chat"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TIMUIKitTheme(
      theme: customTUITheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          title: Text(
            "Chats ($nickName)",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: "Log Out",
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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: () => _startDirectChat(context),
          icon: const Icon(Icons.add_comment_rounded),
          label: const Text("New Chat", style: TextStyle(fontWeight: FontWeight.w600)),
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
      ),
    );
  }
}

class ChatRoomScreen extends StatelessWidget {
  final V2TimConversation conversation;

  const ChatRoomScreen({
    super.key,
    required this.conversation,
  });

  Widget _buildAvatarPlaceholder(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
    return Container(
      color: const Color(0xFF6366F1),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleName = conversation.showName ?? conversation.userID ?? "Chat";

    return TIMUIKitTheme(
      theme: customTUITheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            tooltip: "Back",
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipOval(
                  child: (conversation.faceUrl != null && conversation.faceUrl!.isNotEmpty)
                      ? Image.network(
                          conversation.faceUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(titleName),
                        )
                      : _buildAvatarPlaceholder(titleName),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titleName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: TIMUIKitChat(
          conversation: conversation,
          config: const TIMUIKitChatConfig(
            isAllowShowMorePanel: true,
            isAllowEmojiPanel: true,
            isAllowSoundMessage: true,
            isShowAvatar: true,
            isShowReadingStatus: true,
            showC2cMessageEditStatus: true,
          ),
          morePanelConfig: MorePanelConfig(
            showGalleryPickAction: true,
            showCameraAction: true,
            showFilePickAction: true,
            showVoiceCall: false,
            showVideoCall: false,
          ),
          userAvatarBuilder: (context, message) {
            final faceUrl = message.faceUrl ?? "";
            final name = message.nickName ?? message.sender ?? message.userID ?? "?";
            final isSelf = message.isSelf ?? false;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelf ? const Color(0xFF818CF8) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: faceUrl.isNotEmpty
                    ? Image.network(
                        faceUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(name),
                      )
                    : _buildAvatarPlaceholder(name),
              ),
            );
          },
        ),
      ),
    );
  }
}
