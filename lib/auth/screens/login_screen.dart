import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/game_button.dart';
import '../../shared/widgets/animated_game_background.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const LoginScreen({super.key, this.onBackPressed});

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
        color: Colors.black,
        fontWeight: FontWeight.w800,
        fontSize: 11.0,
        letterSpacing: 1.0,
      ),
      prefixIcon: Icon(icon, color: Colors.black, size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFD0D0D0), width: 2.0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF00C853), width: 2.5), // Focus green
        borderRadius: BorderRadius.circular(12.0),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 2.0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 2.5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      errorStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFFFF5252),
        fontSize: 11.0,
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 14.0,
      ),
      decoration: _buildInputDecoration(
        labelText: 'Mobile Number',
        icon: Icons.phone,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your mobile number';
        }
        final phoneRegExp = RegExp(r'^\d{10}$');
        if (!phoneRegExp.hasMatch(value.trim())) {
          return 'Please enter a valid 10-digit number';
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
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 14.0,
      ),
      decoration: _buildInputDecoration(
        labelText: 'Password',
        icon: Icons.lock,
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.black,
            size: 18,
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
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFEBEBEB);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Outer layout configurations
    final double cardPadding = isLandscape ? 20.0 : 28.0;
    final double maxWidth = isLandscape ? 580.0 : 380.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedGameBackground(
        showStars: false,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                  ),
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: const Color(0xFFD0D0D0), width: 3.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        offset: const Offset(0, 8),
                        blurRadius: 16.0,
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: isLandscape 
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Center(
                              child: Text(
                                'LOG IN',
                                style: GoogleFonts.alfaSlabOne(
                                  textStyle: const TextStyle(
                                    fontSize: 26.0,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),

                            // Fields Row (Side by side)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildPhoneField()),
                                const SizedBox(width: 14.0),
                                Expanded(child: _buildPasswordField()),
                              ],
                            ),
                            const SizedBox(height: 20.0),

                            // Buttons Row (Side by side)
                            Row(
                              children: [
                                Expanded(
                                  child: GameButton(
                                    text: 'LOGIN',
                                    backgroundColor: const Color(0xFF00C853), // Green
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: const Color(0xFF00C853),
                                            content: Text(
                                              'Logging in: ${_phoneController.text}...',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14.0),
                                Expanded(
                                  child: GameButton(
                                    text: 'BACK',
                                    backgroundColor: const Color(0xFFFF5252), // Coral/Red
                                    onPressed: () {
                                      if (widget.onBackPressed != null) {
                                        widget.onBackPressed!();
                                      } else {
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Center(
                              child: Text(
                                'LOG IN',
                                style: GoogleFonts.alfaSlabOne(
                                  textStyle: const TextStyle(
                                    fontSize: 32.0,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24.0),

                            _buildPhoneField(),
                            const SizedBox(height: 16.0),

                            _buildPasswordField(),
                            const SizedBox(height: 24.0),

                            // Submit Button
                            GameButton(
                              text: 'LOGIN',
                              backgroundColor: const Color(0xFF00C853), // Green
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF00C853),
                                      content: Text(
                                        'Logging in: ${_phoneController.text}...',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 12.0),

                            // Back Button
                            GameButton(
                              text: 'BACK',
                              backgroundColor: const Color(0xFFFF5252), // Coral/Red
                              onPressed: () {
                                if (widget.onBackPressed != null) {
                                  widget.onBackPressed!();
                                } else {
                                  Navigator.pop(context);
                                }
                              },
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
    );
  }
}
