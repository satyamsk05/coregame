import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_game_background.dart';
import '../widgets/game_button.dart';
import '../widgets/swipe_slider.dart';
import '../utils/sound_manager.dart';

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
  final Function(String) onPlayGame;
  final ValueChanged<double> onBalanceChanged;
  final ValueChanged<int> onVipLevelChanged;
  final ValueChanged<double> onTotalDepositedChanged;
  final ValueChanged<bool> onSoundToggled;
  final ValueChanged<bool> onMusicToggled;
  final ValueChanged<String> onActiveGatewayChanged;
  final Function(bool, String, String, String, String) onBankDetailsChanged;

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
    required this.onPlayGame,
    required this.onBalanceChanged,
    required this.onVipLevelChanged,
    required this.onTotalDepositedChanged,
    required this.onSoundToggled,
    required this.onMusicToggled,
    required this.onActiveGatewayChanged,
    required this.onBankDetailsChanged,
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

  String _selectedCategory = 'All';

  // Games list metadata matching the files in "assets/"
  final List<Map<String, String>> _games = [
    {
      'title': 'Keno 12',
      'image': 'assets/file_00000000563482119a9594084f1f194c.png',
    },
    {
      'title': 'Coin Flip',
      'image': 'assets/file_0000000004908211b393b98d4a502080.png',
    },
    {
      'title': 'Limbo Rocket',
      'image': 'assets/file_000000004f48821189f8d507b9ab2857.png',
    },
    {
      'title': 'Classic Dice',
      'image': 'assets/file_0000000075348208b1ffe9f8fcf2385b.png',
    },
    {
      'title': 'Mines',
      'image': 'assets/file_00000000eb388211a7196e8362206f0c.png',
    },
    {
      'title': 'Roulette Rush',
      'image': 'assets/file_0000000043b882118581e6c2651cc980.png',
    },
    {
      'title': 'Crash',
      'image': 'assets/file_0000000059c88211addea865bde5ea3d.png',
    },
    {
      'title': 'Plinko',
      'image': 'assets/file_00000000be94821189dc5d6696cf5925.png',
    },
    {
      'title': '7 Up Down',
      'image': 'assets/file_00000000bf5482119cfaa6800c38c2c1.png',
    },
    {
      'title': 'HiLo',
      'image': 'assets/hilo_logo.png',
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
    double borderRadius = 16.0,
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
    const backgroundColor = Color(0xFFEBEBEB);

    final bool isMobilePlatform = defaultTargetPlatform == TargetPlatform.android ||
                                  defaultTargetPlatform == TargetPlatform.iOS;
    final double paddingHorizontal = isMobilePlatform ? 32.0 : 16.0;
    final double paddingVertical = isMobilePlatform ? 12.0 : 16.0;

    final double screenHeight = MediaQuery.of(context).size.height;
    // Calculate the best height for the game cards dynamically to prevent any overflow on small devices
    final double gridHeight = (screenHeight - (paddingVertical * 2) - 80.0).clamp(180.0, 290.0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedGameBackground(
        showStars: false,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: paddingHorizontal,
              vertical: paddingVertical,
            ),
            child: Stack(
              children: [
                // ==================== TOP BAR ROWS ====================
                
                // 1. Profile Avatar (Top-Left) - 20% smaller (43x43)
                Positioned(
                  top: 4.0,
                  left: 8.0,
                  child: _buildLobbyButton(
                    label: 'profile',
                    icon: Icons.person,
                    color: const Color(0xFF90A4AE), // Cool slate gray
                    isCircle: true,
                    width: 43.0,
                    height: 43.0,
                    onTap: () {
                      _showProfileDialog();
                    },
                    customChild: Container(
                      padding: const EdgeInsets.all(4.0),
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        child: Icon(Icons.face, size: 22),
                      ),
                    ),
                  ),
                ),

                // 2. Deposit & Balance Button (Top-Center) - 20% smaller (144x38)
                Positioned(
                  top: 4.0,
                  left: 0.0,
                  right: 0.0,
                  child: Center(
                    child: _buildLobbyButton(
                      label: 'DEPOSIT',
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFFFFB300), // Gold/Orange
                      width: 144.0,
                      height: 38.0,
                      showShimmer: true,
                      onTap: () {
                        _showDepositDialog();
                      },
                      customChild: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 13),
                          const SizedBox(width: 6.0),
                          Text(
                            '\$${_balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Settings Button (Top-Right) - 20% smaller (104x38)
                Positioned(
                  top: 4.0,
                  right: 8.0,
                  child: _buildLobbyButton(
                    label: 'SETTING',
                    icon: Icons.settings,
                    color: const Color(0xFF0288D1), // Bright Blue
                    width: 104.0,
                    height: 38.0,
                    onTap: () {
                      _showSettingsDialog();
                    },
                  ),
                ),

                // ==================== BOTTOM BAR ROWS ====================

                // 4. Row of 4 Action Buttons (Bottom-Left) - 20% smaller sizes
                Positioned(
                  bottom: 4.0,
                  left: 8.0,
                  child: Row(
                    children: [
                      // Button 1: Withdrawal (92x38)
                      _buildLobbyButton(
                        label: 'Withdrawal',
                        icon: Icons.arrow_downward,
                        color: const Color(0xFFFF5252), // Coral red
                        width: 92.0,
                        height: 38.0,
                        onTap: () {
                          _showWithdrawalFlow();
                        },
                      ),
                      const SizedBox(width: 8.0),
                      // Button 2: Quests (80x38)
                      _buildLobbyButton(
                        label: 'Quests',
                        icon: Icons.emoji_events,
                        color: const Color(0xFFFF8F00), // Warm Amber
                        width: 80.0,
                        height: 38.0,
                        onTap: () {
                          _showInfoDialog('QUESTS', 'Complete daily levels to double your balance!');
                        },
                      ),
                      const SizedBox(width: 8.0),
                      // Button 3: Bet History (92x38)
                      _buildLobbyButton(
                        label: 'Bet History',
                        icon: Icons.history,
                        color: const Color(0xFF78909C), // Steel grey
                        width: 92.0,
                        height: 38.0,
                        onTap: () {
                          _showInfoDialog('BET HISTORY', 'No recent bet history. Start a game to see records!');
                        },
                      ),
                      const SizedBox(width: 8.0),
                      // Button 4: Mailbox (80x38)
                      _buildLobbyButton(
                        label: 'Mailbox',
                        icon: Icons.mail,
                        color: const Color(0xFF00C853), // Green
                        width: 80.0,
                        height: 38.0,
                        showRedDot: true,
                        onTap: () {
                          _showMailDialog();
                        },
                      ),
                    ],
                  ),
                ),

                // 5. VIP CLOB Button (Bottom-Right) - 20% smaller (72x64)
                Positioned(
                  bottom: 4.0,
                  right: 8.0,
                  child: _buildLobbyButton(
                    label: 'VIP CLOB',
                    icon: Icons.star,
                    color: const Color(0xFF7B1FA2), // Premium Purple
                    width: 72.0,
                    height: 64.0,
                    borderRadius: 16.0,
                    onTap: () {
                      _showVipDialog();
                    },
                    customChild: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _vipLevel > 0 ? Icons.workspace_premium : Icons.military_tech,
                          color: const Color(0xFFFFD700),
                          size: 22
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'VIP CLOB',
                          style: GoogleFonts.alfaSlabOne(
                            textStyle: TextStyle(
                              fontSize: _vipLevel > 0 ? 8.5 : 8.0,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (_vipLevel > 0)
                          Text(
                            'LEVEL $_vipLevel',
                            style: const TextStyle(
                              fontSize: 7.5,
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 5.5 Category Sidebar (Screenshot 1)
                Positioned(
                  top: 50.0,
                  bottom: 48.0,
                  left: 8.0,
                  width: 135.0,
                  child: Center(
                    child: SizedBox(
                      height: gridHeight,
                      child: _buildCategorySidebar(),
                    ),
                  ),
                ),

                // 6. Horizontal Game Cards List (2x2 Grid Layout)
                Positioned(
                  top: 50.0,
                  bottom: 48.0,
                  left: 150.0,
                  right: 8.0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: gridHeight,
                      child: Builder(
                        builder: (context) {
                          final List<Map<String, String>> filteredGames = _games.where((game) {
                            if (_selectedCategory == 'All') return true;
                            if (_selectedCategory == 'Hot') {
                              return ['Keno 12', 'Coin Flip', 'Limbo Rocket', 'Classic Dice', 'Mines'].contains(game['title']);
                            }
                            if (_selectedCategory == 'Poker') {
                              return ['HiLo'].contains(game['title']);
                            }
                            if (_selectedCategory == 'Slots') {
                              return ['Roulette Rush', 'Crash', 'Plinko', '7 Up Down', 'Fruit Slash'].contains(game['title']);
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
                                    } else if (game['title'] == 'Roulette Rush') {
                                      widget.onPlayGame('roulette');
                                    } else if (game['title'] == 'Plinko') {
                                      widget.onPlayGame('plinko');
                                    } else if (game['title'] == 'Crash') {
                                      widget.onPlayGame('crash');
                                    } else {
                                      _showInfoDialog(game['title']!, 'Launching ${game['title']}! Place your bets to win big.');
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF160E45),
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(color: const Color(0xFF9E84FF), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
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
      width: 135.0,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0736).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF9E84FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Sort Header (glowing card suit theme)
          _buildSortHeader(),
          
          const Divider(color: Color(0xFF322878), height: 1.0),
          
          // 2. Tabs List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildSidebarTab(
                    id: 'Hot',
                    label: 'Hot Game',
                    icon: Icons.local_fire_department,
                    iconColor: Colors.amber,
                  ),
                  const SizedBox(height: 8.0),
                  _buildSidebarTab(
                    id: 'Poker',
                    label: 'Poker Game',
                    icon: Icons.style,
                    iconColor: Colors.red[300]!,
                  ),
                  const SizedBox(height: 8.0),
                  _buildSidebarTab(
                    id: 'Slots',
                    label: 'Slots Game',
                    icon: Icons.casino,
                    iconColor: Colors.cyan[300]!,
                  ),
                  const SizedBox(height: 8.0),
                  _buildSidebarTab(
                    id: 'All',
                    label: 'All Game',
                    icon: Icons.grid_view,
                    iconColor: Colors.purple[300]!,
                  ),
                ],
              ),
            ),
          ),
        ],
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
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 38.0,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF8E24AA), Color(0xFFD81B60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFF160E45).withOpacity(0.4),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.4) : Colors.transparent,
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : iconColor,
              size: 16.0,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.5,
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
            gradient: const LinearGradient(
              colors: [Color(0xFF2C1B6E), Color(0xFF13083B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF9E84FF), width: 2.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 15.0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF3F2B96), width: 1.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.alfaSlabOne(
                        textStyle: const TextStyle(
                          fontSize: 16.0,
                          color: Color(0xFFFFD700), // Gold Text
                          letterSpacing: 1.0,
                          shadows: [
                            Shadow(color: Colors.black, offset: Offset(1.5, 1.5), blurRadius: 2.0),
                          ],
                        ),
                      ),
                    ),
                    // Close button tab (matching red X corner layout)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(5.0),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3355),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14.0),
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
        color: const Color(0xFF160E45),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFF322878), width: 1.5),
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
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 10.0),
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
                              border: Border.all(color: const Color(0xFFFF33CC), width: 2.0),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF33CC).withOpacity(0.3),
                                  blurRadius: 8.0,
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              radius: 36,
                              backgroundColor: Color(0xFF2C1B6E),
                              child: Icon(Icons.face, size: 52, color: Colors.white),
                            ),
                          ),
                          // VIP Level Ribbon
                          Positioned(
                            bottom: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3355),
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: const Color(0xFFFFD700), width: 1.0),
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
                        color: const Color(0xFF0288D1),
                        onTap: () {},
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
                      _buildProfileDetailRow('NICKNAME:', 'superhit'),
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
                            style: TextStyle(color: Color(0xFF8C9EFF), fontWeight: FontWeight.bold, fontSize: 12.0),
                          ),
                          _buildCasinoBalanceCapsule(
                            _balance, 
                            showAddButton: true,
                            onAddTap: () {
                              Navigator.pop(context);
                              _showDepositDialog();
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
              color: const Color(0xFFE040FB),
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

  Widget _buildProfileDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8C9EFF),
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

  // ==================== DIALOG 2: SHOP / DEPOSIT COINS (Screenshot 1) ====================

  void _showDepositDialog() {
    final depositController = TextEditingController(text: '100');
    final formKey = GlobalKey<FormState>();

    // Grid details for the 9 packages from screenshot 1
    final List<Map<String, dynamic>> packages = [
      {'label': '100', 'price': 100, 'extra': ''},
      {'label': '200', 'price': 200, 'extra': ''},
      {'label': '300', 'price': 300, 'extra': ''},
      {'label': '510', 'price': 500, 'extra': 'Extra +2%'},
      {'label': '1020', 'price': 1000, 'extra': 'Extra +2%'},
      {'label': '2040', 'price': 2000, 'extra': 'Extra +2%'},
      {'label': '5150', 'price': 5000, 'extra': 'Extra +3%'},
      {'label': '8240', 'price': 8000, 'extra': 'Extra +3%'},
      {'label': '10300', 'price': 10000, 'extra': 'Extra +3%'},
    ];

    _showCustomCasinoDialog(
      title: 'SHOP',
      maxHeight: 335.0,
      maxWidth: 630.0,
      content: StatefulBuilder(
        builder: (context, setShopState) => Form(
          key: formKey,
          child: Row(
            children: [
              // 1. Sidebar Nav (Gateways)
              Container(
                width: 95.0,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFF2C1B6E), width: 1.5),
                  ),
                ),
                padding: const EdgeInsets.only(right: 8.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: ['UmPay', 'wddpay', 'CloudsPay', 'ZipPay'].map((gateway) {
                      final bool isActive = _activeGateway == gateway;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () {
                            setShopState(() {
                              widget.onActiveGatewayChanged(gateway);
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? const LinearGradient(colors: [Color(0xFFE040FB), Color(0xFF00E5FF)])
                                  : null,
                              color: isActive ? null : const Color(0xFF160E45),
                              borderRadius: BorderRadius.circular(15.0),
                              border: Border.all(
                                color: isActive ? const Color(0xFF00E5FF) : const Color(0xFF322878),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              gateway,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.0,
                                shadows: isActive
                                    ? [const Shadow(color: Colors.black, blurRadius: 2.0)]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),

              // 2. Right panel: Details & packages grid
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top warning label matching screenshot
                    const Text(
                      'If you can\'t recharge, choose another channel, or try several times to successfully recharge.',
                      style: TextStyle(color: Color(0xFFFFD54F), fontSize: 8.5, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6.0),
                    
                    // Input & formula bar
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 34.0,
                            child: TextFormField(
                              controller: depositController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: 'Enter amount...',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 10.0),
                                filled: true,
                                fillColor: const Color(0xFF160E45),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF322878), width: 1.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        // Formula indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF160E45),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 12.0),
                              const SizedBox(width: 2.0),
                              Text(
                                ' ${depositController.text.isEmpty ? "0" : depositController.text} × 100% = ${depositController.text.isEmpty ? "0" : depositController.text}',
                                style: const TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        // Any deposit button
                        _buildMiniCasinoButton(
                          text: 'Any Deposit',
                          color: const Color(0xFFFF9100),
                          onTap: () {
                            if (formKey.currentState!.validate()) {
                              final amount = double.tryParse(depositController.text) ?? 100;
                              _executeDeposit(amount);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),

                    // Grid layout of packages (Screenshot 1)
                    Expanded(
                      child: GridView.builder(
                        itemCount: packages.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 6.0,
                          mainAxisSpacing: 6.0,
                          childAspectRatio: 0.82,
                        ),
                        itemBuilder: (context, index) {
                          final pack = packages[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF160E45),
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: const Color(0xFF2C1B6E), width: 1.5),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Coin value tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1A237E),
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                                      ),
                                      child: Text(
                                        pack['label'],
                                        style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 9.0, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    // Stack of Gold coins graphic
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.monetization_on,
                                          color: const Color(0xFFFFD700),
                                          size: index > 5 ? 18.0 : 14.0,
                                        ),
                                        if (index > 3)
                                          Icon(
                                            Icons.monetization_on,
                                            color: const Color(0xFFFFD700),
                                            size: index > 5 ? 16.0 : 12.0,
                                          ),
                                      ],
                                    ),
                                    // Buy button
                                    GestureDetector(
                                      onTap: () {
                                        setShopState(() {
                                          depositController.text = pack['price'].toString();
                                        });
                                        _executeDeposit(pack['price'].toDouble());
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF64DD17)]),
                                          borderRadius: BorderRadius.circular(6.0),
                                        ),
                                        child: Text(
                                          '₹${pack['price']}',
                                          style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Extra bonus tag badge
                                if (pack['extra'].isNotEmpty)
                                  Positioned(
                                    top: -4,
                                    left: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF9100),
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      child: Text(
                                        pack['extra'],
                                        style: const TextStyle(color: Colors.white, fontSize: 6.0, fontWeight: FontWeight.bold),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _executeDeposit(double amount) {
    widget.onBalanceChanged(widget.balance + amount);
    Navigator.pop(context);
    _checkVipUpgrade(amount);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF00C853),
        content: Text(
          'Recharged ₹${amount.toStringAsFixed(2)} Successfully!',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  // ==================== DIALOG 3: WITHDRAWALS POPUP (Screenshot 3) ====================

  void _showWithdrawalFlow() {
    if (!_isBankAdded) {
      _showAddBankDialog();
      return;
    }

    final withdrawController = TextEditingController(text: '10');
    final withdrawFormKey = GlobalKey<FormState>();

    _showCustomCasinoDialog(
      title: 'WITHDRAWALS',
      maxHeight: 330.0,
      maxWidth: 620.0,
      content: StatefulBuilder(
        builder: (context, setWithdrawState) => Form(
          key: withdrawFormKey,
          child: Row(
            children: [
              // 1. Sidebar Nav
              Container(
                width: 100.0,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFF3F2B96), width: 1.5),
                  ),
                ),
                padding: const EdgeInsets.only(right: 8.0),
                child: Column(
                  children: [
                    // IMPS Tab (Selected)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0288D1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                            blurRadius: 8.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance, color: Colors.white, size: 12.0),
                          SizedBox(width: 4.0),
                          Text(
                            'IMPS',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    // Records Tab (Unselected)
                    InkWell(
                      onTap: () {
                        _showInfoDialog('RECORDS', 'No recent withdrawal records.');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF160E45),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFF3F2B96), width: 1.0),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, color: Colors.grey, size: 12.0),
                            SizedBox(width: 4.0),
                            Text(
                              'Records',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),

              // 2. Right withdrawal fields
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Balance Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Balance:',
                          style: TextStyle(color: Color(0xFF8C9EFF), fontWeight: FontWeight.bold, fontSize: 11.0),
                        ),
                        _buildCasinoBalanceCapsule(_balance),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    // Withdraw amount row with MAX button
                    Row(
                      children: [
                        const Text(
                          'Withdrawable: ',
                          style: TextStyle(color: Color(0xFF8C9EFF), fontWeight: FontWeight.bold, fontSize: 11.0),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: SizedBox(
                            height: 36.0,
                            child: TextFormField(
                              controller: withdrawController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: 'Must be an integer',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 10.0),
                                filled: true,
                                fillColor: const Color(0xFF0F0730),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF3F2B96), width: 1.2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        GestureDetector(
                          onTap: () {
                            setWithdrawState(() {
                              withdrawController.text = _balance.toInt().toString();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9100),
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFFB26A00),
                                  offset: Offset(0, 2.5),
                                )
                              ],
                            ),
                            child: Text(
                              'MAX',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.0,
                                fontFamily: GoogleFonts.alfaSlabOne().fontFamily,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    // Wager Progress star bar indicator
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 16.0),
                        const SizedBox(width: 6.0),
                        Expanded(
                          child: Container(
                            height: 10.0,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0730),
                              borderRadius: BorderRadius.circular(5.0),
                              border: Border.all(color: const Color(0xFF3F2B96), width: 1.0),
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.05, // Subtle active progress indicator
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFE040FB), Color(0xFF00E5FF)],
                                        ),
                                        borderRadius: BorderRadius.circular(5.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        const Text(
                          '0.0%',
                          style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    // Bank Account Info gradient card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF241A63), Color(0xFF0F0730)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFF3B2E92), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance, color: Color(0xFF00E5FF), size: 14.0),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  'Withdraw Via: $_bankName',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          Row(
                            children: [
                              const Icon(Icons.credit_card, color: Color(0xFFFF9100), size: 14.0),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  'My Account: $_bankAccountNumber',
                                  style: const TextStyle(
                                    color: Color(0xFFFFB300),
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Bottom Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
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
                              'Withdrawal of ₹${withdrawVal.toStringAsFixed(0)} initiated to Kotak Bank!'
                            );
                          },
                          child: Container(
                            width: 140.0,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9100),
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFFB26A00),
                                  offset: Offset(0, 3.0),
                                )
                              ],
                            ),
                            child: Text(
                              'WITHDRAW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.0,
                                fontFamily: GoogleFonts.alfaSlabOne().fontFamily,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.3), width: 1.0),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, color: Color(0xFFFF5252), size: 12.0),
                              SizedBox(width: 4.0),
                              Text(
                                'REMAINING WAGER: 93.81',
                                style: TextStyle(
                                  color: Color(0xFFFF5252),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    // Disclaimer footer
                    const Text(
                      'Coins withdrawal range 100~100K, you should keep 0+ coins',
                      style: TextStyle(color: Colors.grey, fontSize: 8.0),
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
                    color: const Color(0xFF160E45),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: const Color(0xFF2C1B6E), width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline, color: Color(0xFF00E5FF), size: 24.0),
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
                color: const Color(0xFFE040FB),
                width: 140,
                onTap: () {
                  Navigator.pop(context);
                  _showInfoDialog('MAILBOX', 'All read mails deleted successfully.');
                },
              ),
              _buildLargeCasinoButton(
                text: 'CLAIM ALL',
                color: const Color(0xFFFF9100),
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
                style: GoogleFonts.alfaSlabOne(textStyle: const TextStyle(color: Colors.white, fontSize: 15.0)),
              ),
              const Spacer(),
              // Info banner notes from Screenshot 5
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF160E45),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: const Color(0xFF3F2B96), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.date_range, color: Color(0xFF00E5FF), size: 10.0),
                        const SizedBox(width: 4.0),
                        const Text(
                          'Weekly Bonus - (Every Monday 8am)',
                          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 8.0, fontWeight: FontWeight.bold),
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
                style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w900, fontSize: 12.0),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Container(
                  height: 14.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF160E45),
                    borderRadius: BorderRadius.circular(7.0),
                    border: Border.all(color: const Color(0xFF322878), width: 1.0),
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
                              gradient: const LinearGradient(colors: [Color(0xFFE040FB), Color(0xFF00E5FF)]),
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
                  iconColor: const Color(0xFFE040FB), // Magenta
                ),
                const SizedBox(width: 8.0),
                _buildVipBenefitCard(
                  title: 'MONTHLY REWARD',
                  reward: '70',
                  actionText: 'RECEIVE',
                  isReceived: false,
                  icon: Icons.savings,
                  iconColor: const Color(0xFFFF9100), // Amber orange
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF241A63), Color(0xFF0F0730)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFF3B2E92), width: 1.5),
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
              style: const TextStyle(color: Color(0xFF8C9EFF), fontSize: 7.5, fontWeight: FontWeight.bold),
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
                    fontFamily: GoogleFonts.alfaSlabOne().fontFamily,
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
                  color: isReceived ? const Color(0xFF5E5E6E) : const Color(0xFFFF9100),
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: isReceived
                      ? []
                      : [
                          const BoxShadow(
                            color: Color(0xFFB26A00),
                            offset: Offset(0, 3.0),
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
                color: const Color(0xFF0288D1),
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
            style: GoogleFonts.alfaSlabOne(fontSize: 16.0, color: const Color(0xFF00C853)),
          ),
          const SizedBox(height: 6.0),
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
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.showShimmer) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Color _getDarkerColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    final double newValue = (hsv.value - 0.16).clamp(0.0, 1.0);
    final double newSaturation = (hsv.saturation + 0.08).clamp(0.0, 1.0);
    return hsv.withValue(newValue).withSaturation(newSaturation).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final Color topColor = widget.color;
    final Color bottomColor = _getDarkerColor(topColor);

    final double shadowHeight = 4.0;
    final double offsetTop = _isPressed ? shadowHeight : 0.0;

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
        child: SizedBox(
          width: widget.width,
          height: widget.height + shadowHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Bottom Shadow Layer
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: widget.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: bottomColor,
                    shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: widget.isCircle ? null : BorderRadius.circular(widget.borderRadius),
                  ),
                ),
              ),

              // 2. Interactive Top Layer
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                left: 0,
                right: 0,
                top: offsetTop,
                height: widget.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isHovered 
                        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.12), topColor) 
                        : topColor,
                    shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: widget.isCircle ? null : BorderRadius.circular(widget.borderRadius),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Shimmer sheen overlay if enabled
                      if (widget.showShimmer)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              final double offset = -2.0 + (_shimmerController.value * 4.0);
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(offset, -1.0),
                                    end: Alignment(offset + 1.5, 1.0),
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.28),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      // Button contents (icon + label)
                      Positioned.fill(
                        child: Center(
                          child: widget.customChild ?? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(widget.icon, color: Colors.white, size: 13),
                              const SizedBox(width: 5.0),
                              Text(
                                widget.label.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
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

              // 3. Optional Red Notification Dot Badge
              if (widget.showRedDot)
                Positioned(
                  top: offsetTop - 2.0,
                  right: -2.0,
                  child: Container(
                    width: 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.5),
                          blurRadius: 4.0,
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
}
