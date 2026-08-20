import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/sound_manager.dart';
import '../shared/widgets/bounceable.dart';

class LobbyScreen extends StatefulWidget {
  final VoidCallback onLogoutPressed;
  final double balance;
  final int vipLevel;
  final double totalDeposited;
  final bool soundOn;
  final bool musicOn;
  final bool isBankAdded;
  final String bankHolderName;
  final String bankPhoneNumber;
  final String bankName;
  final String bankAccountNumber;
  final String activeGateway;
  final String nickname;
  final String avatarPath;
  final ValueChanged<String> onNicknameChanged;
  final ValueChanged<String> onAvatarChanged;
  final Function(String) onPlayGame;
  final ValueChanged<double> onBalanceChanged;
  final ValueChanged<int> onVipLevelChanged;
  final ValueChanged<double> onTotalDepositedChanged;
  final ValueChanged<bool> onSoundToggled;
  final ValueChanged<bool> onMusicToggled;
  final ValueChanged<String> onActiveGatewayChanged;
  final Function(bool, String, String, String, String) onBankDetailsChanged;
  final VoidCallback onDepositPressed;

  const LobbyScreen({
    super.key,
    required this.onLogoutPressed,
    required this.balance,
    required this.vipLevel,
    required this.totalDeposited,
    required this.soundOn,
    required this.musicOn,
    required this.isBankAdded,
    required this.bankHolderName,
    required this.bankPhoneNumber,
    required this.bankName,
    required this.bankAccountNumber,
    required this.activeGateway,
    required this.nickname,
    required this.avatarPath,
    required this.onNicknameChanged,
    required this.onAvatarChanged,
    required this.onPlayGame,
    required this.onBalanceChanged,
    required this.onVipLevelChanged,
    required this.onTotalDepositedChanged,
    required this.onSoundToggled,
    required this.onMusicToggled,
    required this.onActiveGatewayChanged,
    required this.onBankDetailsChanged,
    required this.onDepositPressed,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  // Getters that map to widget properties to maintain full compatibility
  double get _balance => widget.balance;
  int get _vipLevel => widget.vipLevel;
  double get _totalDeposited => widget.totalDeposited;
  bool get _soundOn => widget.soundOn;
  bool get _musicOn => widget.musicOn;
  bool get _isBankAdded => widget.isBankAdded;
  String get _bankHolderName => widget.bankHolderName;
  String get _bankPhoneNumber => widget.bankPhoneNumber;
  String get _bankName => widget.bankName;
  String get _bankAccountNumber => widget.bankAccountNumber;
  String get _activeGateway => widget.activeGateway;
  String get _nickname => widget.nickname;
  String get _avatarPath => widget.avatarPath;

  String _selectedCategory = 'All';

  // Games list metadata matching the files in "assets/"
  final List<Map<String, String>> _games = [
    {
      'title': 'Keno 12',
      'image': 'assets/logos/keno_logo.png',
    },
    {
      'title': 'Coin Flip',
      'image': 'assets/logos/coin_flip_logo.png',
    },
    {
      'title': 'Limbo Rocket',
      'image': 'assets/logos/limbo_logo.png',
    },
    {
      'title': 'Classic Dice',
      'image': 'assets/logos/dice_logo.png',
    },
    {
      'title': 'Mines',
      'image': 'assets/logos/mines_logo.png',
    },
    {
      'title': 'Roulette Rush',
      'image': 'assets/logos/roulette_logo.png',
    },
    {
      'title': 'Crash',
      'image': 'assets/logos/crash_logo.png',
    },
    {
      'title': 'Plinko',
      'image': 'assets/logos/plinko_logo.png',
    },
    {
      'title': '7 Up Down',
      'image': 'assets/logos/seven_up_down_logo.png',
    },
    {
      'title': 'HiLo',
      'image': 'assets/logos/hilo_logo.png',
    },
    {
      'title': 'Andar Bahar',
      'image': 'assets/logos/andar_bahar.png',
    },
    {
      'title': 'Twist',
      'image': 'assets/logos/twist_logo.png',
    },
    {
      'title': 'Fast Parity',
      'image': 'assets/logos/fast_parity_logo.png',
    },
    {
      'title': 'Perya Color Game',
      'image': 'assets/logos/perya_color_game_logo.png',
    },
    {
      'title': 'Double',
      'image': 'assets/logos/double_logo.png',
    },
    {
      'title': 'Jade',
      'image': 'assets/logos/jade_logo.png',
    },
    {
      'title': 'Ring of Fortune',
      'image': 'assets/logos/ring_of_fortune_logo.png',
    },

    {
      'title': 'Fruit Slash',
      'image': 'black',
    },
  ];

  // Check and upgrade VIP levels based on total deposits
  void _checkVipUpgrade(double addedDeposit) {
    double newDeposited = widget.totalDeposited + addedDeposit;
    widget.onTotalDepositedChanged(newDeposited);
    int oldLevel = widget.vipLevel;
    int newLevel = oldLevel;
    
    if (newDeposited >= 500.0) {
      newLevel = 8;
    } else if (newDeposited >= 200.0) {
      newLevel = 7;
    } else if (newDeposited >= 100.0) {
      newLevel = 2;
    } else {
      newLevel = 1;
    }

    if (newLevel > oldLevel) {
      widget.onVipLevelChanged(newLevel);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showVipLevelUpDialog(oldLevel, newLevel);
      });
    }
  }

