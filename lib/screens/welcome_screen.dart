import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../widgets/game_button.dart';
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

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Video ───────────────────────────────────────────────────────────────
  late VideoPlayerController _videoCtrl;
  bool _videoReady = false;

  // ── Entry animation ─────────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    // Video setup
    _videoCtrl = VideoPlayerController.asset('assets/bg_video.mp4')
      ..setLooping(true)
      ..setVolume(0.0) // mute — pure visual
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _videoReady = true);
          _videoCtrl.play();
          _entryCtrl.forward();
        }
      });
  }

  @override
  void dispose() {
    stopWelcomeMusic();
    _videoCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060810),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen video background ───────────────────────────────
          if (_videoReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoCtrl.value.size.width,
                height: _videoCtrl.value.size.height,
                child: VideoPlayer(_videoCtrl),
              ),
            )
          else
            Container(color: const Color(0xFF060810)),

          // ── Gradient overlays (darken video so UI is readable) ─────────
          // Deep dark vignette
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          // Horizontal dark edge fade
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xBB000000), Colors.transparent, Color(0xBB000000)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          // Top + bottom dark bars
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xDD060810), Colors.transparent, Color(0xDD060810)],
                stops: [0.0, 0.4, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Main UI ────────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _buildLayout(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return isLandscape
        ? _buildLandscapeLayout(context)
        : _buildPortraitLayout(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Logo
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Glow pill behind text
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 240,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5FF).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Text(
              'COREGAME',
              style: GoogleFonts.alfaSlabOne(
                textStyle: const TextStyle(
                  fontSize: 46.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                  height: 1.0,
                  shadows: [
                    Shadow(
                        color: Color(0xFF00E5FF),
                        blurRadius: 20.0,
                        offset: Offset(0, 0)),
                    Shadow(
                        color: Colors.black,
                        blurRadius: 6.0,
                        offset: Offset(2.0, 3.0)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        // Neon gradient underline bar
        Container(
          width: 180,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFFE040FB)],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.5),
                blurRadius: 8.0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'PLAY · WIN · REPEAT',
          style: GoogleFonts.robotoMono(
            textStyle: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 9.5,
              letterSpacing: 2.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Buttons
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _glassButton(
          label: 'LOGIN',
          gradient: const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF00E57A)],
          ),
          glowColor: const Color(0xFF00C853),
          onTap: () {
            stopWelcomeMusic();
            if (widget.onLoginPressed != null) {
              widget.onLoginPressed!();
            } else {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            }
          },
        ),
        const SizedBox(height: 12.0),
        _glassButton(
          label: 'SIGN UP',
          gradient: const LinearGradient(
            colors: [Color(0xFFE040FB), Color(0xFF7B2FF7)],
          ),
          glowColor: const Color(0xFFE040FB),
          onTap: () {
            stopWelcomeMusic();
            if (widget.onSignupPressed != null) {
              widget.onSignupPressed!();
            } else {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()));
            }
          },
        ),
        const SizedBox(height: 12.0),
        _glassButton(
          label: 'SKIP →  LOBBY',
          gradient: const LinearGradient(
            colors: [Color(0xFF1A2033), Color(0xFF252A40)],
          ),
          glowColor: const Color(0xFF00D2FF),
          border: Border.all(color: const Color(0xFF00D2FF).withOpacity(0.35), width: 1.2),
          onTap: () {
            stopWelcomeMusic();
            if (widget.onSkipPressed != null) {
              widget.onSkipPressed!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LobbyScreen(
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

  Widget _glassButton({
    required String label,
    required LinearGradient gradient,
    required Color glowColor,
    required VoidCallback onTap,
    BoxBorder? border,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          border: border,
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.30),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Layouts
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      children: [
        // Left: Character + Logo
        Expanded(
          flex: 4,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AnimatedCharacter(width: 130.0, height: 130.0),
                const SizedBox(height: 16.0),
                _buildLogo(),
              ],
            ),
          ),
        ),
        // Right: Buttons
        Expanded(
          flex: 3,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 40.0),
              child: _buildButtons(context),
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
