import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
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

const Color ink = Color(0xFF151522);
const Color paper = Color(0xFFF7F6F2);
const Color violet = Color(0xFF6D5CE7);
const Color coral = Color(0xFFFF8067);
const Color softViolet = Color(0xFFEDEAFF);
const Color mutedInk = Color(0xFF777587);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KatsKlubApp());
}

class KatsKlubApp extends StatelessWidget {
  const KatsKlubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData.light().textTheme;
    return MaterialApp(
      title: "KatsKlub",
      debugShowCheckedModeBanner: false,
      navigatorObservers: [TUICallKit.navigatorObserver],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: "Plus Jakarta Sans",
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: violet,
          brightness: Brightness.light,
          primary: violet,
          onPrimary: Colors.white,
          surface: paper,
          onSurface: ink,
        ),
        textTheme: baseTextTheme.copyWith(
          displaySmall: baseTextTheme.displaySmall?.copyWith(
            color: ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(
            color: ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            color: ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
            color: ink,
            height: 1.45,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            color: mutedInk,
            height: 1.45,
          ),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          hintStyle: const TextStyle(color: Color(0xFFA19EAC)),
          labelStyle: const TextStyle(color: mutedInk),
          prefixIconColor: violet,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE9E7EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: violet, width: 1.5),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
          height: 74,
          indicatorColor: softViolet,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? violet : mutedInk,
              size: 22,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const TencentLoginScreen(),
    );
  }
}

/// Shared TUIKit theme bridge, kept separate so the chat SDK remains isolated
/// from the rest of the app's visual system.
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

