import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'web_search_view_stub.dart'
    if (dart.library.js_interop) 'web_search_view.dart';
class SessionCheckScreen extends StatefulWidget {
  const SessionCheckScreen({super.key});

  @override
  State<SessionCheckScreen> createState() => _SessionCheckScreenState();
}

class _SessionCheckScreenState extends State<SessionCheckScreen> {
  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    const storage = FlutterSecureStorage();

    final token = await storage.read(
      key: 'auth_token',
    );

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => JosoraChat(
          token: token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0B0F19),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
void main() {
  runApp(const JosoraApp());
}

class JosoraApp extends StatelessWidget {
  const JosoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JOSORA',
      theme: ThemeData.dark(),
      home: const JosoraIntroScreen(),
    );
  }
}

class JosoraIntroScreen extends StatefulWidget {
  const JosoraIntroScreen({super.key});

  @override
  State<JosoraIntroScreen> createState() => _JosoraIntroScreenState();
}
class JosoraEnergyPainter extends CustomPainter {
  final double progress;

  JosoraEnergyPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shortestSide = math.min(size.width, size.height);

    final backgroundPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF071B43),
          Color(0xFF020817),
          Color(0xFF01030A),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(
      Offset.zero & size,
      backgroundPaint,
    );

    final coreRadius = shortestSide * 0.12;
    final rotation = progress * math.pi * 4;

    // Rotating orbital rings.
    for (int i = 0; i < 4; i++) {
      final radius = coreRadius * (1.35 + i * 0.32);
      

      final ringPaint = Paint()
        ..color = [
          const Color(0xFF167BFF),
          const Color(0xFF1749C7),
          const Color(0xFF45C8FF),
          const Color(0xFF0A3C91),
        ][i].withOpacity(0.8 - i * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 2.0 : 1.0;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation * (i.isEven ? 1 : -0.7));

      final oval = Rect.fromCenter(
        center: Offset.zero,
        width: radius * 2,
        height: radius * (i.isEven ? 0.55 : 1.35),
      );

      canvas.drawArc(
        oval,
        i * 0.8,
        math.pi * 1.45,
        false,
        ringPaint,
      );

      canvas.restore();

      // Small orbiting energy nodes.
      final angle = rotation * (i.isEven ? 1 : -1) + i;
      final node = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawCircle(
        node,
        3.0,
        Paint()
          ..color = const Color(0xFF76D8FF)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            7,
          ),
      );

      canvas.drawCircle(
        node,
        1.7,
        Paint()..color = Colors.white,
      );
    }

    // Glowing energy core.
    canvas.drawCircle(
      center,
      coreRadius * 1.5,
      Paint()
        ..color = const Color(0xFF087BFF).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          38,
        ),
    );

    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFFBCEBFF),
            Color(0xFF168BFF),
            Color(0xFF073B9C),
            Color(0xFF020817),
          ],
          stops: [0.0, 0.2, 0.65, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: center,
            radius: coreRadius,
          ),
        ),
    );

    // Scanning beam.
    final beamY = size.height * progress;

    canvas.drawRect(
      Rect.fromLTWH(0, beamY, size.width, 1.2),
      Paint()
        ..color = const Color(0xFF168BFF).withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          5,
        ),
    );

    // Expanding final energy wave.
    if (progress > 0.58) {
      final waveProgress = (progress - 0.58) / 0.42;
      final wavePaint = Paint()
        ..color = const Color(0xFF168BFF)
            .withOpacity((1 - waveProgress).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 + waveProgress * 20;

      canvas.drawCircle(
        center,
        shortestSide * waveProgress * 1.1,
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant JosoraEnergyPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _JosoraIntroScreenState extends State<JosoraIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _revealOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    

    
    _revealOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.68, 1.0, curve: Curves.easeIn),
    );

    _controller.forward().then((_) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SessionCheckScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020817),
      body: AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: JosoraEnergyPainter(
            progress: _controller.value,
          ),
          size: Size.infinite,
        ),

        Center(
          child: Opacity(
            opacity: (1.0 - _revealOpacity.value).clamp(0.0, 1.0),
            child: const Text(
              'JOSORA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                shadows: [
                  Shadow(
                    color: Color(0xFF168BFF),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          ),
        ),

        Opacity(
          opacity: _revealOpacity.value,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color(0xFF071B43),
                  Color(0xFF01030A),
                ],
              ),
            ),
            child: SizedBox.expand(),
          ),
        ),
      ],
    );
  },
),
    );
  }
}
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  Future<void> handleLogin() async {
  final email = emailController.text.trim();
  final password = passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    final response = await http.post(
      Uri.parse('http://localhost:3000/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      const storage = FlutterSecureStorage();

await storage.write(
  key: 'auth_token',
  value: data['token'],
);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => JosoraChat(
  token: data['token'],
),
        ),
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email or password.'),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not connect to JOSORA.'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 70,
                    color: Colors.blueAccent,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'JOSORA',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Your Personal AI',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 40),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      filled: true,
                      fillColor: const Color(0xFF151B29),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true,
                      fillColor: const Color(0xFF151B29),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
  icon: Icon(
    obscurePassword
        ? Icons.visibility_outlined
        : Icons.visibility_off_outlined,
  ),
  onPressed: () {
    setState(() {
      obscurePassword = !obscurePassword;
    });
  },
),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleLogin,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Log In',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),

TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  },
  child: const Text(
    'Create Account',
    style: TextStyle(fontSize: 16),
  ),
),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class JosoraChat extends StatefulWidget {
  final String token;

  const JosoraChat({
    super.key,
    required this.token,
  });

  @override
  State<JosoraChat> createState() => _JosoraChatState();
}


class _JosoraChatState extends State<JosoraChat> {
  String? authToken;
  String? selectedImageBase64;
  String? currentChatId;
  bool isPro = false;
  bool isSubscriptionLoading = true;
  List<Map<String, dynamic>> chatHistory = [];
@override
void initState() {
  super.initState();
  authToken = widget.token;
  _speech = stt.SpeechToText();
  loadChatHistory();
  loadSubscriptionStatus();
}
  final TextEditingController messageController = TextEditingController();

  List<Map<String, dynamic>> messages = [];

  bool isLoading = false;
  late final stt.SpeechToText _speech;
bool _isListening = false;
  

Future<bool> login(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('http://localhost:3000/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      

      return true;
    }

    return false;
  } catch (e) {
    return false;
  }
}