  // Custom Duolingo-Style 3D Button builder inside the screen
  Widget _buildLobbyButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double width = 120.0,
    double height = 48.0,
    double borderRadius = 8.0,
    bool showRedDot = false,
    bool isCircle = false,
    Widget? customChild,
    bool showShimmer = false,
  }) {
    return _LobbyButton(
      label: label,
      icon: icon,
      color: color,
      onTap: onTap,
      width: width,
      height: height,
      borderRadius: borderRadius,
      showRedDot: showRedDot,
      isCircle: isCircle,
      customChild: customChild,
      showShimmer: showShimmer,
    );
  }

  @override
  Widget build(BuildContext context) {

    final bool isMobilePlatform = defaultTargetPlatform == TargetPlatform.android ||
                                  defaultTargetPlatform == TargetPlatform.iOS;
    final double paddingHorizontal = isMobilePlatform ? 12.0 : 16.0;
    final double paddingVertical = isMobilePlatform ? 12.0 : 16.0;

    final double screenHeight = MediaQuery.of(context).size.height;
    // Calculate the best height for the game cards dynamically to prevent any overflow on small devices
    final double gridHeight = (screenHeight - (paddingVertical * 2) - 80.0).clamp(180.0, 290.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/coinflip/coin_flip_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 4.0, // Shifted closer to the bezel to match photo
              right: paddingHorizontal,
              top: paddingVertical,
              bottom: paddingVertical,
            ),
            child: Stack(
              children: [
                // ==================== TOP BAR ROWS ====================
                Positioned(
                  top: 8.0,
                  left: 0.0,
                  right: 0.0,
                  height: 48.0,
                  child: Row(
                    children: [
                      // Profile Avatar & Brand Logo on Left
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // User Profile Avatar with green dot and dragon asset (moved here!)
                          GestureDetector(
                            onTap: () {
                              SoundManager.playClick();
                              _showProfileDialog();
                            },
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: ClipOval(
                                      child: Image.asset(
                                        _avatarPath,
                                        width: 36.0,
                                        height: 36.0,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                                          radius: 18.0,
                                          backgroundColor: Colors.white,
                                          child: Icon(Icons.face, color: Colors.black, size: 20.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          // Custom B logo + BC.GAME text
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22.0,
                                height: 22.0,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6.0),
                                    bottomLeft: Radius.circular(6.0),
                                    topRight: Radius.circular(10.0),
                                    bottomRight: Radius.circular(10.0),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Container(
                                  width: 6.0,
                                  height: 6.0,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF24EE89),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                'BC.GAME',
                                style: GoogleFonts.pressStart2p(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Center Controls: Balance Capsule & Deposit Combined
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 235.0,
                            height: 42.0,
                            decoration: BoxDecoration(
                              color: const Color(0xFF232528),
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: const Color(0xFF323539), width: 1.0),
                            ),
                            padding: const EdgeInsets.only(left: 10.0, right: 4.0, top: 4.0, bottom: 4.0),
                            child: Row(
                              children: [
                                // Orange Rupee Circle Icon
                                Container(
                                  width: 18.0,
                                  height: 18.0,
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '₹',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  '₹${_balance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                  size: 16.0,
                                ),
                                const Spacer(),
                                // Deposit Button inside combined container
                                GestureDetector(
                                  onTap: () {
                                    SoundManager.playClick();
                                    widget.onDepositPressed();
                                  },
                                  child: Container(
                                    height: 34.0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF24EE89),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Deposit',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Right Side Controls: Gift, Chat, Bell, Avatar
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Gift Box Icon Button
                          GestureDetector(
                            onTap: () {
                              SoundManager.playClick();
                              _showInfoDialog('REWARDS', 'No active rewards found. Check back later!');
                            },
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E3035),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.card_giftcard, color: Colors.white70, size: 20.0),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          // Chat Icon Button
                          GestureDetector(
                            onTap: () {
                              SoundManager.playClick();
                              _showInfoDialog('CHATROOM', 'Connecting to global chatroom...');
                            },
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E3035),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 18.0),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          // Notification Bell Icon Button with green dot
                          GestureDetector(
                            onTap: () {
                              SoundManager.playClick();
                              _showMailDialog();
                            },
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E3035),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              alignment: Alignment.center,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.notifications_none, color: Colors.white70, size: 20.0),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 7.0,
                                      height: 7.0,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF24EE89),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ==================== BOTTOM BAR ROWS ====================

                // Row of all 6 Action Buttons stretching across bottom
                Positioned(
                  bottom: 8.0,
                  left: 0.0,
                  right: 0.0,
                  height: 36.0,
                  child: Row(
                    children: [
                      // Withdraw
                      _buildLobbyButton(
                        label: 'Withdraw',
                        icon: Icons.arrow_downward,
                        color: const Color(0xFF3A4142),
                        width: 110.0,
                        height: 36.0,
                        onTap: _showWithdrawalFlow,
                      ),
                      const SizedBox(width: 8.0),
                      // Bet History
                      _buildLobbyButton(
                        label: 'Bet History',
                        icon: Icons.history,
                        color: const Color(0xFF3A4142),
                        width: 115.0,
                        height: 36.0,
                        onTap: () => _showInfoDialog('BET HISTORY', 'No recent bet history. Start a game to see records!'),
                      ),
                      const Spacer(),
                      // Vault Pro
                      _buildLobbyButton(
                        label: 'Vault Pro',
                        icon: Icons.lock,
                        color: const Color(0xFF3A4142),
                        width: 125.0,
                        height: 36.0,
                        onTap: () => _showInfoDialog('VAULT PRO', 'Secure your funds in the VIP vault. Annual interest rate up to 5%!'),
                      ),
                      const SizedBox(width: 8.0),
                      // Live Support
                      _buildLobbyButton(
                        label: 'Live Support',
                        icon: Icons.headset,
                        color: const Color(0xFF3A4142),
                        width: 135.0,
                        height: 36.0,
                        onTap: () => _showInfoDialog('LIVE SUPPORT', 'Connecting to live chat support...'),
                      ),
                      const Spacer(),
                      // Referral
                      _buildLobbyButton(
                        label: 'Referral',
                        icon: Icons.share,
                        color: const Color(0xFF3A4142),
                        width: 115.0,
                        height: 36.0,
                        onTap: _showReferralDialog,
                      ),
                      const SizedBox(width: 8.0),
                      // VIP Club
                      _buildLobbyButton(
                        label: 'VIP Club',
                        icon: Icons.star,
                        color: const Color(0xFF3A4142),
                        width: 120.0,
                        height: 36.0,
                        onTap: _showVipDialog,
                        customChild: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/icon_vip_club.png',
                              width: 16.0,
                              height: 16.0,
                              errorBuilder: (context, error, stackTrace) => const SizedBox(width: 16.0, height: 16.0),
                            ),

                            const SizedBox(width: 6.0),
                            const Text(
                              'VIP ',
                              style: TextStyle(color: Color(0xFF24EE89), fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Club',
                              style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 5.5 Category Sidebar (Screenshot 1)
                Positioned(
                  top: 62.0,
                  bottom: 50.0,
                  left: 0.0,
                  width: 195.0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: gridHeight,
                      child: _buildCategorySidebar(),
                    ),
                  ),
                ),

                // 6. Horizontal Game Cards List (2x2 Grid Layout)
                Positioned(
                  top: 62.0,
                  bottom: 50.0,
                  left: 202.0,
                  right: 0.0,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: SizedBox(
                      height: gridHeight,
                      child: Builder(
                        builder: (context) {
                          final List<Map<String, String>> filteredGames = _games.where((game) {
                            if (_selectedCategory == 'Recent') {
                              return ['Keno 12', 'Coin Flip', 'Limbo Rocket', 'Classic Dice'].contains(game['title']);
                            }
                            if (_selectedCategory == 'All') return true; // 'New Releases' shows all
                            if (_selectedCategory == 'Hot') {
                              return ['Keno 12', 'Coin Flip', 'Limbo Rocket', 'Classic Dice', 'Mines', 'Twist'].contains(game['title']);
                            }
                            if (_selectedCategory == 'Poker') {
                              return ['HiLo', 'Fruit Slash', 'Andar Bahar'].contains(game['title']);
                            }
                            if (_selectedCategory == 'Slots') {
                              return ['Roulette Rush', 'Crash', 'Plinko', '7 Up Down', 'Twist'].contains(game['title']);
                            }
                            return true;
                          }).toList();

                          Widget gridContent;
                          if (filteredGames.isEmpty) {
                            gridContent = Center(
                              key: ValueKey('empty_$_selectedCategory'),
                              child: Text(
                                'No Games Found',
                                style: GoogleFonts.pressStart2p(
                                  textStyle: const TextStyle(color: Colors.grey, fontSize: 8.0),
                                ),
                              ),
                            );
                          } else {
                            gridContent = GridView.builder(
                              key: ValueKey(_selectedCategory),
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              itemCount: filteredGames.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12.0,
                                crossAxisSpacing: 12.0,
                                childAspectRatio: 1.0, // Perfect square cards
                              ),
                              itemBuilder: (context, index) {
                                final game = filteredGames[index];
                                return GestureDetector(
                                  onTap: () {
                                    if (game['title'] == 'Keno 12') {
                                      widget.onPlayGame('keno');
                                    } else if (game['title'] == 'Coin Flip') {
                                      widget.onPlayGame('coin_flip');
                                    } else if (game['title'] == 'Limbo Rocket') {
                                      widget.onPlayGame('limbo');
                                    } else if (game['title'] == 'Classic Dice') {
                                      widget.onPlayGame('dice');
                                    } else if (game['title'] == 'Mines') {
                                      widget.onPlayGame('mines');
                                    } else if (game['title'] == 'HiLo') {
                                      widget.onPlayGame('hilo');
                                    } else if (game['title'] == '7 Up Down') {
                                      widget.onPlayGame('seven_up_down');
                                    } else if (game['title'] == 'Andar Bahar') {
                                      widget.onPlayGame('andar_bahar');
                                    } else if (game['title'] == 'Roulette Rush') {
                                      widget.onPlayGame('roulette');
                                    } else if (game['title'] == 'Plinko') {
                                      widget.onPlayGame('plinko');
                                    } else if (game['title'] == 'Crash') {
                                      widget.onPlayGame('crash');
                                    } else if (game['title'] == 'Twist') {
                                      widget.onPlayGame('twist');
                                    } else if (game['title'] == 'Double') {
                                      widget.onPlayGame('double');
                                    } else if (game['title'] == 'Ring of Fortune') {
                                      widget.onPlayGame('ring_of_fortune');
                                    } else {
                                      _showInfoDialog(game['title']!, 'Launching ${game['title']}! Place your bets to win big.');
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF160E45),
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(color: const Color(0xFF4A5152), width: 2.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 6.0,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: game['image'] == 'black'
                                          ? Container(
                                              color: const Color(0xFF0D0A1B),
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.videogame_asset, color: Color(0xFF9E84FF), size: 28.0),
                                                  const SizedBox(height: 6.0),
                                                  Text(
                                                    game['title']!.toUpperCase(),
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.pressStart2p(
                                                      textStyle: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 8.0,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Image.asset(
                                              game['image']!,
                                              fit: BoxFit.fill,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: const Color(0xFF0D0A1B),
                                                alignment: Alignment.center,
                                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.style, color: Color(0xFF00E5FF), size: 28.0),
                                                    const SizedBox(height: 6.0),
                                                    Text(
                                                      game['title']!.toUpperCase(),
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.pressStart2p(
                                                        textStyle: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 8.0,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                          return TweenAnimationBuilder<double>(
                            key: ValueKey(_selectedCategory),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(-40.0 * (1.0 - value), 0.0), // Slides in smoothly from left by 40 pixels!
                                  child: child,
                                ),
                              );
                            },
                            child: gridContent,
                          );
                        }
                      ),
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

  // ==================== SIDEBAR COMPONENT HELPERS ====================

  Widget _buildCategorySidebar() {
    return Container(
      width: 195.0,
      decoration: BoxDecoration(
        color: const Color(0xFF232528),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF323539), width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSidebarTab(
                  id: 'Recent',
                  label: 'Recent',
                  icon: Icons.history,
                  iconColor: Colors.grey,
                ),
                const SizedBox(height: 8.0),
                _buildSidebarTab(
                  id: 'Hot',
                  label: 'Hot Games',
                  icon: Icons.local_fire_department,
                  iconColor: Colors.amber,
                ),
                const SizedBox(height: 8.0),
                _buildSidebarTab(
                  id: 'All',
                  label: 'New Releases',
                  icon: Icons.rocket_launch,
                  iconColor: Colors.purple[300]!,
                ),
                const SizedBox(height: 8.0),
                _buildSidebarTab(
                  id: 'Slots',
                  label: 'Slots',
                  icon: Icons.casino,
                  iconColor: Colors.cyan[300]!,
                ),
                const SizedBox(height: 8.0),
                _buildSidebarTab(
                  id: 'Poker',
                  label: 'Game Shows',
                  icon: Icons.sports_esports,
                  iconColor: Colors.red[300]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSidebarTab({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    // Select correct asset based on label
    String assetName = 'icon_referral.png';
    if (label.toLowerCase().contains('vip')) {
      assetName = 'icon_vip_club.png';
    } else if (label.toLowerCase().contains('support')) {
      assetName = 'icon_live_support.png';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38.0,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF323738),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            Image.asset(
              'assets/icons/$assetName',
              width: 18.0,
              height: 18.0,
              errorBuilder: (context, error, stackTrace) => Icon(icon, color: iconColor, size: 18.0),
            ),

            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite, color: Colors.cyanAccent, size: 10.0),
          const SizedBox(width: 4.0),
          Text(
            'S',
            style: GoogleFonts.pressStart2p(
              textStyle: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.favorite, color: Colors.pink, size: 13.0),
          Text(
            'rt',
            style: GoogleFonts.pressStart2p(
              textStyle: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4.0),
          const Icon(Icons.star, color: Colors.pinkAccent, size: 10.0),
        ],
      ),
    );
  }

  Widget _buildSidebarTab({
    required String id,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    final bool isSelected = _selectedCategory == id;
    
    // Select correct asset based on id
    String assetName = 'icon_hot_games.png';
    if (id == 'Recent') {
      assetName = 'icon_bet_history.png';
    } else if (id == 'Slots') {
      assetName = 'icon_slots.png';
    } else if (id == 'Poker') {
      assetName = 'icon_game_shows.png';
    } else if (id == 'All') {
      assetName = 'icon_new_releases.png';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isSelected ? 44.0 : 38.0,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A4142) : const Color(0xFF323738),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            if (isSelected) ...[
              Container(
                width: 3.0,
                height: 18.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF24EE89),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 6.0),
            ],
            Image.asset(
              'assets/icons/$assetName',
              width: isSelected ? 20.0 : 18.0,
              height: isSelected ? 20.0 : 18.0,

              errorBuilder: (context, error, stackTrace) => Icon(
                icon,
                color: isSelected ? const Color(0xFF24EE89) : iconColor,
                size: isSelected ? 20.0 : 18.0,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF24EE89) : Colors.white,
                  fontSize: isSelected ? 12.5 : 11.0,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PREMIUM CASINO DIALOG TEMPLATE ====================

  void _showCustomCasinoDialog({
    required String title,
    required Widget content,
    double maxWidth = 640.0,
    double maxHeight = 340.0,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          width: maxWidth,
          height: maxHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2024),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF2E3135), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12.0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF2E3135), width: 1.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.pressStart2p(
                        textStyle: const TextStyle(
                          fontSize: 11.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _Bounceable(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E3135),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF3E4347)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.close, color: Colors.white70, size: 14.0),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scrollable Context Layer
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simple info alert box
  void _showInfoDialog(String title, String message) {
    _showCustomCasinoDialog(
      title: title,
      maxHeight: 200.0,
      maxWidth: 450.0,
      content: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Casino Balance Capsule Builder
  Widget _buildCasinoBalanceCapsule(double amount, {bool showAddButton = false, VoidCallback? onAddTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: const Color(0xFF181A1F),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFF2E3135), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16.0),
          const SizedBox(width: 6.0),
          Text(
            amount.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13.0,
              letterSpacing: 0.5,
            ),
          ),
          if (showAddButton) ...[
            const SizedBox(width: 8.0),
            GestureDetector(
              onTap: onAddTap,
              child: Container(
                padding: const EdgeInsets.all(2.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF00C853),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 10.0),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== DIALOG 1: PROFILE POPUP (Screenshot 2) ====================

  void _showProfileDialog() {
    _showCustomCasinoDialog(
      title: 'PROFILE',
      maxHeight: 310.0,
      maxWidth: 580.0,
      content: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Avatar profile details
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const SizedBox(height: 6.0),
                      // Avatar glowing frame
                      Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF2E3135), width: 2.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8.0,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFF181A1F),
                              backgroundImage: AssetImage(_avatarPath),
                            ),
                          ),
                          // VIP Level Ribbon
                          Positioned(
                            bottom: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9100),
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: const Color(0xFF2E3135), width: 1.0),
                              ),
                              child: Text(
                                'VIP $_vipLevel',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18.0),
                      // Edit avatar button
                      _buildMiniCasinoButton(
                        text: 'EDIT AVATAR',
                        color: const Color(0xFF2E3135),
                        onTap: () {
                          _showAvatarGridDialog();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24.0),
                
                // Right Column: Player details matching screenshot
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildProfileDetailRow('NICKNAME:', _nickname)),
                          const SizedBox(width: 8.0),
                          _buildMiniCasinoButton(
                            text: 'EDIT',
                            color: const Color(0xFF00C853),
                            onTap: () {
                              _showEditNicknameDialog();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          Expanded(child: _buildProfileDetailRow('PLAYER ID:', '18316818')),
                          const SizedBox(width: 8.0),
                          _buildMiniCasinoButton(
                            text: 'COPY',
                            color: const Color(0xFF00C853),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ID Copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      _buildProfileDetailRow('PHONE NO:', '091-$_bankPhoneNumber'),
                      const SizedBox(height: 12.0),
                      // Balance Row
                      Row(
                        children: [
                          const Text(
                            'COINS:  ',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12.0),
                          ),
                          _buildCasinoBalanceCapsule(
                            _balance, 
                            showAddButton: true,
                            onAddTap: () {
                              Navigator.pop(context);
                              widget.onDepositPressed();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom button: SET PW
          Center(
            child: _buildLargeCasinoButton(
              text: 'SET PW',
              color: const Color(0xFF2E3135),
              width: 140,
              onTap: () {
                _showInfoDialog('PASSWORD', 'Simulated password change. Encryption key updated!');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNicknameDialog() {
    final TextEditingController controller = TextEditingController(text: _nickname);
    _showCustomCasinoDialog(
      title: 'EDIT NICKNAME',
      maxHeight: 180.0,
      maxWidth: 400.0,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 42.0,
            decoration: BoxDecoration(
              color: const Color(0xFF161618),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF2E3135), width: 1.2),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter nickname...',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 13.0),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildMiniCasinoButton(
                text: 'CANCEL',
                color: const Color(0xFF323539),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 12.0),
              _buildMiniCasinoButton(
                text: 'SAVE',
                color: const Color(0xFF00C853),
                onTap: () {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    widget.onNicknameChanged(newName);
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _showProfileDialog();
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAvatarGridDialog() {
    _showCustomCasinoDialog(
      title: 'CHOOSE AVATAR',
      maxHeight: 220.0,
      maxWidth: 450.0,
      content: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 7,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          final String path = 'assets/userprofile/user${index + 1}.png';
          final bool isSelected = _avatarPath == path;
          return Bounceable(
            onTap: () {
              widget.onAvatarChanged(path);
              Navigator.pop(context);
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 100), () {
                _showProfileDialog();
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF2E3135),
                  width: isSelected ? 2.5 : 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 6.0,
                          spreadRadius: 1.0,
                        )
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.asset(
                  path,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 11.0,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13.0,
          ),
        ),
      ],
    );
  }

  // Shop dialog removed in favor of full screen DepositScreen

  // ==================== DIALOG 3: WITHDRAWALS POPUP (Screenshot 3) ====================

  void _showWithdrawalFlow() {
    if (!_isBankAdded) {
      _showAddBankDialog();
      return;
    }

    final withdrawController = TextEditingController(text: '100');
    final withdrawFormKey = GlobalKey<FormState>();
    String activeTab = 'IMPS';

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double dialogWidth = screenWidth < 650 ? screenWidth * 0.95 : 619.0;
    final double dialogHeight = screenHeight < 360 ? screenHeight * 0.95 : 320.0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2024),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF2E3135), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12.0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WITHDRAWAL',
                      style: GoogleFonts.pressStart2p(
                        textStyle: const TextStyle(
                          fontSize: 11.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _Bounceable(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E3135),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF3E4347)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.close, color: Colors.white70, size: 14.0),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF2E3135), height: 1.0, thickness: 1.0),
              
              // Body
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setWithdrawState) => Row(
                    children: [
                      // Left Sidebar
                      Container(
                        width: 135.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFF181A1F),
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15.0)),
                          border: Border(
                            right: BorderSide(color: Color(0xFF2E3135), width: 1.0),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                        child: Column(
                          children: [
                            // IMPS Tab
                            _Bounceable(
                              onTap: () {
                                setWithdrawState(() {
                                  activeTab = 'IMPS';
                                });
                              },
                              child: Container(
                                height: 38.0,
                                decoration: BoxDecoration(
                                  color: activeTab == 'IMPS' ? const Color(0xFF232528) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: activeTab == 'IMPS'
                                      ? Border.all(color: const Color(0xFF323539), width: 1.0)
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                child: Row(
                                  children: [
                                    if (activeTab == 'IMPS') ...[
                                      Container(
                                        width: 3.0,
                                        height: 14.0,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF24EE89),
                                          borderRadius: BorderRadius.circular(1.5),
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                    ] else ...[
                                      const SizedBox(width: 11.0),
                                    ],
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: activeTab == 'IMPS' ? Colors.white : Colors.white70,
                                      size: 14.0,
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      'IMPS',
                                      style: TextStyle(
                                        color: activeTab == 'IMPS' ? Colors.white : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            // Records Tab
                            _Bounceable(
                              onTap: () {
                                setWithdrawState(() {
                                  activeTab = 'Records';
                                });
                              },
                              child: Container(
                                height: 38.0,
                                decoration: BoxDecoration(
                                  color: activeTab == 'Records' ? const Color(0xFF232528) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: activeTab == 'Records'
                                      ? Border.all(color: const Color(0xFF323539), width: 1.0)
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                child: Row(
                                  children: [
                                    if (activeTab == 'Records') ...[
                                      Container(
                                        width: 3.0,
                                        height: 14.0,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF24EE89),
                                          borderRadius: BorderRadius.circular(1.5),
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                    ] else ...[
                                      const SizedBox(width: 11.0),
                                    ],
                                    Icon(
                                      Icons.history,
                                      color: activeTab == 'Records' ? Colors.white : Colors.white70,
                                      size: 14.0,
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      'Records',
                                      style: TextStyle(
                                        color: activeTab == 'Records' ? Colors.white : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Right Content Area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: activeTab == 'IMPS'
                              ? Form(
                                  key: withdrawFormKey,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Total Balance Row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total Balance :',
                                              style: GoogleFonts.montserrat(
                                                textStyle: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            // Balance Capsule matching top bar
                                            Container(
                                              height: 34.0,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF181A1F),
                                                borderRadius: BorderRadius.circular(8.0),
                                                border: Border.all(color: const Color(0xFF2E3135), width: 1.2),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 16.0,
                                                    height: 16.0,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.orange,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: const Text(
                                                      '₹',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10.0,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8.0),
                                                  Text(
                                                    '₹${_balance.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13.0,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12.0),
                                        
                                        // Withdrawable Row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Withdrawable :',
                                              style: GoogleFonts.montserrat(
                                                textStyle: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12.0),
                                            // Text Field Container
                                            Expanded(
                                              child: Container(
                                                height: 34.0,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF181A1F),
                                                  borderRadius: BorderRadius.circular(6.0),
                                                  border: Border.all(color: const Color(0xFF2E3135), width: 1.2),
                                                ),
                                                child: TextFormField(
                                                  controller: withdrawController,
                                                  keyboardType: TextInputType.number,
                                                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                                                  decoration: const InputDecoration(
                                                    border: InputBorder.none,
                                                    hintText: 'Enter Amount',
                                                    hintStyle: TextStyle(color: Colors.white24, fontSize: 12.0),
                                                    contentPadding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 12.0),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8.0),
                                            // MAX Button
                                            _Bounceable(
                                              onTap: () {
                                                setWithdrawState(() {
                                                  withdrawController.text = _balance.toInt().toString();
                                                });
                                              },
                                              child: Container(
                                                width: 65.0,
                                                height: 34.0,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2C2F36),
                                                  borderRadius: BorderRadius.circular(6.0),
                                                  border: Border.all(color: const Color(0xFF3E4347), width: 1.0),
                                                ),
                                                alignment: Alignment.center,
                                                child: const Text(
                                                  'MAX',
                                                  style: TextStyle(
                                                    color: Colors.orangeAccent,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12.0),
                                        
                                        // Bank Info Box
                                        Container(
                                          width: double.infinity,
                                          height: 55.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF181A1F),
                                            borderRadius: BorderRadius.circular(8.0),
                                            border: Border.all(color: const Color(0xFF2E3135), width: 1.0),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Name : $_bankHolderName',
                                                      style: GoogleFonts.montserrat(textStyle: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      'Account No : $_bankAccountNumber',
                                                      style: GoogleFonts.montserrat(textStyle: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const VerticalDivider(color: Color(0xFF2E3135), width: 20.0, thickness: 1.0),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Bank Name : $_bankName',
                                                      style: GoogleFonts.montserrat(textStyle: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      'IFSC Code : ${widget.bankPhoneNumber}',
                                                      style: GoogleFonts.montserrat(textStyle: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12.0),
                                        
                                        // Bottom Row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _Bounceable(
                                              onTap: () {
                                                final withdrawVal = double.tryParse(withdrawController.text);
                                                if (withdrawVal == null || withdrawVal <= 0) {
                                                  _showInfoDialog('ERROR', 'Please enter a valid withdrawal amount.');
                                                  return;
                                                }
                                                if (withdrawVal > _balance) {
                                                  _showInfoDialog('ERROR', 'Insufficient balance available.');
                                                  return;
                                                }
                                                
                                                widget.onBalanceChanged(widget.balance - withdrawVal);
                                                Navigator.pop(context);
                                                _showInfoDialog(
                                                  'SUCCESS', 
                                                  'Withdrawal of ₹${withdrawVal.toStringAsFixed(0)} initiated to $_bankName!'
                                                );
                                              },
                                              child: Container(
                                                width: 130.0,
                                                height: 34.0,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF00C853),
                                                  borderRadius: BorderRadius.circular(6.0),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF00C853).withOpacity(0.2),
                                                      blurRadius: 8.0,
                                                      offset: const Offset(0, 2),
                                                    )
                                                  ]
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'WITHDRAW',
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
                                            Text(
                                              'REMAINING WAGER : ₹0.00',
                                              style: GoogleFonts.montserrat(
                                                textStyle: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : _buildWithdrawalRecordsView(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawalRecordsView() {
    final List<Map<String, String>> records = [
      {'txId': 'T83925018', 'amount': '₹500', 'status': 'SUCCESS', 'date': '2026/08/18 19:40'},
      {'txId': 'T91274092', 'amount': '₹1,500', 'status': 'PENDING', 'date': '2026/08/18 20:12'},
      {'txId': 'T72839103', 'amount': '₹1,000', 'status': 'SUCCESS', 'date': '2026/08/17 11:15'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WITHDRAWAL RECORDS',
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: ListView.builder(
            itemCount: records.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final record = records[index];
              final isSuccess = record['status'] == 'SUCCESS';
              return Container(
                margin: const EdgeInsets.only(bottom: 6.0),
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF181A1F),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: const Color(0xFF2E3135), width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              record['txId']!,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              record['date']!,
                              style: const TextStyle(color: Colors.white24, fontSize: 8.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'Amount: ${record['amount']}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.0),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: isSuccess 
                            ? const Color(0xFF00C853).withOpacity(0.12)
                            : const Color(0xFFFFAB00).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(
                          color: isSuccess ? const Color(0xFF00C853) : const Color(0xFFFFAB00), 
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        record['status']!,
                        style: TextStyle(
                          color: isSuccess ? const Color(0xFF00C853) : const Color(0xFFFFAB00), 
                          fontSize: 7.5, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  // ==================== DIALOG 4: MAIL POPUP (Screenshot 4) ====================

  void _showMailDialog() {
    final List<Map<String, String>> mails = [
      {'title': 'DAILY BETTING REBATE', 'desc': 'Your activity bonus has been credited.', 'date': '2026/08/13 11:14'},
      {'title': 'Daily first deposit bonus', 'desc': 'Dear member, your deposit bonus is ready.', 'date': '2026/08/13 01:13'},
      {'title': 'DAILY BETTING REBATE', 'desc': 'Your activity bonus has been credited.', 'date': '2026/08/12 11:22'},
      {'title': 'Daily first deposit bonus', 'desc': 'Dear member, your deposit bonus is ready.', 'date': '2026/08/12 01:13'},
    ];

    _showCustomCasinoDialog(
      title: 'MAIL',
      maxHeight: 320.0,
      maxWidth: 580.0,
      content: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: mails.length,
              itemBuilder: (context, index) {
                final mail = mails[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181A1F),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: const Color(0xFF2E3135), width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline, color: Color(0xFFFFD700), size: 24.0),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mail['title']!,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.0),
                            ),
                            Text(
                              mail['desc']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey, fontSize: 9.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            mail['date']!,
                            style: const TextStyle(color: Colors.grey, fontSize: 8.0),
                          ),
                          const SizedBox(height: 2.0),
                          // Read stamp look
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF00C853), width: 1.0),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: const Text(
                              'READ',
                              style: TextStyle(color: Color(0xFF00C853), fontSize: 7.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Bottom action buttons matching Screenshot 4
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLargeCasinoButton(
                text: 'DELETE ALL',
                color: const Color(0xFF2E3135),
                width: 140,
                onTap: () {
                  Navigator.pop(context);
                  _showInfoDialog('MAILBOX', 'All read mails deleted successfully.');
                },
              ),
              _buildLargeCasinoButton(
                text: 'CLAIM ALL',
                color: const Color(0xFF00C853),
                width: 140,
                onTap: () {
                  Navigator.pop(context);
                  widget.onBalanceChanged(widget.balance + 5.0);
                  _showInfoDialog('MAILBOX', 'Claimed ₹5.00 daily rebate bonuses successfully!');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== DIALOG 5: VIP CLUB POPUP (Screenshot 5) ====================

  void _showVipDialog() {
    _showCustomCasinoDialog(
      title: 'PERMANENT EARNINGS',
      maxHeight: 330.0,
      maxWidth: 620.0,
      content: Column(
        children: [
          // Top section: Crown graphic & bonus info
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 36.0),
              const SizedBox(width: 8.0),
              Text(
                'VIP CLUB',
                style: GoogleFonts.pressStart2p(textStyle: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              // Info banner notes from Screenshot 5
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF181A1F),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: const Color(0xFF2E3135), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.date_range, color: Color(0xFFFFD700), size: 10.0),
                        const SizedBox(width: 4.0),
                        const Text(
                          'Weekly Bonus - (Every Monday 8am)',
                          style: TextStyle(color: Color(0xFFFFD700), fontSize: 8.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month, color: Color(0xFFFF9100), size: 10.0),
                        const SizedBox(width: 4.0),
                        const Text(
                          'Monthly Bonus - (1st of each month 8am)',
                          style: TextStyle(color: Color(0xFFFF9100), fontSize: 8.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Progress XP Bar matching Screenshot 5
          Row(
            children: [
              const Text(
                'VIP 7',
                style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 12.0),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Container(
                  height: 14.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF181A1F),
                    borderRadius: BorderRadius.circular(7.0),
                    border: Border.all(color: const Color(0xFF2E3135), width: 1.0),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: 171503 / 200000,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF9100)]),
                              borderRadius: BorderRadius.circular(7.0),
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        '171,503 / 200,000',
                        style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              const Text(
                'VIP 8',
                style: TextStyle(color: Color(0xFFFF9100), fontWeight: FontWeight.w900, fontSize: 12.0),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          const Text(
            'You still need 28,497 EXP to upgrade to VIP8',
            style: TextStyle(color: Colors.grey, fontSize: 9.0),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),

          // VIP7 Benefits Grid list
          Expanded(
            child: Row(
              children: [
                _buildVipBenefitCard(
                  title: 'UPGRADE REWARD',
                  reward: '90',
                  actionText: 'RECEIVED',
                  isReceived: true,
                  icon: Icons.emoji_events,
                  iconColor: const Color(0xFFFFD700), // Gold
                ),
                const SizedBox(width: 8.0),
                _buildVipBenefitCard(
                  title: 'WEEKLY REWARD',
                  reward: '60',
                  actionText: 'RECEIVE',
                  isReceived: false,
                  icon: Icons.redeem,
                  iconColor: const Color(0xFFFF9100), // Amber
                ),
                const SizedBox(width: 8.0),
                _buildVipBenefitCard(
                  title: 'MONTHLY REWARD',
                  reward: '70',
                  actionText: 'RECEIVE',
                  isReceived: false,
                  icon: Icons.savings,
                  iconColor: const Color(0xFF00C853), // Green
                ),
                const SizedBox(width: 8.0),
                _buildVipBenefitCard(
                  title: 'SIGN IN BUFF',
                  reward: '21%',
                  actionText: 'DETAILS',
                  isReceived: false,
                  icon: Icons.flash_on,
                  iconColor: const Color(0xFF00E5FF), // Cyan neon
                  isBuff: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipBenefitCard({
    required String title,
    required String reward,
    required String actionText,
    required bool isReceived,
    required IconData icon,
    required Color iconColor,
    bool isBuff = false,
  }) {
    final Color buttonColor = isReceived
        ? const Color(0xFF2E3135)
        : (actionText.toUpperCase() == 'DETAILS' ? const Color(0xFF2E3135) : const Color(0xFF00C853));

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF232528), Color(0xFF181A1F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFF2E3135), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4.0,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 7.5, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withOpacity(0.3), width: 1.0),
              ),
              child: Icon(icon, color: iconColor, size: 18.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isBuff) ...[
                  const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 12.0),
                  const SizedBox(width: 3.0),
                ],
                Text(
                  reward,
                  style: TextStyle(
                    color: isBuff ? const Color(0xFF00E5FF) : const Color(0xFFFFD700),
                    fontSize: 14.0,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 2.0, offset: Offset(1.0, 1.0)),
                    ],
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                if (!isReceived) {
                  _showInfoDialog('VIP CLAIM', 'Perk benefit claimed successfully!');
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: isReceived
                      ? []
                      : [
                          BoxShadow(
                            color: buttonColor.withOpacity(0.3),
                            blurRadius: 4.0,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Text(
                  actionText.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== REFERRAL DIALOG (Withdrawal Layout style) ====================

  void _showReferralDialog() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double dialogWidth = screenWidth < 650 ? screenWidth * 0.95 : 619.0;
    final double dialogHeight = screenHeight < 360 ? screenHeight * 0.95 : 320.0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2024),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF2E3135), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12.0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'REFERRAL',
                      style: GoogleFonts.pressStart2p(
                        textStyle: const TextStyle(
                          fontSize: 11.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _Bounceable(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E3135),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF3E4347)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.close, color: Colors.white70, size: 14.0),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF2E3135), height: 1.0, thickness: 1.0),
              
              // Body
              Expanded(
                child: Row(
                  children: [
                    // Left Sidebar
                    Container(
                      width: 135.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFF181A1F),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15.0)),
                        border: Border(
                          right: BorderSide(color: Color(0xFF2E3135), width: 1.0),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                      child: Column(
                        children: [
                          // Invite Tab (Selected)
                          Container(
                            height: 38.0,
                            decoration: BoxDecoration(
                              color: const Color(0xFF232528),
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: const Color(0xFF323539), width: 1.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 3.0,
                                  height: 14.0,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF24EE89),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                const Icon(Icons.people, color: Colors.white, size: 14.0),
                                const SizedBox(width: 8.0),
                                const Text(
                                  'Invite',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          // Rules Tab (Unselected)
                          _Bounceable(
                            onTap: () {
                              _showInfoDialog('RULES', 'Invite friends via your referral link. You earn a permanent 50% commission from their game fees!');
                            },
                            child: Container(
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: const Row(
                                children: [
                                  SizedBox(width: 11.0),
                                  Icon(Icons.rule_folder, color: Colors.white70, size: 14.0),
                                  SizedBox(width: 8.0),
                                  Text(
                                    'Rules',
                                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Right Content Area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INVITE FRIENDS & EARN CASH',
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              const Text(
                                'Get a 50% commission for every active user that signs up under your referral code.',
                                style: TextStyle(color: Colors.grey, fontSize: 9.5),
                              ),
                              const SizedBox(height: 12.0),
                              
                              // Referral Code Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 36.0,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF181A1F),
                                        borderRadius: BorderRadius.circular(6.0),
                                        border: Border.all(color: const Color(0xFF2E3135), width: 1.2),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                      child: const Text(
                                        'REF-18316818',
                                        style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  // COPY Button
                                  _Bounceable(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Referral Code Copied!')),
                                      );
                                    },
                                    child: Container(
                                      height: 36.0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00C853),
                                        borderRadius: BorderRadius.circular(6.0),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'COPY',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12.0),
                              
                              // Stats Box
                              Container(
                                width: double.infinity,
                                height: 50.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF181A1F),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: const Color(0xFF2E3135), width: 1.0),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('TOTAL INVITED', style: TextStyle(color: Colors.grey, fontSize: 8.0, fontWeight: FontWeight.bold)),
                                        Text('0 Users', style: GoogleFonts.montserrat(textStyle: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.w600))),
                                      ],
                                    ),
                                    const VerticalDivider(color: Color(0xFF2E3135), width: 20.0, thickness: 1.0),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('COMMISSION EARNED', style: TextStyle(color: Colors.grey, fontSize: 8.0, fontWeight: FontWeight.bold)),
                                        Text('₹0.00', style: GoogleFonts.montserrat(textStyle: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.w600))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              
                              // Claim Button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildLargeCasinoButton(
                                    text: 'CLAIM REWARD',
                                    color: const Color(0xFF00C853),
                                    width: 140,
                                    onTap: () {
                                      _showInfoDialog('CLAIM', 'No rewards currently available to claim.');
                                    },
                                  ),
                                  const Text(
                                    'MINIMUM CLAIM : ₹10.00',
                                    style: TextStyle(color: Colors.grey, fontSize: 8.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SETTINGS DIALOG (Centered) ====================

  void _showSettingsDialog() {
    _showCustomCasinoDialog(
      title: 'SETTINGS',
      maxHeight: 250.0,
      maxWidth: 450.0,
      content: Column(
        children: [
          StatefulBuilder(
            builder: (context, setModalState) => SwitchListTile(
              dense: true,
              value: _soundOn,
              activeColor: const Color(0xFF00C853),
              title: const Text('SOUND EFFECTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.0)),
              secondary: const Icon(Icons.volume_up, color: Colors.white, size: 20),
              onChanged: (val) {
                widget.onSoundToggled(val);
                setModalState(() {});
              },
            ),
          ),
          StatefulBuilder(
            builder: (context, setModalState) => SwitchListTile(
              dense: true,
              value: _musicOn,
              activeColor: const Color(0xFF00C853),
              title: const Text('MUSIC TRACKS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.0)),
              secondary: const Icon(Icons.music_note, color: Colors.white, size: 20),
              onChanged: (val) {
                widget.onMusicToggled(val);
                setModalState(() {});
              },
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLargeCasinoButton(
                text: 'LOGOUT',
                color: const Color(0xFFFF3355),
                width: 110,
                onTap: () {
                  Navigator.pop(context);
                  widget.onLogoutPressed();
                },
              ),
              _buildLargeCasinoButton(
                text: 'CLOSE',
                color: const Color(0xFF2E3135),
                width: 110,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // VIP Level-Up Notification popup
  void _showVipLevelUpDialog(int oldLevel, int newLevel) {
    _showCustomCasinoDialog(
      title: 'VIP LEVEL UP!',
      maxHeight: 250.0,
      maxWidth: 450.0,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars, color: Color(0xFFFFD700), size: 48.0),
          const SizedBox(height: 10.0),
          Text(
            'CONGRATULATIONS!',
            style: GoogleFonts.pressStart2p(
              textStyle: const TextStyle(
                fontSize: 11.0, 
                color: Color(0xFF00C853), 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'YOU UPGRADED TO VIP $newLevel!',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
          ),
        ],
      ),
    );
  }

  // ==================== WITHDRAWAL STEP 1 BANK ACCOUNT REGISTRATION ====================

  void _showAddBankDialog() {
    final holderNameController = TextEditingController();
    final phoneController = TextEditingController();
    final bankNameController = TextEditingController();
    final accountController = TextEditingController();
    final bankFormKey = GlobalKey<FormState>();

    _showCustomCasinoDialog(
      title: 'STEP 1: ADD BANK',
      maxHeight: 310.0,
      maxWidth: 540.0,
      content: Form(
        key: bankFormKey,
        child: Column(
          children: [
            const Text(
              'Enter info to verify your account:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.0, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12.0),
            
            // Row 1: Holder Name & Phone
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: holderNameController,
                    style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: _buildCasinoInputDecoration('Holder Name', Icons.person),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: _buildCasinoInputDecoration('Phone Number', Icons.phone),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      if (!RegExp(r'^\d{10}$').hasMatch(val.trim())) return '10 digits';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            
            // Row 2: Bank Name & Account Number
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: bankNameController,
                    style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: _buildCasinoInputDecoration('Bank Name', Icons.account_balance),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: TextFormField(
                    controller: accountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: _buildCasinoInputDecoration('Account Number', Icons.password),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLargeCasinoButton(
                  text: 'SAVE DETAILS',
                  color: const Color(0xFF00C853),
                  width: 130,
                  onTap: () {
                    if (bankFormKey.currentState!.validate()) {
                      widget.onBankDetailsChanged(
                        true,
                        holderNameController.text.trim(),
                        phoneController.text.trim(),
                        bankNameController.text.trim(),
                        accountController.text.trim(),
                      );
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showWithdrawalFlow();
                      });
                    }
                  },
                ),
                const SizedBox(width: 12.0),
                _buildLargeCasinoButton(
                  text: 'CANCEL',
                  color: const Color(0xFFFF3355),
                  width: 100,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildCasinoInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint.toUpperCase(),
      hintStyle: const TextStyle(fontSize: 9.0, color: Colors.grey, fontWeight: FontWeight.bold),
      prefixIcon: Icon(icon, color: Colors.white70, size: 14),
      filled: true,
      fillColor: const Color(0xFF160E45),
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF322878), width: 1.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
    );
  }

  // ==================== GLOSSY CASINO ACTION BUTTONS ====================

  Widget _buildMiniCasinoButton({required String text, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        SoundManager.playClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildLargeCasinoButton({required String text, required Color color, double width = 120.0, required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        SoundManager.playClick();
        onTap();
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 6.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Helper Widget representing the physical Duolingo 3D button behavior inside the lobby
class _LobbyButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double width;
  final double height;
  final double borderRadius;
  final bool showRedDot;
  final bool isCircle;
  final Widget? customChild;
  final bool showShimmer;

  const _LobbyButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.showRedDot,
    required this.isCircle,
    this.customChild,
    this.showShimmer = false,
  });

  @override
  State<_LobbyButton> createState() => _LobbyButtonState();
}

class _LobbyButtonState extends State<_LobbyButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = widget.color == const Color(0xFF7B1FA2)
        ? widget.color
        : const Color(0xFF3A4142); // Default Figma dark gray

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          SoundManager.playClick();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: _isPressed 
                  ? buttonColor.withValues(alpha: 0.8) 
                  : (_isHovered ? buttonColor.withValues(alpha: 0.9) : buttonColor),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: const Color(0xFF4A5152), width: 1.0),
            ),
            child: widget.customChild ?? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    widget.label.toLowerCase().contains('withdraw')
                        ? 'assets/icons/icon_withdraw.png'
                        : (widget.label.toLowerCase().contains('vault')
                            ? 'assets/icons/icon_vault_pro.png'
                            : 'assets/icons/icon_bet_history.png'),

                    width: 14.0,
                    height: 14.0,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(widget.icon, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
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

// Reusable micro-interaction scale/bounce animation wrapper for buttons
class _Bounceable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _Bounceable({
    required this.child,
    required this.onTap,
  });

  @override
  State<_Bounceable> createState() => _BounceableState();
}

class _BounceableState extends State<_Bounceable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
