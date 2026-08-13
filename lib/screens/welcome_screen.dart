import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/game_button.dart';
import '../widgets/animated_game_background.dart';
import '../widgets/animated_character.dart';
import '../utils/sound_helper.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'lobby_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onSignupPressed;
  final VoidCallback? onSkipPressed;

  const WelcomeScreen({
    super.key,
    this.onLoginPressed,
    this.onSignupPressed,
    this.onSkipPressed,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Start sci-fi welcome screen ambient pad loop
    startWelcomeMusic();
  }

  @override
  void dispose() {
    // Fade out and stop the music when welcome screen is disposed
    stopWelcomeMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    // Background color matching the deep space theme
    const backgroundColor = Color(0xFF0B0523);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedGameBackground(
        child: SafeArea(
          child: isLandscape
              ? _buildLandscapeLayout(context)
              : _buildPortraitLayout(context),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // COREGAME Text in white
        Text(
          'COREGAME',
          style: GoogleFonts.alfaSlabOne(
            textStyle: const TextStyle(
              fontSize: 48.0,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 3,
              height: 1.0,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 4.0, offset: Offset(2.0, 2.0)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        // Neon gradient underline bar
        Container(
          width: 180,
          height: 5,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFFE040FB)],
            ),
            borderRadius: BorderRadius.circular(2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                blurRadius: 6.0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GameButton(
          text: 'LOGIN',
          backgroundColor: const Color(0xFF00C853), // Green from the image
          width: 260.0,
          height: 48.0,
          onPressed: () {
            stopWelcomeMusic();
            if (widget.onLoginPressed != null) {
              widget.onLoginPressed!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          },
        ),
        const SizedBox(height: 12.0),
        GameButton(
          text: 'SIGN UP',
          backgroundColor: const Color(0xFFFF5252), // Coral/Red from the image
          width: 260.0,
          height: 48.0,
          onPressed: () {
            stopWelcomeMusic();
            if (widget.onSignupPressed != null) {
              widget.onSignupPressed!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignupScreen()),
              );
            }
          },
        ),
        const SizedBox(height: 12.0),
        GameButton(
          text: 'SKIP',
          backgroundColor: const Color(0xFF1CB0F6), // Duolingo blue
          width: 260.0,
          height: 48.0,
          onPressed: () {
            stopWelcomeMusic();
            if (widget.onSkipPressed != null) {
              widget.onSkipPressed!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LobbyScreen(
                    onLogoutPressed: () => Navigator.pop(context),
                    balance: 17.57,
                    vipLevel: 1,
                    totalDeposited: 100.00,
                    soundOn: true,
                    musicOn: true,
                    isBankAdded: true,
                    bankHolderName: 'SUPER HIT',
                    bankPhoneNumber: '0917088800480',
                    bankName: 'KOTAK MAHINDRA BANK',
                    bankAccountNumber: '6055376770',
                    activeGateway: 'UmPay',
                    onPlayGame: (_) {},
                    onBalanceChanged: (_) {},
                    onVipLevelChanged: (_) {},
                    onTotalDepositedChanged: (_) {},
                    onSoundToggled: (_) {},
                    onMusicToggled: (_) {},
                    onActiveGatewayChanged: (_) {},
                    onBankDetailsChanged: (_, __, ___, ____, _____) {},
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      children: [
        // Left side: Title/Logo & Mascot
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AnimatedCharacter(width: 140.0, height: 140.0),
                  const SizedBox(height: 12.0),
                  _buildLogo(),
                ],
              ),
            ),
          ),
        ),
        // Right side: Buttons
        Expanded(
          flex: 3,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(right: 48.0),
                child: _buildButtons(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20.0),
              const AnimatedCharacter(width: 150.0, height: 150.0),
              const SizedBox(height: 16.0),
              _buildLogo(),
              const SizedBox(height: 48.0),
              _buildButtons(context),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