Future<void> toggleVoiceSearch() async {
  if (_isListening) {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
    return;
  }

  final available = await _speech.initialize(
    onStatus: (status) {
      if (status == 'notListening' && mounted) {
        setState(() {
          _isListening = false;
        });
      }
    },
    onError: (error) {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    },
  );

  if (!available || !mounted) return;

  setState(() {
    _isListening = true;
  });

  await _speech.listen(
    onResult: (result) {
      if (mounted) {
        setState(() {
          messageController.text = result.recognizedWords;
          messageController.selection = TextSelection.collapsed(
            offset: messageController.text.length,
          );
        });
      }
    },
  );
}
  Future<void> sendMessage() async {
    final message = messageController.text.trim();
    final imageToSend = selectedImageBase64;

if (message.isEmpty && selectedImageBase64 == null || isLoading) return;
if (authToken == null) {
  
}
print('AUTH TOKEN LENGTH: ${authToken?.length}');
if (authToken == null) {
  return;
}

    setState(() {
  messages.add({
    'sender': 'user',
    'text': message,
  });

  messageController.clear();
  selectedImageBase64 = null;
  isLoading = true;
});

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/chat'),
        headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $authToken',
},
        body: jsonEncode({
  'message': message,
  'chatId': currentChatId,
  'imageBase64': imageToSend,
}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentChatId = data['chatId'];
        setState(() {
          messages.add({
            'sender': 'josora',
            'text': data['reply'],
          });
        });
        await loadChatHistory();
      } else {
        setState(() {
          messages.add({
            'sender': 'josora',
            'text': 'Server error: ${response.statusCode}',
          });
        });
      }
    } catch (error) {
      setState(() {
        messages.add({
          'sender': 'josora',
          'text': 'Flutter error: $error',
        });
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> draftWhatsAppMessage() async {
if (isSubscriptionLoading) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Checking your JOSORA Pro subscription.'),
),
);
return;
}

if (!isPro) {
showDialog(
context: context,
builder: (context) => AlertDialog(
title: const Text('JOSORA Connect Pro'),
content: const Text(
'Preparing and sharing messages through other apps '
'is a JOSORA Pro feature.',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('Close'),
),
],
),
);
return;
}

final controller = TextEditingController();

final draft = await showDialog<String>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Draft a WhatsApp Message'),
content: TextField(
controller: controller,
maxLines: 5,
decoration: const InputDecoration(
hintText: 'Write the message you want to share...',
border: OutlineInputBorder(),
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext),
child: const Text('Cancel'),
),
ElevatedButton(
onPressed: () {
Navigator.pop(dialogContext, controller.text.trim());
},
child: const Text('Continue'),
),
],
),
);

controller.dispose();

if (!mounted || draft == null || draft.isEmpty) return;

await SharePlus.instance.share(
ShareParams(text: draft),
);
}
void startNewChat() {
  print("NEW CHAT BUTTON PRESSED");

  setState(() {
    currentChatId = null;
    messages.clear();
    messageController.clear();
  });
}
Future<void> pickImage() async {
  final ImagePicker picker = ImagePicker();

  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
  );

  if (image != null) {
    final bytes = await image.readAsBytes();
selectedImageBase64 = base64Encode(bytes);
    setState(() {
      messages.add({
        'sender': 'user',
        'text': '🖼️ Image selected',
        'image': image.path,
      });
    });

    print('IMAGE SELECTED: ${image.path}');
  }
}
Future<void> loadSubscriptionStatus() async {
try {
final response = await http.get(
Uri.parse('http://localhost:3000/subscription'),
headers: {
'Authorization': 'Bearer ${widget.token}',
},
);

if (!mounted) return;

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);

  setState(() {
    isPro = data['isPro'] == true;
    isSubscriptionLoading = false;
  });
} else {
  setState(() {
    isPro = false;
    isSubscriptionLoading = false;
  });
}

} catch (e) {
if (!mounted) return;

setState(() {
  isPro = false;
  isSubscriptionLoading = false;
});

}
}
Future<void> loadChatHistory() async {
  try {
    final response = await http.get(
      Uri.parse('http://localhost:3000/chats'),
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        chatHistory = List<Map<String, dynamic>>.from(
          data['chats'],
        );
      });
    }
  } catch (error) {
    print('CHAT HISTORY ERROR: $error');
  }
}
Future<void> renameChat(String chatId, String currentTitle) async {
  final controller = TextEditingController(text: currentTitle);

  final newTitle = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter chat name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                controller.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  if (newTitle == null || newTitle.isEmpty) {
    return;
  }

  try {
    final response = await http.patch(
      Uri.parse('http://localhost:3000/chats/$chatId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'title': newTitle,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        final chatIndex = chatHistory.indexWhere(
          (chat) => chat['id'] == chatId,
        );

        if (chatIndex != -1) {
          chatHistory[chatIndex]['title'] = newTitle;
        }
      });
    } else {
      print('RENAME CHAT ERROR: ${response.statusCode}');
    }
  } catch (error) {
    print('RENAME CHAT ERROR: $error');
  }
}
Future<void> deleteChat(String chatId) async {
  try {
    final response = await http.delete(
      Uri.parse('http://localhost:3000/chats/$chatId'),
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        chatHistory.removeWhere((chat) => chat['id'] == chatId);

        if (currentChatId == chatId) {
          currentChatId = null;
          messages.clear();
        }
      });
    } else {
      print('DELETE CHAT ERROR: ${response.statusCode}');
    }
  } catch (error) {
    print('DELETE CHAT ERROR: $error');
  }
}
Future<void> loadChatMessages(String chatId) async {
  try {
    final response = await http.get(
      Uri.parse('http://localhost:3000/chats/$chatId/messages'),
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final loadedMessages =
          List<Map<String, dynamic>>.from(data['messages']);

      setState(() {
        currentChatId = chatId;

        messages = loadedMessages.map((message) {
          return {
            'sender':
                message['role'] == 'user' ? 'user' : 'josora',
            'text': message['content'],
          };
        }).toList();
      });
    } else {
      print('LOAD CHAT ERROR: ${response.statusCode}');
    }
  } catch (error) {
    print('LOAD CHAT ERROR: $error');
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
  child: SafeArea(
    child: Column(
      children: [
        const DrawerHeader(
          child: Center(
            child: Text(
              'Chat History',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: chatHistory.length,
            itemBuilder: (context, index) {
              final chat = chatHistory[index];

              return ListTile(
  leading: const Icon(Icons.chat_bubble_outline),
  title: Text(
    chat['title'] ?? 'New Chat',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
  
  trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.edit_outlined),
      onPressed: () {
        renameChat(
          chat['id'],
          chat['title'] ?? 'New Chat',
        );
      },
    ),
    IconButton(
      icon: const Icon(
        Icons.delete_outline,
        color: Colors.redAccent,
      ),
      onPressed: () {
        deleteChat(chat['id']);
      },
    ),
  ],
),
  onTap: () {
    loadChatMessages(chat['id']);
    Navigator.pop(context);
  },
);
            },
          ),
       ),

ListTile(
  leading: const Icon(
    Icons.favorite_rounded,
    color: Color(0xFF9A83FF),
  ),
  title: const Text('Therapy Buddy'),
  subtitle: const Text('Your emotional wellness companion'),
  onTap: () {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TherapyBuddyScreen(
          token: authToken ?? '',
        ),
      ),
    );
  },
),
ListTile(
  leading: const Icon(Icons.extension_outlined),
  title: const Text('Plugins'),
  subtitle: const Text('Explore JOSORA tools'),
  onTap: () {
  Navigator.pop(context);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const PluginsScreen(),
    ),
  );
},
),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Settings'),
          onTap: () {
            Navigator.pop(context);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  token: authToken ?? '',
                ),
              ),
            );
          },
        ),
      ],
    ),
  ),
),
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
  backgroundColor: const Color(0xFF0B0F19),
  title: const Text(
    'JOSORA',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    ),
  ),
  actions: [
    Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
    ),
  ],
),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 70,
                          color: Colors.blueAccent,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'JOSORA',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your Personal AI',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];

                      return Align(
                        alignment: message['sender'] == 'user'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(15),
                          constraints: const BoxConstraints(
                            maxWidth: 600,
                          ),
                          decoration: BoxDecoration(
                            color: message['sender'] == 'user'
                                ? Colors.blueAccent
                                : const Color(0xFF151B29),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
MarkdownBody(
data: message['text']!,
styleSheet: MarkdownStyleSheet(
p: const TextStyle(fontSize: 16),
),
),
if (message['sender'] != 'user')
Align(
alignment: Alignment.centerRight,
child: IconButton(
tooltip: 'Share JOSORA answer',
onPressed: () async {
if (isSubscriptionLoading) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Checking your JOSORA Pro subscription. Please wait.',
),
),
);
return;
}

if (!isPro) {
showDialog(
context: context,
builder: (context) => AlertDialog(
title: const Text('JOSORA Connect Pro'),
content: const Text(
'Sharing JOSORA responses with other apps is a Pro feature. '
'Upgrade to JOSORA Pro to unlock it.',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('Close'),
),
],
),
);
return;
}

