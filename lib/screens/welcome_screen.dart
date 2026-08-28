import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bounceable.dart';
import '../shared/widgets/night_forest_background.dart';
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

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    stopWelcomeMusic();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NightForestBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Dark tint overlay for readability
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.18),
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

  Widget _buildLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 280,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFA726).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFEE58), Color(0xFFF57C00)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                'COREGAME',
                style: GoogleFonts.alfaSlabOne(
                  textStyle: const TextStyle(
                    fontSize: 48.0,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(0.0, 4.0),
                        blurRadius: 2.0,
                      ),
                      Shadow(
                        color: Colors.black,
                        offset: Offset(3.0, 3.0),
                        blurRadius: 0.0,
                      ),
                      Shadow(
                        color: Colors.black,
                        offset: Offset(-1.0, -1.0),
                        blurRadius: 0.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -38.0,
              left: 16.0,
              child: Transform.rotate(
                angle: -0.22,
                child: Image.asset(
                  'assets/cowboy_hat.png',
                  width: 66.0,
                  height: 66.0,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        Container(
          width: 180,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFE65100)],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA726).withValues(alpha: 0.5),
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
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 9.5,
              letterSpacing: 2.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

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
          border: Border.all(color: const Color(0xFF00D2FF).withValues(alpha: 0.35), width: 1.2),
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
                    nickname: 'superhit',
                    avatarPath: 'assets/userprofile/user7.png',
                    onNicknameChanged: (_) {},
                    onAvatarChanged: (_) {},
                    onPlayGame: (_) {},
                    onBalanceChanged: (_) {},
                    onVipLevelChanged: (_) {},
                    onTotalDepositedChanged: (_) {},
                    onSoundToggled: (_) {},
                    onMusicToggled: (_) {},
                    onActiveGatewayChanged: (_) {},
                    onBankDetailsChanged: (_, _, _, _, _) {},
                    onDepositPressed: () {},
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
    return Bounceable(
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
              color: glowColor.withValues(alpha: 0.30),
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

  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
              ],
            ),
          ),
        ),
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
