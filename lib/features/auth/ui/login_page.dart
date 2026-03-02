import 'package:cu_plus_webapp/features/auth/ui/first_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../api/auth_api.dart';
import '../../dashboard/course_content_page.dart';
import './first_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _rememberMe = false;

  bool _loading = false;
  String? _error;
  String? _tokenPreview;

  late final AuthApi _authApi;

  @override
  void initState() {
    super.initState();
    _authApi = AuthApi(ApiClient());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    setState(() {
      _error = null;
      _tokenPreview = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final res = await _authApi.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final user = res["user"] as Map<String, dynamic>?;
      final email = (user?["email"] ?? _emailCtrl.text.trim()).toString();

      if (!mounted) return;

      // popup
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Login successful!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      // navigate
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (_) => CourseContentPage(email: email),
        ),
      );

      final token = (res["token"] ?? "").toString();
      setState(() {
        _tokenPreview = token.isEmpty
            ? "(no token returned)"
            : "${token.substring(0, token.length > 25 ? 25 : token.length)}...";
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: topBar(),
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          final content = phoneVersion(context); // phone ui

          if (!isDesktop) return content;

          // other wise, wrap the phone ui in a box for pc version
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: Offset(0, 8),
                      color: Color(0x14000000),
                    ),
                  ],
                ),
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar topBar() {
    return AppBar(
      title: const Text(
        "Plus Scholar Cameron",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20.0),
        child: Image.asset('assets/images/cameron_logo2.png'),
      ),
    );
  }

  Padding phoneVersion(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                  
                    // Top Input fields
                    children: [
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "School Email",
                                style: TextStyle(fontSize: 16, color: Color(0xFF111928)),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  final s = (v ?? "").trim();
                                  if (s.isEmpty) return "Email is required";
                                  if (!s.contains("@")) return "Enter a valid email";
                                  return null;
                                },
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: "name@cameron.edu",
                                  hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                  
                                  filled: true,
                                  fillColor: Color(0xFFF9FAFB),
                  
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                  ),
                  
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                  ),
                  
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                  ),
                  
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.red),
                                  ),
                  
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  
                          const SizedBox(height: 34),
                  
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Password",
                                style: TextStyle(fontSize: 16, color: Color(0xFF111928)),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (!_loading) {
                                    _onLogin();
                                  }
                                },
                                validator: (v) {
                                  if ((v ?? "").isEmpty) return "Password is required";
                                  if ((v ?? "").length < 6) return "Min 6 characters";
                                  return null;
                                },
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: "••••••••••",
                                  hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                  
                                  filled: true,
                                  fillColor: Color(0xFFF9FAFB),
                  
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                  ),
                  
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                  ),
                  
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                  ),
                  
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.red),
                                  ),
                  
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  
                          if (_error != null) ...[
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                          ],
                  
                          const SizedBox(height: 20),
                  
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "Remember me",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                      color: Color(0xFF787878),
                                    ),
                                  ),
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    activeColor: Color(0xFFD9D9D9),
                                    fillColor: WidgetStateProperty.resolveWith<Color>((
                                      states,
                                    ) {
                                      return const Color(0xFFD9D9D9); // same color always
                                    }),
                                    side: const BorderSide(
                                      color: Color(0xFFD9D9D9),
                                      width: 2,
                                    ),
                                    checkColor: Colors.blueGrey,
                                  ),
                                ],
                              ),
                  
                              const Text(
                                "Forgot password?",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xFF787878),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                  
                      // Bottom buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style:
                                  ElevatedButton.styleFrom(
                                    backgroundColor: Color.fromARGB(255, 255, 255, 255),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    elevation: 1, // shadow
                                    padding: const EdgeInsets.symmetric(vertical: 22),
                                  ).copyWith(
                                    overlayColor: WidgetStateProperty.all(
                                      Colors.transparent,
                                    ),
                                  ),
                              child: const Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                  
                          SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _onLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFFC425),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                elevation: 2, // shadow
                                padding: const EdgeInsets.symmetric(vertical: 22),
                              ),
                              child: Text(
                                _loading ? "Signing in..." : "Sign in",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