await SharePlus.instance.share(
ShareParams(
text: message['text']!,
),
);
},
icon: const Icon(
Icons.share_outlined,
color: Colors.white70,
size: 20,
),
),
),
],
),
                        ),
                      );
                    },
                  ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'JOSORA is thinking...',
                style: TextStyle(color: Colors.white60),
              ),
            ),
          Align(
  alignment: Alignment.centerRight,
  child: TextButton.icon(
    onPressed: startNewChat,
    icon: const Icon(Icons.add, color: Colors.white),
    label: const Text(
      'New Chat',
      style: TextStyle(color: Colors.white),
    ),
  ),
),Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
  controller: messageController,
  decoration: InputDecoration(
    hintText: 'Ask JOSORA...',
    filled: true,
    fillColor: const Color(0xFF151B29),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
    prefixIcon: IconButton(
      icon: const Icon(
        Icons.image_outlined,
        color: Colors.white,
      ),
      onPressed: pickImage,
    ),
  ),
  onSubmitted: (_) => sendMessage(),
),
                ),
                const SizedBox(width: 8),
IconButton(
  tooltip: _isListening ? 'Stop voice search' : 'Voice search',
  onPressed: toggleVoiceSearch,
  icon: Icon(
    _isListening ? Icons.mic : Icons.mic_none,
    color: _isListening ? Colors.lightBlueAccent : Colors.white,
  ),
),
const SizedBox(width: 4),
IconButton(
tooltip: 'Draft a WhatsApp message',
onPressed: draftWhatsAppMessage,
icon: const Icon(
Icons.chat_outlined,
color: Colors.greenAccent,
),
),
const SizedBox(width: 4),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class SettingsScreen extends StatelessWidget {
  final String token;

  const SettingsScreen({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
  leading: const Icon(Icons.person_outline),
  title: const Text('Account'),
  subtitle: const Text('Manage your JOSORA account'),
  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AccountScreen(
        token: token,
      ),
    ),
  );
},
),

          ListTile(
  leading: const Icon(Icons.psychology_outlined),
  title: const Text('Memory'),
  subtitle: const Text('Manage what JOSORA remembers'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemoryScreen(
          token: token,
        ),
      ),
    );
  },
),
ListTile(
  leading: const Icon(
    Icons.face_retouching_natural,
    color: Color(0xFF9A83FF),
  ),
  title: const Text('Pro Companion'),
  subtitle: const Text('Talk with your AI companion'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProCompanionVoiceScreen(
          token: token,
        ),
      ),
    );
  },
),

          ListTile(
  leading: const Icon(Icons.workspace_premium_outlined),
  title: const Text('JOSORA Pro'),
  subtitle: const Text('Premium features and subscription'),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProScreen(
          token: token,
        ),
      ),
    );
  },
),

const Divider(),

          ListTile(
  leading: const Icon(Icons.logout),
  title: const Text('Log out'),
  onTap: () async {
    const storage = FlutterSecureStorage();

    await storage.delete(
      key: 'auth_token',
    );

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  },
),
        ],
      ),
    );
  }
}
class AccountScreen extends StatefulWidget {
  final String token;

  const AccountScreen({
    super.key,
    required this.token,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String name = 'Loading...';
  String email = 'Loading...';
  
  @override
void initState() {
  super.initState();
  loadAccount();
}

  Future<void> loadAccount() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/me'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          name = data['user']['name'];
          email = data['user']['email'];
        });
      }
    } catch (error) {
      print('ACCOUNT ERROR: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Name'),
            subtitle: Text(name),
          ),

          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(email),
          ),

          const Divider(),

          ListTile(
  leading: const Icon(Icons.lock_outline),
  title: const Text('Password'),
  subtitle: const Text('Change your password'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(
          token: widget.token,
        ),
      ),
    );
  },
),
const Divider(),
  ListTile(
  leading: const Icon(Icons.favorite_outline),
  title: const Text('JOSORA Companion'),
  subtitle: const Text('Your personal AI best friend'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanionScreen(
          token: widget.token,
        ),
      ),
    );
  },
),
        ],
      ),
    );
  }
}
class MemoryScreen extends StatefulWidget {
  final String token;

  const MemoryScreen({
    super.key,
    required this.token,
  });

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  List<Map<String, dynamic>> memories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMemories();
  }

  Future<void> loadMemories() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/memories'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          memories = List<Map<String, dynamic>>.from(
            data['memories'],
          );
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('MEMORY ERROR: $error');

      setState(() {
        isLoading = false;
      });
    }
  }
