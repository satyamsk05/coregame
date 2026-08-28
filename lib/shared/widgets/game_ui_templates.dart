import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../games/andar_bahar/widgets/chip_widgets.dart';

// Helper to play sounds (checks if sound is enabled and SoundManager is available)
class SoundHelper {
  static void playClick(bool soundOn) {
    try {
      // Direct call via dynamic/reflection or simple print in templates
      // User can customize this behavior in target games.
    } catch (_) {}
  }
}

// ── TEMPLATE 1: Sidebar leaderboard containing mock players ──
class GameSidebarWidget extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  final bool isLeft;

  const GameSidebarWidget({
    super.key,
    required this.players,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0x3323272C), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: players.asMap().entries.map((entry) {
          final idx = entry.key;
          final p = entry.value;

          final String name = p['name'] as String;
          final double balance = p['balance'] as double;
          final String avatar = p['avatar'] as String;

          String username = name.toLowerCase();
          if (name == 'Billionaire') {
            username = "name304250";
          } else if (name == 'Richie') {
            username = "kFOJx";
          } else if (name == 'High Roller') {
            username = "name136668";
          } else if (name == 'Master') {
            username = "proMaster99";
          } else if (name == 'Pro King') {
            username = "kingSlot88";
          } else if (name == 'Elite Player') {
            username = "eliteGamer";
          }

          // Map to correct banner image template
          String bannerPath = 'assets/dpbanner/IMG_20260821_135148.png';
          if (isLeft) {
            if (idx == 0) {
              bannerPath = 'assets/dpbanner/IMG_20260821_135148.png';
            } else if (idx == 1) {
              bannerPath = 'assets/dpbanner/IMG_20260821_135204.png';
            } else if (idx == 2) {
              bannerPath = 'assets/dpbanner/IMG_20260821_135223.png';
            }
          } else {
            if (idx == 0) {
              bannerPath = 'assets/dpbanner/IMG_20260821_135255.png';
            } else if (idx == 1) {
              bannerPath = 'assets/dpbanner/IMG_20260821_135316.png';
            } else if (idx == 2) {
              bannerPath = 'assets/dpbanner/IMG_20260821_135338.png';
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 35.3,
                      height: 35.3,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black38, blurRadius: 2.0, offset: Offset(0, 1)),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(avatar, fit: BoxFit.cover),
                      ),
                    ),
                    Image.asset(
                      bannerPath,
                      width: 48.5,
                      height: 48.5,
                      fit: BoxFit.contain,
                    ),
                    if (name == 'Master')
                      Positioned(
                        top: -6.0,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black45, blurRadius: 2.0, offset: Offset(0, 1.0))
                            ],
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFFB74D), Color(0xFFFF3D00)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: const Icon(
                              Icons.star,
                              size: 12.6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  username,
                  style: GoogleFonts.roboto(
                    textStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 7.9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 1.0),
                Text(
                  '₹${balance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 7.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── TEMPLATE 2: Bottom Bar (horizontal user profile + chip selector) ──
class GameBottomBarWidget extends StatelessWidget {
  final String nickname;
  final double balance;
  final String avatarPath;
  final int selectedChipValue;
  final List<int> chipValues;
  final bool interactionEnabled;
  final ValueChanged<int> onChipSelected;
  final VoidCallback? onPlaySound;

  const GameBottomBarWidget({
    super.key,
    required this.nickname,
    required this.balance,
    required this.avatarPath,
    required this.selectedChipValue,
    this.chipValues = const [10, 50, 100, 500, 1000],
    required this.interactionEnabled,
    required this.onChipSelected,
    this.onPlaySound,
  });

  @override
  Widget build(BuildContext context) {
    const String userBanner = 'assets/dpbanner/IMG_20260821_135148.png';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left User Profile Box (horizontal layout)
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 35.7,
                  height: 35.7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 2.0, offset: Offset(0, 1)),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(avatarPath, fit: BoxFit.cover),
                  ),
                ),
                Image.asset(
                  userBanner,
                  width: 50.4,
                  height: 50.4,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  right: 2.0, top: 2.0,
                  child: Container(
                    width: 8.0, height: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00E676),
                      border: Border.all(color: Colors.black, width: 1.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nickname,
                  style: GoogleFonts.roboto(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
                  decoration: BoxDecoration(
                    color: const Color(0x4D000000),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    '₹${balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 9.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 8.0),
        // Right Chips selector bar (transparent background)
        IgnorePointer(
          ignoring: !interactionEnabled,
          child: Opacity(
            opacity: interactionEnabled ? 1.0 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: chipValues.expand((val) {
                  final isSelected = selectedChipValue == val;
                  return [
                    GestureDetector(
                      onTap: () {
                        onPlaySound?.call();
                        onChipSelected(val);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        transform: Matrix4.translationValues(0.0, isSelected ? -6.0 : 0.0, 0.0),
                        child: Transform.scale(
                          scale: isSelected ? 1.12 : 1.0,
                          child: PokerChipWidget(value: val, selected: isSelected, size: 33.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4.0),
                  ];
                }).toList()..removeLast(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
