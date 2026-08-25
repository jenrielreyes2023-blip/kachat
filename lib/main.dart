import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:tencent_cloud_chat_sdk/models/v2_tim_message.dart";
import "package:tencent_cloud_chat_sdk/models/v2_tim_sdk_listener.dart";
import "package:tencent_cloud_chat_sdk/models/v2_tim_advanced_msg_listener.dart";
import "package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart";
import "package:tencent_cloud_chat_sdk/enum/log_level_enum.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: TencentChatTestApp()));
}

class TencentChatTestApp extends StatefulWidget {
  const TencentChatTestApp({super.key});

  @override
  State<TencentChatTestApp> createState() => _TencentChatTestAppState();
}

class _TencentChatTestAppState extends State<TencentChatTestApp> {
  final String backendUrl = "https://katsklub.top/api/chat/token";
  final int sdkAppId = 20046974;

  final TextEditingController _myUserIdController = TextEditingController();
  final TextEditingController _targetUserIdController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool isSdkInited = false;
  bool isLoggedIn = false;
  List<String> logs = [];

  @override
  void initState() {
    super.initState();
    _initTencentSdk();
  }

  void _addLog(String log) {
    setState(() {
      logs.insert(0, log);
    });
  }

  Future<void> _initTencentSdk() async {
    final res = await TencentImSDKPlugin.v2TIMManager.initSDK(
      sdkAppID: sdkAppId,
      loglevel: LogLevelEnum.V2TIM_LOG_DEBUG,
      listener: V2TimSDKListener(
        onConnectSuccess: () => _addLog("Connected to Tencent server!"),
        onConnectFailed: (code, desc) => _addLog("Connect failed: $code - $desc"),
        onKickedOffline: () => _addLog("Kicked offline!"),
      ),
    );

    if (res.code == 0) {
      TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .addAdvancedMsgListener(
            listener: V2TimAdvancedMsgListener(
              onRecvNewMessage: (V2TimMessage msg) {
                final sender = msg.sender ?? "Unknown";
                final text = msg.textElem?.text ?? "";
                _addLog("Received from $sender: $text");
              },
            ),
          );

      setState(() => isSdkInited = true);
      _addLog("SDK Initialized successfully.");
    } else {
      _addLog("Failed to init SDK: ${res.desc}");
    }
  }

  Future<void> _login() async {
    final userId = _myUserIdController.text.trim();
    if (userId.isEmpty) return;

    _addLog("Fetching token for $userId...");
    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userSig = data["userSig"];

        _addLog("Logging in to Tencent Cloud...");
        final loginRes = await TencentImSDKPlugin.v2TIMManager.login(
          userID: userId,
          userSig: userSig,
        );

        if (loginRes.code == 0) {
          setState(() => isLoggedIn = true);
          _addLog("Logged in successfully as $userId!");
        } else {
          _addLog("Login failed: ${loginRes.desc}");
        }
      } else {
        _addLog("Backend error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      _addLog("Error connecting to backend: $e");
    }
  }

  Future<void> _sendMessage() async {
    final targetUser = _targetUserIdController.text.trim();
    final text = _messageController.text.trim();
    if (targetUser.isEmpty || text.isEmpty) return;

    _addLog("Sending to $targetUser: $text");
    final sendRes = await TencentImSDKPlugin.v2TIMManager.sendC2CTextMessage(
      text: text,
      userID: targetUser,
    );

    if (sendRes.code == 0) {
      _addLog("Message sent!");
      _messageController.clear();
    } else {
      _addLog("Send failed: ${sendRes.desc}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tencent IM Standalone Test"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!isLoggedIn) ...[
              TextField(
                controller: _myUserIdController,
                decoration: const InputDecoration(
                  labelText: "Your User ID (from your DB)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isSdkInited ? _login : null,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                child: const Text("Log In to Chat"),
              ),
            ] else ...[
              TextField(
                controller: _targetUserIdController,
                decoration: const InputDecoration(
                  labelText: "Send to (Target User ID)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: "Type message...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.indigo,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ],
            const Divider(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Logs & Incoming Messages:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, i) => Text(
                    logs[i],
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
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