Future<void> deleteMemory(int memoryId) async {
    try {
      final response = await http.delete(
        Uri.parse(
          'http://localhost:3000/memories/$memoryId',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          memories.removeWhere(
            (memory) => memory['id'] == memoryId,
          );
        });
      } else {
        print('DELETE MEMORY ERROR: ${response.statusCode}');
      }
    } catch (error) {
      print('DELETE MEMORY ERROR: $error');
    }
  }
  Future<void> editMemory(int memoryId, String currentMemory) async {
    final controller = TextEditingController(
      text: currentMemory,
    );

    final newMemory = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Memory'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter memory',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text.trim(),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newMemory == null || newMemory.isEmpty) {
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse(
          'http://localhost:3000/memories/$memoryId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'memory': newMemory,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final memoryIndex = memories.indexWhere(
            (memory) => memory['id'] == memoryId,
          );

          if (memoryIndex != -1) {
            memories[memoryIndex]['memory'] = newMemory;
          }
        });
      } else {
        print('EDIT MEMORY ERROR: ${response.statusCode}');
      }
    } catch (error) {
      print('EDIT MEMORY ERROR: $error');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : memories.isEmpty
              ? const Center(
                  child: Text(
                    'JOSORA has no saved memories yet.',
                  ),
                )
              : ListView.builder(
                  itemCount: memories.length,
                  itemBuilder: (context, index) {
                    final memory = memories[index];

                    return ListTile(
  leading: const Icon(
    Icons.psychology_outlined,
  ),
  title: Text(
    memory['memory'] ?? '',
  ),
  trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(
        Icons.edit_outlined,
      ),
      onPressed: () {
        editMemory(
          memory['id'],
          memory['memory'],
        );
      },
    ),
    IconButton(
      icon: const Icon(
        Icons.delete_outline,
        color: Colors.redAccent,
      ),
      onPressed: () {
        deleteMemory(memory['id']);
      },
    ),
  ],
),
);
                  },
                ),
    );
  }
}class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  Future<void> handleRegister() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/users'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully.'),
          ),
        );

        Navigator.pop(context);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration failed: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not connect to JOSORA.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    filled: true,
                    fillColor: const Color(0xFF151B29),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: const Color(0xFF151B29),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: const Color(0xFF151B29),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
  icon: Icon(
    obscurePassword
        ? Icons.visibility_outlined
        : Icons.visibility_off_outlined,
  ),
  onPressed: () {
    setState(() {
      obscurePassword = !obscurePassword;
    });
  },
),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleRegister,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 16),
                          ),
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
class ChangePasswordScreen extends StatefulWidget {
  final String token;

  const ChangePasswordScreen({
    super.key,
    required this.token,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  bool obscureCurrentPassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  Future<void> changePassword() async {
    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.patch(
        Uri.parse('http://localhost:3000/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully.'),
          ),
        );

        Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error'] ?? 'Could not change password.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not connect to JOSORA.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrentPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureCurrentPassword =
                            !obscureCurrentPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: newPasswordController,
                obscureText: obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNewPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureNewPassword =
                            !obscureNewPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword =
                            !obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed:
                      isLoading ? null : changePassword,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Change Password',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanionScreen extends StatefulWidget {
  final String token;

  const CompanionScreen({
    super.key,
    required this.token,
  });

  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}
class _CompanionScreenState extends State<CompanionScreen> {
  bool companionEnabled = false;
  String companionPersonality = 'best_friend';
  String companionName = 'JOSORA';
  bool companionLocked = false;
  Future<void> loadCompanion() async {
  try {
    final response = await http.get(
      Uri.parse('http://localhost:3000/companion'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    print('COMPANION LOAD STATUS: ${response.statusCode}');
    print('COMPANION LOAD RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  final companion = data['companion'];

  setState(() {
    companionEnabled = companion['enabled'] == 1;
    companionPersonality = companion['personality'];
    companionName = companion['companion_name'];
    companionLocked = false;
  });
} else if (response.statusCode == 403) {
  setState(() {
    companionLocked = true;
    companionEnabled = false;
  });
}
  } catch (e) {
    print('COMPANION LOAD ERROR: $e');
  }
}

  @override
void initState() {
  super.initState();
  loadCompanion();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JOSORA Companion'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Your Personal AI Best Friend',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Make JOSORA more personal by giving it a companion personality that understands you.',
          ),

          const SizedBox(height: 25),

          if (companionLocked) ...[
  const SizedBox(height: 40),

  const Icon(
    Icons.lock_outline,
    size: 70,
  ),

  const SizedBox(height: 20),

  const Text(
    'JOSORA Companion is a Pro feature',
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 12),

  const Text(
    'Upgrade to JOSORA Pro to unlock your personal AI best friend, companion personality, and personalized relationship features.',
    textAlign: TextAlign.center,
  ),

  const SizedBox(height: 25),

  ElevatedButton(
    onPressed: () {
      // Pro upgrade screen will be connected here later.
    },
    child: const Text('Upgrade to JOSORA Pro'),
  ),
] else ...[
  SwitchListTile(
    title: const Text('Enable Companion'),
    subtitle: const Text(
      'Let JOSORA use your companion personality during conversations.',
    ),
    value: companionEnabled,
    onChanged: (value) async {
      setState(() {
        companionEnabled = value;
      });

      try {
        final response = await http.put(
          Uri.parse('http://localhost:3000/companion'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'enabled': value,
          }),
        );

        print('COMPANION UPDATE STATUS: ${response.statusCode}');
        print('COMPANION UPDATE RESPONSE: ${response.body}');

        if (response.statusCode == 403) {
          setState(() {
            companionEnabled = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'JOSORA Companion is a Pro feature. Upgrade to JOSORA Pro to unlock it.',
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          companionEnabled = false;
        });

        print('COMPANION UPDATE ERROR: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update Companion. Please try again.',
            ),
          ),
        );
      }
    },
  ),

  const Divider(),

  ListTile(
  title: const Text('Companion Name'),
  subtitle: Text(companionName),
  trailing: const Icon(Icons.edit_outlined),
  onTap: () async {
    final controller = TextEditingController(
      text: companionName,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Companion Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Companion name',
              hintText: 'Enter a name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(dialogContext, name);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName != null && newName.isNotEmpty) {
  try {
    final response = await http.put(
      Uri.parse('http://localhost:3000/companion'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'companion_name': newName,
      }),
    );

    print('COMPANION NAME STATUS: ${response.statusCode}');
    print('COMPANION NAME RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        companionName = newName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Companion name saved.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save Companion name.'),
        ),
      );
    }
  } catch (e) {
    print('COMPANION NAME ERROR: $e');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not save Companion name.'),
      ),
    );
  }
}
  },
),

  const Divider(),

  ListTile(
  title: const Text('Personality'),
  subtitle: Text(
    companionPersonality
        .split('_')
        .map(
          (word) => word[0].toUpperCase() + word.substring(1),
        )
        .join(' '),
  ),
  trailing: const Icon(Icons.chevron_right),
  onTap: () async {
    final selectedPersonality = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Choose Personality'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext, 'best_friend');
              },
              child: const Text('🫂 Best Friend'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext, 'hype_friend');
              },
              child: const Text('🚀 Hype Friend'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext, 'mentor');
              },
              child: const Text('🧠 Mentor'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext, 'brutally_honest');
              },
              child: const Text('🗣️ Brutally Honest'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext, 'listener');
              },
              child: const Text('💙 Listener'),
            ),
          ],
        );
      },
    );

    if (selectedPersonality != null) {
      try {
        final response = await http.put(
          Uri.parse('http://localhost:3000/companion'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'personality': selectedPersonality,
          }),
        );

        print('COMPANION PERSONALITY STATUS: ${response.statusCode}');
        print('COMPANION PERSONALITY RESPONSE: ${response.body}');

        if (response.statusCode == 200) {
          setState(() {
            companionPersonality = selectedPersonality;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Personality saved.'),
            ),
          );
        } else if (response.statusCode == 403) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'JOSORA Companion is a Pro feature.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not save Personality.',
              ),
            ),
          );
        }
      } catch (e) {
        print('COMPANION PERSONALITY ERROR: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save Personality.',
            ),
          ),
        );
      }
    }
  },
),
],
        ],
      ),
    );
  }
}
class ProScreen extends StatefulWidget {
  final String token;

