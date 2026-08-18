import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/bounceable.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.onBackPressed,
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText.toUpperCase(),
      labelStyle: const TextStyle(
        color: Colors.white60,
        fontWeight: FontWeight.w800,
        fontSize: 10.5,
        letterSpacing: 0.5,
      ),
      prefixIcon: Icon(icon, color: Colors.white70, size: 16),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0x60000000), // Semi-translucent input background
      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24, width: 1.2),
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF24EE89), width: 1.5), // Neon green active border
        borderRadius: BorderRadius.circular(10.0),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFFF3356), width: 1.2),
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFFF3356), width: 1.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      errorStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFFFF3356),
        fontSize: 10.0,
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 13.0,
      ),
      decoration: _buildInputDecoration(
        labelText: 'Mobile Number',
        icon: Icons.phone,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        final phoneRegExp = RegExp(r'^\d{10}$');
        if (!phoneRegExp.hasMatch(value.trim())) {
          return 'Enter a 10-digit number';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 13.0,
      ),
      decoration: _buildInputDecoration(
        labelText: 'Password',
        icon: Icons.lock,
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.white54,
            size: 16,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        if (value.length < 6) {
          return 'Must be at least 6 characters';
        }
        return null;
      },
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00C853),
          content: Text(
            'Logged in Successfully!',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Beautiful startlogo background image spanning full screen
          Positioned.fill(
            child: Image.asset(
              'assets/startlogo.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark tint overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),
          
          // 2. Glassmorphic login card centered
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: isLandscape ? 440.0 : 330.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x301E2024), // Highly transparent dark slate
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Glowing header
                              Center(
                                child: Text(
                                  'LOGIN',
                                  style: GoogleFonts.pressStart2p(
                                    textStyle: const TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFF24EE89),
                                          blurRadius: 10.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24.0),
                              
                              _buildPhoneField(),
                              const SizedBox(height: 14.0),
                              _buildPasswordField(),
                              const SizedBox(height: 24.0),
                              
                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: Bounceable(
                                      onTap: _handleLogin,
                                      child: Container(
                                        height: 40.0,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF24EE89), Color(0xFF00C853)],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius: BorderRadius.circular(10.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF24EE89).withOpacity(0.3),
                                              blurRadius: 8.0,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'LOGIN',
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Bounceable(
                                      onTap: () {
                                        if (widget.onBackPressed != null) {
                                          widget.onBackPressed!();
                                        } else {
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: Container(
                                        height: 40.0,
                                        decoration: BoxDecoration(
                                          color: const Color(0x30FFFFFF),
                                          borderRadius: BorderRadius.circular(10.0),
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 1.0,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'BACK',
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
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
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