class KatsKlubMark extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const KatsKlubMark({
    super.key,
    this.size = 64,
    this.showWordmark = true,
  });

  static const String _svg = '''
<svg width="96" height="96" viewBox="0 0 96 96" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="violet" x1="12" y1="6" x2="85" y2="90" gradientUnits="userSpaceOnUse">
      <stop stop-color="#8877FF"/>
      <stop offset="1" stop-color="#5A48D5"/>
    </linearGradient>
    <linearGradient id="coral" x1="17" y1="16" x2="78" y2="79" gradientUnits="userSpaceOnUse">
      <stop stop-color="#FFB28C"/>
      <stop offset="1" stop-color="#FF705E"/>
    </linearGradient>
  </defs>
  <path d="M48 8C25.909 8 8 23.67 8 43c0 10.44 5.36 19.84 13.87 26.27L18 86l17.98-9.72C40.1 78.04 43.97 78.99 48 79c22.091 0 40-15.67 40-36S70.091 8 48 8Z" fill="url(#violet)"/>
  <path d="M29.2 47.3c0-10.7 8.36-19.3 18.76-19.3 5.02 0 9.61 2.02 12.95 5.3l-6.83 6.78a8.7 8.7 0 0 0-6.12-2.5c-4.9 0-8.86 4.04-8.86 9.72 0 5.69 3.96 9.73 8.86 9.73 2.42 0 4.56-.96 6.12-2.5l6.83 6.78c-3.34 3.28-7.93 5.3-12.95 5.3-10.4 0-18.76-8.61-18.76-19.31Z" fill="url(#coral)"/>
  <circle cx="70" cy="20" r="7" fill="#FFB28C"/>
  <circle cx="26" cy="64" r="3" fill="#FFF8F5" fill-opacity=".8"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.string(
          _svg,
          width: size,
          height: size,
          semanticsLabel: "KatsKlub mark",
        ),
        if (showWordmark) ...[
          const SizedBox(width: 12),
          const Text(
            "KatsKlub",
            style: TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: violet,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String fallback;
  final double radius;
  final Color backgroundColor;

  const _Avatar({
    this.imageUrl,
    required this.fallback,
    this.radius = 24,
    this.backgroundColor = softViolet,
  });

  @override
  Widget build(BuildContext context) {
    final safeImage = imageUrl ?? "";
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: safeImage.isNotEmpty ? NetworkImage(safeImage) : null,
      child: safeImage.isEmpty
          ? Text(
              fallback.isEmpty ? "K" : fallback.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: violet,
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class TencentLoginScreen extends StatefulWidget {
  const TencentLoginScreen({super.key});

  @override
  State<TencentLoginScreen> createState() => _TencentLoginScreenState();
}

class _TencentLoginScreenState extends State<TencentLoginScreen> {
  final TextEditingController _idController = TextEditingController();
  bool _loading = false;
  String _status = "Ready when you are";

  @override
  void initState() {
    super.initState();
    _initTUIKit();
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _initTUIKit() async {
    try {
      await TIMUIKitCore.getInstance().init(
        sdkAppID: sdkAppId,
        loglevel: LogLevelEnum.V2TIM_LOG_DEBUG,
        listener: V2TimSDKListener(),
        onTUIKitCallbackListener: (dynamic callback) {},
      );
    } catch (e) {
      debugPrint("TUIKit init warning: $e");
    }
  }

  Future<void> _login() async {
    final userId = _idController.text.trim();
    if (userId.isEmpty) {
      setState(() => _status = "Enter your user ID to continue");
      return;
    }

    setState(() {
      _loading = true;
      _status = "Fetching your profile...";
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
        setState(() => _status = "Opening your conversations...");

        final loginRes = await TIMUIKitCore.getInstance().login(
          userID: userId,
          userSig: userSig,
        );

        if (loginRes.code == 0) {
          await TencentImSDKPlugin.v2TIMManager.setSelfInfo(
            userFullInfo: V2TimUserFullInfo(
              nickName: nickName,
              faceUrl: avatarUrl,
            ),
          );

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
      setState(() => _status = "Connection error. Please try again.");
      debugPrint("Login error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 820;
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: isWide
                  ? Row(
                      children: [
                        const Expanded(child: _WelcomePanel()),
                        const SizedBox(width: 56),
                        Expanded(child: _LoginCard(onLogin: _login, controller: _idController, loading: _loading, status: _status)),
                      ],
                    )
                  : Column(
                      children: [
                        const _WelcomePanel(compact: true),
                        const SizedBox(height: 26),
                        _LoginCard(onLogin: _login, controller: _idController, loading: _loading, status: _status),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  final bool compact;

  const _WelcomePanel({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 20, vertical: compact ? 4 : 24),
      child: Column(
        crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          const KatsKlubMark(size: 68),
          const SizedBox(height: 38),
          const _Eyebrow("Your people, in one room"),
          const SizedBox(height: 14),
          Text(
            "Good chats\nfeel like home.",
            textAlign: compact ? TextAlign.center : TextAlign.left,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: compact ? 36 : 50),
          ),
          const SizedBox(height: 18),
          Text(
            "A calmer space for the people, ideas, and little moments you want to keep close.",
            textAlign: compact ? TextAlign.center : TextAlign.left,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: mutedInk, fontSize: 16),
          ),
          if (!compact) ...[
            const SizedBox(height: 38),
            const _FeaturePill(icon: Icons.forum_rounded, text: "Conversations that stay human"),
            const SizedBox(height: 12),
            const _FeaturePill(icon: Icons.call_rounded, text: "Voice and video when words fall short"),
          ],
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeaturePill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.check_rounded, size: 18, color: coral),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: ink, fontWeight: FontWeight.w600))),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final VoidCallback onLogin;
  final TextEditingController controller;
  final bool loading;
  final String status;

  const _LoginCard({
    required this.onLogin,
    required this.controller,
    required this.loading,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [violet, coral]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.login_rounded, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text("Welcome back", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text("Sign in with your KatsKlub ID to pick up where you left off."),
            const SizedBox(height: 28),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => loading ? null : onLogin(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.alternate_email_rounded),
                labelText: "KatsKlub ID",
                hintText: "e.g. alex09",
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: loading ? null : onLogin,
                child: loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Enter KatsKlub"),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 15, color: violet),
                const SizedBox(width: 7),
                Expanded(child: Text(status, style: const TextStyle(color: mutedInk, fontSize: 12))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
      ProfileTab(userId: widget.currentUserId, displayName: widget.displayName, avatarUrl: widget.avatarUrl),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: "Chats"),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt_rounded), label: "People"),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }
}

class ConversationTab extends StatelessWidget {
  final String currentUserId;
  final String displayName;

  const ConversationTab({super.key, required this.currentUserId, required this.displayName});

  void _showNewChatMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Start something new", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              const Text("Choose how you want to bring people in."),
              const SizedBox(height: 18),
              _ActionTile(
                icon: Icons.person_add_alt_1_rounded,
                title: "Direct chat",
                subtitle: "Message one person privately",
                onTap: () {
                  Navigator.pop(ctx);
                  _openDirectChatDialog(context);
                },
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.groups_rounded,
                title: "Create a group",
                subtitle: "Make a room for your circle",
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateGroupDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDirectChatDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: paper,
        title: const Text("New direct chat"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: "KatsKlub ID", hintText: "e.g. user2"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              final target = controller.text.trim();
              if (target.isNotEmpty) {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModernChatRoomScreen(
                      conversation: V2TimConversation(conversationID: "c2c_$target", type: 1, userID: target, showName: target),
                    ),
                  ),
                );
              }
            },
            child: const Text("Start chat"),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _openCreateGroupDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: paper,
        title: const Text("Create a group"),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Group name", hintText: "e.g. Weekend circle"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
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
                        conversation: V2TimConversation(conversationID: "group_${res.data}", groupID: res.data, type: 2, showName: groupName),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text("Create group"),
          ),
        ],
      ),
    ).then((_) => nameCtrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow("Your space"),
            const SizedBox(height: 2),
            Text("Good to see you, $displayName", style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: _Avatar(fallback: displayName, radius: 20),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        elevation: 0,
        onPressed: () => _showNewChatMenu(context),
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: const Text("New chat"),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Recent conversations", style: TextStyle(color: mutedInk, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: TIMUIKitConversation(
                    onTapItem: (conv) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ModernChatRoomScreen(conversation: conv)));
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: softViolet, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: violet),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: mutedInk)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: mutedInk),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactsTab extends StatelessWidget {
  const ContactsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow("Your circle"),
            const SizedBox(height: 2),
            Text("People & groups", style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: Card(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: TIMUIKitContact(
              onTapItem: (item) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModernChatRoomScreen(
                      conversation: V2TimConversation(
                        conversationID: "c2c_${item.userID}",
                        type: 1,
                        userID: item.userID,
                        showName: (item.friendRemark != null && item.friendRemark!.isNotEmpty) ? item.friendRemark : (item.userProfile?.nickName ?? item.userID),
                        faceUrl: item.userProfile?.faceUrl,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  final String userId;
  final String displayName;
  final String avatarUrl;

  const ProfileTab({super.key, required this.userId, required this.displayName, required this.avatarUrl});

  Future<void> _signOut(BuildContext context) async {
    await TIMUIKitCore.getInstance().logout();
    await TUICallKit.instance.logout();
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TencentLoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile", style: Theme.of(context).textTheme.titleLarge)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ink, Color(0xFF302C53)]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x2EFFFFFF)),
                    child: _Avatar(imageUrl: avatarUrl, fallback: displayName, radius: 42, backgroundColor: const Color(0xFFFFE0D6)),
                  ),
                  const SizedBox(height: 16),
                  Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text("@$userId", style: const TextStyle(color: Color(0xFFB9B4D8), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(99)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF6BE2AE)),
                        SizedBox(width: 7),
                        Text("Available to chat", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.lock_outline_rounded, color: violet),
                    title: Text("Private by default", style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text("Your space stays yours."),
                  ),
                  const Divider(height: 1, indent: 70, endIndent: 18),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: coral),
                    title: const Text("Sign out", style: TextStyle(color: coral, fontWeight: FontWeight.w800)),
                    onTap: () => _signOut(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernChatRoomScreen extends StatelessWidget {
  final V2TimConversation conversation;

  const ModernChatRoomScreen({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final isGroup = conversation.type == 2;
    final targetId = isGroup ? conversation.groupID : conversation.userID;

    return TIMUIKitTheme(
      theme: const TUITheme(
        primaryColor: violet,
        secondaryColor: Color(0xFF5A48D5),
        chatMessageItemFromSelfBgColor: violet,
        chatMessageItemFromOthersBgColor: Colors.white,
        chatBgColor: paper,
      ),
      child: Scaffold(
        backgroundColor: paper,
        body: TIMUIKitChat(
          conversation: conversation,
          config: const TIMUIKitChatConfig(isShowAvatar: true, isAllowClickAvatar: true, isShowReadingStatus: false),
          appBarConfig: AppBar(
            backgroundColor: paper,
            title: Text(conversation.showName ?? "Conversation", style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
            actions: isGroup
                ? []
                : [
                    IconButton(
                      icon: const Icon(Icons.phone_rounded, color: violet),
                      tooltip: "Voice call",
                      onPressed: () {
                        if (targetId != null) TUICallKit.instance.calls([targetId], TUICallMediaType.audio);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.videocam_rounded, color: violet),
                      tooltip: "Video call",
                      onPressed: () {
                        if (targetId != null) TUICallKit.instance.calls([targetId], TUICallMediaType.video);
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
          ),
        ),
      ),
    );
  }
}