  const ProScreen({
    super.key,
    required this.token,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  bool isLoading = true;
  bool isPro = false;
  String status = 'free';
  String? plan;
  String? currency;
  String? startedAt;
  String? endsAt;

  @override
  void initState() {
    super.initState();
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/subscription'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

print('SUBSCRIPTION RESPONSE: ${response.body}');
print('SUBSCRIPTION IS PRO: ${data['isPro']}');

if (!mounted) return;

        setState(() {
          isPro = data['isPro'] == true;
          status = data['status'] ?? 'free';
          plan = data['plan'];
          currency = data['currency'];
          startedAt = data['startedAt'];
          endsAt = data['endsAt'];
          isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        title: const Text('JOSORA Pro'),
        backgroundColor: const Color(0xFF0B0F19),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  Center(
                    child: Icon(
                      Icons.workspace_premium,
                      size: 70,
                      color: Colors.amber,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      isPro
                          ? 'JOSORA Pro Active'
                          : 'Upgrade to JOSORA Pro',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      isPro
                          ? 'You have access to JOSORA Pro features.'
                          : 'Unlock the full JOSORA experience.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151B29),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'JOSORA Pro',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          '₦5,000 / month',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          '\$8 / month',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 20),

                        _proFeature(
                          Icons.smart_toy_outlined,
                          'JOSORA Companion',
                        ),

                        _proFeature(
                          Icons.memory_outlined,
                          'Larger and stronger memory',
                        ),

                        _proFeature(
                          Icons.image_outlined,
                          'Advanced image generation',
                        ),

                        _proFeature(
                          Icons.graphic_eq_outlined,
                          'AI voice features',
                        ),

                        _proFeature(
                          Icons.description_outlined,
                          'Advanced document analysis',
                        ),

                        _proFeature(
                          Icons.speed_outlined,
                          'Priority and faster AI',
                        ),

                        _proFeature(
                          Icons.language_outlined,
                          'Advanced web research',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  if (isPro)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151B29),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Subscription',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('Status: $status'),
                          if (plan != null) Text('Plan: $plan'),
                          if (currency != null)
                            Text('Currency: $currency'),
                          if (startedAt != null)
                            Text('Started: $startedAt'),
                          if (endsAt != null)
                            Text('Ends: $endsAt'),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading
? null
: () {
showDialog(
context: context,
builder: (dialogContext) {
return AlertDialog(
backgroundColor: const Color(0xFF151B29),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(20),
),
title: const Row(
children: [
Icon(
Icons.workspace_premium,
color: Colors.amber,
),
SizedBox(width: 10),
Expanded(
child: Text(
'JOSORA Pro',
style: TextStyle(color: Colors.white),
),
),
],
),
content: const Text(
'JOSORA Pro subscriptions are coming soon! '
'We are preparing premium features for launch. '
'You will be able to upgrade your account when '
'subscriptions become available.',
style: TextStyle(
color: Colors.white70,
height: 1.5,
),
),
actions: [
TextButton(
onPressed: () {
Navigator.of(dialogContext).pop();
},
child: const Text(
'Got it',
style: TextStyle(color: Colors.amber),
),
),
],
);
},
);
},
                        child: const Text(
                          'Upgrade to JOSORA Pro',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  if (!isPro)
                    const Center(
                      child: Text(
                        'Secure payments will be available when JOSORA subscriptions launch.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _proFeature(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: Colors.amber,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ================= JOSORA THERAPY BUDDY =================

class TherapyBuddyScreen extends StatefulWidget {
  final String token;

  const TherapyBuddyScreen({
    super.key,
    required this.token,
  });

  @override
  State<TherapyBuddyScreen> createState() =>
      _TherapyBuddyScreenState();
}

class _TherapyBuddyScreenState extends State<TherapyBuddyScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];

  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();

    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': message,
      });
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/therapy-buddy/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        _messages.add({
          'sender': 'josora',
          'text': response.statusCode == 200
              ? (data['reply'] ?? 'I am here to listen.')
              : (data['message'] ??
                  'I could not respond right now. Please try again.'),
        });
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _messages.add({
          'sender': 'josora',
          'text':
              'I am here for you. I could not connect just now. Please try again.',
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10111B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191B2B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF7C5CFC),
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Therapy Buddy',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your space to talk',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF191B2B),
            child: const Text(
              'You can talk about what is on your mind without fear of being judged. I can offer support, but I am an AI companion, not a professional therapist.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 58,
                            color: Color(0xFF9A83FF),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            "It's okay not to be okay.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "What's on your mind today?",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final item = _messages[index];
                      final isUser = item['sender'] == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.82,
                          ),
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFF7055E8)
                                : const Color(0xFF242638),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            item['text'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Therapy Buddy is listening...',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              color: const Color(0xFF191B2B),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Tell me how you feel...',
                        hintStyle:
                            const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF292B3D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFF7C5CFC),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
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

class ProCompanionVoiceScreen extends StatefulWidget {
  final String token;

  const ProCompanionVoiceScreen({
    super.key,
    required this.token,
  });

  @override
  State<ProCompanionVoiceScreen> createState() =>
      _ProCompanionVoiceScreenState();
}

class _ProCompanionVoiceScreenState
    extends State<ProCompanionVoiceScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _controller = TextEditingController();

  late final AnimationController _animationController;

  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;
  bool _isFemale = true;

  String _status = 'Your companion is ready';
  String _reply = 'Hey! I’m here for you. What would you like to talk about?';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.94,
      upperBound: 1.06,
    )..repeat(reverse: true);

    _setupVoice();
  }
  String _cleanTextForSpeech(String text) {
  final buffer = StringBuffer();

  for (final rune in text.runes) {
    final isEmoji =
        (rune >= 0x1F000 && rune <= 0x1FAFF) ||
        (rune >= 0x2600 && rune <= 0x27BF) ||
        (rune >= 0xFE00 && rune <= 0xFE0F) ||
        (rune >= 0x1F1E6 && rune <= 0x1F1FF) ||
        rune == 0x200D ||
        rune == 0x20E3;

    if (!isEmoji) {
      buffer.writeCharCode(rune);
    }
  }

  return buffer
      .toString()
      .replaceAll(RegExp(r'[*_#`~]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

  Future<void> _setupVoice() async {
    try {
      await _tts.setLanguage('en-US');
      debugPrint('SETUP VOICE IS RUNNING');
      final voices = await _tts.getVoices;
      debugPrint('JOSORA AVAILABLE VOICES: $voices');
      
if (mounted) {
setState(() {
_status = 'Available voices: ${voices.map((v) => "${v['name']} (${v['locale']})").join(', ')}';
});
}
debugPrint('AVAILABLE JOSORA VOICES: $voices');
debugPrint('AVAILABLE JOSORA VOICES: $voices');
      await _tts.setSpeechRate(1.5);
await _tts.setPitch(1.1);

      _tts.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
            _status = 'Your companion is speaking';
          });
        }
      });

      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _status = 'Your companion is ready';
          });
        }
      });

      _tts.setCancelHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
    } catch (e) {
      debugPrint('VOICE SETUP ERROR: $e');
    }
  }
  Future<void> _setCompanionVoice() async {
try {
final voices = await _tts.getVoices;

final targetName = _isFemale ? 'Zira' : 'David';

final matchingVoices = voices.where((voice) {
  final name = (voice['name'] ?? '').toString();
  final locale = (voice['locale'] ?? '').toString();

  return name.toLowerCase().contains(targetName.toLowerCase()) &&
      locale.toLowerCase().startsWith('en');
}).toList();

if (matchingVoices.isEmpty) {
  if (mounted) {
    setState(() {
      _status = 'Voice $targetName not found in this browser';
    });
  }
  debugPrint('VOICE NOT FOUND: $targetName. Available: $voices');
  return;
}

final voice = matchingVoices.first;



await _tts.setLanguage(voice['locale']!);
await _tts.setVoice({
  'name': voice['name']!,
  'locale': voice['locale']!,
});
await _tts.setPitch(_isFemale ? 1.1 : 0.9);

if (mounted) {
  setState(() {
    _status = 'Selected voice: ${voice['name']} (${voice['locale']})';
  });
}

debugPrint('SELECTED COMPANION VOICE: $voice');

} catch (e) {
debugPrint('VOICE SELECTION ERROR: $e');
}
}
  Future<void> _startListening() async {
    if (_isThinking || _isSpeaking) return;

    try {
      final permission = await Permission.microphone.request();

      if (!permission.isGranted) {
        setState(() {
          _status = 'Please allow microphone access in your browser.';
        });
        return;
      }

      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('SPEECH STATUS: $status');
        },
        onError: (error) {
          debugPrint('SPEECH ERROR: ${error.errorMsg}');

          if (mounted) {
            setState(() {
              _isListening = false;
              _status = 'Could not hear you. Please try again.';
            });
          }
        },
      );

      if (!available) {
        setState(() {
          _status = 'Voice recognition is unavailable on this device.';
        });
        return;
      }

      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _controller.text = result.recognizedWords;
              _controller.selection = TextSelection.collapsed(
                offset: _controller.text.length,
              );
            });
          }

          if (result.finalResult &&
    result.recognizedWords.trim().isNotEmpty) {
  _sendMessage();
}
        },
      );

      if (mounted) {
        setState(() {
          _isListening = true;
          _status = 'I’m listening...';
        });
      }
    } catch (e) {
      debugPrint('MICROPHONE ERROR: $e');

      if (mounted) {
        setState(() {
          _isListening = false;
          _status = 'Microphone unavailable. Please try again.';
        });
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    if (mounted) {
      setState(() {
        _isListening = false;
        _status = 'Your companion is ready';
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();

    if (message.isEmpty || _isThinking) return;

    await _stopListening();

    setState(() {
      _isThinking = true;
      _status = 'Your companion is thinking...';
      _controller.clear();
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/chat'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['reply'] != null) {
        final reply = data['reply'].toString();

        if (!mounted) return;

        setState(() {
          _reply = reply;
          _status = 'Your companion is ready';
        });

        await _tts.speak(_cleanTextForSpeech(reply));
      } else {
        throw Exception('Chat request failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PRO COMPANION CHAT ERROR: $e');

      if (mounted) {
        setState(() {
          _reply = 'I couldn’t connect just now. Please try again.';
          _status = 'Connection issue';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isThinking = false;
        });
      }
    }
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();

    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _status = 'Your companion is ready';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speech.stop();
    _tts.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('JOSORA Pro Companion'),
        actions: [
          IconButton(
            tooltip: 'Stop speaking',
            icon: const Icon(Icons.volume_off_rounded),
            onPressed: _stopSpeaking,
          ),
        ],
      ),
      body: SafeArea(
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 600),
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const SizedBox(height: 20),
const Text(
'Your Personal AI Best Friend',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 23,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 24),
AnimatedBuilder(
animation: _animationController,
builder: (context, child) {
return Transform.scale(
scale: (_isListening || _isSpeaking)
? _animationController.value
: 1.0,
child: child,
);
},
child: ChibiCompanion(
isFemale: _isFemale,
mood: _isListening
? 'listening'
: _isThinking
? 'thinking'
: _isSpeaking
? 'speaking'
: 'neutral',
),
),
const SizedBox(height: 16),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
ChoiceChip(
label: const Text('JOSORA ♀'),
selected: _isFemale,
onSelected: (selected) async {
  if (selected) {
    setState(() {
      _isFemale = true;
    });
    await _setCompanionVoice();
  }
},
),
const SizedBox(width: 12),
ChoiceChip(
label: const Text('JOSORO ♂'),
selected: !_isFemale,
onSelected: (selected) async {
  if (selected) {
    setState(() {
      _isFemale = false;
    });
    await _setCompanionVoice();
  }
},
),
],
),
const SizedBox(height: 16),
Text(
_status,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 16,
color: Color(0xFF9A83FF),
),
),
const SizedBox(height: 20),
Container(
width: double.infinity,
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: Theme.of(context)
.colorScheme
.surfaceContainerHighest,
borderRadius: BorderRadius.circular(20),
),
child: Text(
_reply,
style: const TextStyle(
fontSize: 16,
height: 1.6,
),
),
),
const SizedBox(height: 18),
TextField(
controller: _controller,
minLines: 1,
maxLines: 4,
onSubmitted: (value) => _sendMessage(),
decoration: InputDecoration(
hintText: 'Talk or type to your companion...',
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
),
prefixIcon: const Icon(Icons.chat_bubble_outline),
suffixIcon: IconButton(
tooltip: 'Send message',
icon: const Icon(Icons.send_rounded),
onPressed: _isThinking ? null : _sendMessage,
),
),
),
const SizedBox(height: 16),
SizedBox(
width: double.infinity,
height: 54,
child: ElevatedButton.icon(
onPressed: _isThinking
? null
: _isListening
? _stopListening
: _startListening,
icon: Icon(
_isListening
? Icons.stop_rounded
: Icons.mic_rounded,
),
label: Text(
_isListening
? 'Stop Listening'
: 'Talk to Companion',
),
),
),
const SizedBox(height: 12),
],
),
),
),
),
),
    );
  }
}
// =============================================
// JOSORA AI — FULL BODY CHIBI COMPANION
// =============================================

class ChibiCompanion extends StatelessWidget {
  final bool isFemale;
  final String mood;

  const ChibiCompanion({
    super.key,
    this.isFemale = true,
    this.mood = 'neutral',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 270,
      child: CustomPaint(
        painter: _ChibiCompanionPainter(
          isFemale: isFemale,
          mood: mood,
        ),
      ),
    );
  }
}

class _ChibiCompanionPainter extends CustomPainter {
  final bool isFemale;
  final String mood;

  _ChibiCompanionPainter({
    required this.isFemale,
    required this.mood,
  });

  final Color purple = const Color(0xFF9A83FF);
  final Color darkPurple = const Color(0xFF38266F);
  final Color skin = const Color(0xFFE8B99B);
  final Color hair = const Color(0xFF201B35);
  final Color eyeColor = const Color(0xFF49366D);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 190;
    final sy = size.height / 270;

    canvas.save();
    canvas.scale(sx, sy);

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(95, 258),
        width: 90,
        height: 12,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // Legs.
    final legPaint = Paint()..color = darkPurple;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(72, 192, 20, 43),
        const Radius.circular(9),
      ),
      legPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(99, 192, 20, 43),
        const Radius.circular(9),
      ),
      legPaint,
    );

    // Shoes.
    final shoePaint = Paint()..color = const Color(0xFF191626);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(61, 231, 36, 16),
        const Radius.circular(8),
      ),
      shoePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(96, 231, 36, 16),
        const Radius.circular(8),
      ),
      shoePaint,
    );

    // Arms.
    final armPaint = Paint()
      ..color = skin
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      const Offset(66, 133),
      const Offset(45, 171),
      armPaint,
    );

    canvas.drawLine(
      const Offset(124, 133),
      const Offset(145, 171),
      armPaint,
    );

    // Jacket / upper body.
    final bodyPath = Path()
      ..moveTo(72, 112)
      ..quadraticBezierTo(95, 103, 118, 112)
      ..lineTo(132, 183)
      ..quadraticBezierTo(95, 197, 58, 183)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()..color = darkPurple,
    );

    // Jacket panels.
    final panelPaint = Paint()
      ..color = purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawLine(
      const Offset(95, 119),
      const Offset(95, 183),
      panelPaint,
    );

    // Shirt.
    final shirtPath = Path()
      ..moveTo(83, 114)
      ..lineTo(95, 130)
      ..lineTo(107, 114)
      ..lineTo(104, 164)
      ..lineTo(86, 164)
      ..close();

    canvas.drawPath(
      shirtPath,
      Paint()..color = const Color(0xFFDDD6FF),
    );

    // Neck.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(84, 93, 22, 28),
        const Radius.circular(8),
      ),
      Paint()..color = skin,
    );

    // Long hair behind the head for JOSORA.
    if (isFemale) {
      final longHair = Path()
        ..moveTo(56, 43)
        ..quadraticBezierTo(43, 60, 49, 100)
        ..lineTo(58, 129)
        ..quadraticBezierTo(65, 139, 70, 122)
        ..lineTo(74, 73)
        ..close();

      canvas.drawPath(
        longHair,
        Paint()..color = hair,
      );

      final rightHair = Path()
        ..moveTo(133, 43)
        ..quadraticBezierTo(147, 64, 141, 100)
        ..lineTo(132, 127)
        ..quadraticBezierTo(125, 136, 120, 119)
        ..lineTo(118, 72)
        ..close();

      canvas.drawPath(
        rightHair,
        Paint()..color = hair,
      );
    }

    // Ears.
    canvas.drawCircle(
      const Offset(56, 68),
      10,
      Paint()..color = skin,
    );

    canvas.drawCircle(
      const Offset(134, 68),
      10,
      Paint()..color = skin,
    );

    // Head.
    canvas.drawOval(
      const Rect.fromLTWH(52, 23, 86, 91),
      Paint()..color = skin,
    );

    // Hair cap.
    final hairPath = Path()
      ..moveTo(52, 67)
      ..quadraticBezierTo(42, 29, 75, 20)
      ..quadraticBezierTo(111, 7, 136, 34)
      ..quadraticBezierTo(145, 45, 137, 69)
      ..lineTo(125, 49)
      ..quadraticBezierTo(105, 43, 94, 32)
      ..quadraticBezierTo(80, 50, 59, 54)
      ..lineTo(52, 67)
      ..close();

    canvas.drawPath(
      hairPath,
      Paint()..color = hair,
    );

    // Front fringe.
    final fringe = Path()
      ..moveTo(57, 48)
      ..quadraticBezierTo(72, 29, 91, 34)
      ..quadraticBezierTo(109, 46, 130, 44)
      ..quadraticBezierTo(119, 60, 99, 53)
      ..quadraticBezierTo(83, 49, 70, 61)
      ..lineTo(57, 66)
      ..close();

    canvas.drawPath(
      fringe,
      Paint()..color = hair,
    );

    // Purple hair highlight.
    final highlight = Paint()
      ..color = purple.withValues(alpha: 0.85)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      const Offset(76, 27),
      const Offset(91, 25),
      highlight,
    );

    // Eyebrows.
    final browPaint = Paint()
      ..color = hair
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      const Offset(69, 62),
      Offset(83, mood == 'concerned' ? 59 : 60),
      browPaint,
    );

    canvas.drawLine(
      Offset(106, mood == 'concerned' ? 59 : 60),
      const Offset(120, 62),
      browPaint,
    );

    // Eyes change according to mood.
    if (mood == 'happy') {
      final eyePaint = Paint()
        ..color = eyeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        const Rect.fromLTWH(68, 65, 17, 12),
        3.5,
        2.3,
        false,
        eyePaint,
      );

      canvas.drawArc(
        const Rect.fromLTWH(104, 65, 17, 12),
        3.5,
        2.3,
        false,
        eyePaint,
      );
    } else if (mood == 'concerned') {
      final eyePaint = Paint()..color = eyeColor;

      canvas.drawOval(
        const Rect.fromLTWH(70, 65, 12, 17),
        eyePaint,
      );

      canvas.drawOval(
        const Rect.fromLTWH(106, 65, 12, 17),
        eyePaint,
      );
    } else if (mood == 'thinking') {
      final eyePaint = Paint()..color = eyeColor;

      canvas.drawOval(
        const Rect.fromLTWH(70, 66, 12, 15),
        eyePaint,
      );

      canvas.drawOval(
        const Rect.fromLTWH(107, 66, 12, 15),
        eyePaint,
      );

      canvas.drawCircle(
        const Offset(78, 72),
        3,
        Paint()..color = Colors.white,
      );

      canvas.drawCircle(
        const Offset(111, 72),
        3,
        Paint()..color = Colors.white,
      );
    } else {
      final eyePaint = Paint()..color = eyeColor;

      canvas.drawOval(
        Rect.fromLTWH(
          70,
          65,
          13,
          mood == 'listening' ? 18 : 16,
        ),
        eyePaint,
      );

      canvas.drawOval(
        Rect.fromLTWH(
          106,
          65,
          13,
          mood == 'listening' ? 18 : 16,
        ),
        eyePaint,
      );

      // Eye highlights.
      canvas.drawCircle(
        const Offset(77, 70),
        3,
        Paint()..color = Colors.white,
      );

      canvas.drawCircle(
        const Offset(113, 70),
        3,
        Paint()..color = Colors.white,
      );
    }

    // Blush.
    if (isFemale || mood == 'happy') {
      final blushPaint = Paint()
        ..color = const Color(0xFFE88C9C).withValues(alpha: 0.45);

      canvas.drawOval(
        const Rect.fromLTWH(59, 80, 16, 7),
        blushPaint,
      );

      canvas.drawOval(
        const Rect.fromLTWH(115, 80, 16, 7),
        blushPaint,
      );
    }

    // Mouth.
    final mouthPaint = Paint()
      ..color = const Color(0xFF7D3F4C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    if (mood == 'happy') {
      canvas.drawArc(
        const Rect.fromLTWH(80, 79, 30, 21),
        0.2,
        2.7,
        false,
        mouthPaint,
      );
    } else if (mood == 'concerned') {
      canvas.drawArc(
        const Rect.fromLTWH(83, 88, 24, 12),
        3.5,
        2.4,
        false,
        mouthPaint,
      );
    } else if (mood == 'speaking') {
      canvas.drawOval(
        const Rect.fromLTWH(87, 84, 15, 12),
        Paint()..color = const Color(0xFF7D3F4C),
      );
    } else if (mood == 'thinking') {
      canvas.drawLine(
        const Offset(88, 91),
        const Offset(102, 89),
        mouthPaint,
      );
    } else {
      canvas.drawLine(
        const Offset(86, 89),
        const Offset(104, 89),
        mouthPaint,
      );
    }

    // Outfit badge.
    canvas.drawCircle(
      const Offset(95, 145),
      9,
      Paint()..color = purple,
    );

    canvas.drawCircle(
      const Offset(95, 145),
      4,
      Paint()..color = Colors.white,
    );

    // Gender-specific hair accessory.
    if (isFemale) {
      canvas.drawCircle(
        const Offset(130, 37),
        7,
        Paint()..color = purple,
      );

      canvas.drawCircle(
        const Offset(130, 37),
        3,
        Paint()..color = Colors.white,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChibiCompanionPainter oldDelegate) {
    return oldDelegate.isFemale != isFemale ||
        oldDelegate.mood != mood;
  }
}

class PluginsScreen extends StatelessWidget {
  const PluginsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: const Text(
          'JOSORA Plugins',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Extend what JOSORA can do.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore tools and features for your personal AI.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          _buildPluginCard(
  icon: Icons.search_rounded,
  title: 'Web Research',
  description: 'Search the web using Google.',
  status: 'Open Google Search',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GoogleSearchScreen(),
      ),
    );
  },
),
          _buildPluginCard(
            icon: Icons.description_outlined,
            title: 'Document Tools',
            description: 'Work with documents and extract key information.',
            status: 'Coming soon',
          ),
          _buildPluginCard(
            icon: Icons.image_outlined,
            title: 'Image Studio',
            description: 'Explore image creation and editing tools.',
            status: 'Planned',
          ),
        ],
      ),
    );
  }

  Widget _buildPluginCard({
  required IconData icon,
  required String title,
  required String description,
  required String status,
  VoidCallback? onTap,
}) {
    return Card(
      color: const Color(0xFF191B2B),
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
  onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          icon,
          color: const Color(0xFF9A83FF),
          size: 30,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                status,
                style: const TextStyle(
                  color: Color(0xFF9A83FF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class GoogleSearchScreen extends StatefulWidget {
  const GoogleSearchScreen({super.key});

  @override
  State<GoogleSearchScreen> createState() => _GoogleSearchScreenState();
}

class _GoogleSearchScreenState extends State<GoogleSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isOpening = false;

  Future<void> _searchGoogle() async {
  final query = _searchController.text.trim();

  if (query.isEmpty || _isOpening) return;

  final uri = Uri(
    path: 'josora_search.html',
    queryParameters: {'q': query},
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B0F19),
          title: const Text('JOSORA Web Research'),
        ),
        body: WebSearchView(
          url: uri.toString(),
        ),
      ),
    ),
  );
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: const Text(
          'JOSORA Web Research',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            color: Color(0xFF9A83FF),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'What do you want to discover?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Search for news, technology, tutorials, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _searchGoogle(),
            decoration: InputDecoration(
              hintText: 'Search the web...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF9A83FF),
              ),
              filled: true,
              fillColor: const Color(0xFF191B2B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isOpening ? null : _searchGoogle,
            icon: const Icon(Icons.search),
            label: Text(_isOpening ? 'Opening...' : 'Search with Google'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9A83FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}