import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/widgets/phone_mockup_wrapper.dart';
import '../utils/sound_manager.dart';

// Auth screens
import '../auth/screens/welcome_screen.dart';
import '../auth/screens/login_screen.dart';
import '../auth/screens/signup_screen.dart';

// Lobby & Shop
import 'lobby_screen.dart';
import 'deposit_screen.dart';

// Shared
import '../shared/widgets/game_loading_screen.dart';

// Games
import '../games/keno/keno_screen.dart';
import '../games/coin_flip/coin_flip_screen.dart';
import '../games/limbo/limbo_screen.dart';
import '../games/dice/dice_screen.dart';
import '../games/roulette/roulette_screen.dart';
import '../games/mines/mines_screen.dart';
import '../games/hilo/hilo_screen.dart';
import '../games/seven_up_down/seven_up_down_screen.dart';
import '../games/andar_bahar/andar_bahar_screen.dart';
import '../games/plinko/plinko_screen.dart';
import '../games/crash/crash_screen.dart';
import '../games/twist/twist_screen.dart';
import '../games/double/double_screen.dart';
import '../games/ring_of_fortune/ring_of_fortune_screen.dart';
import '../games/tower_legend/tower_legend_screen.dart';

class PhoneAppShell extends StatefulWidget {
  const PhoneAppShell({super.key});

  @override
  State<PhoneAppShell> createState() => _PhoneAppShellState();
}

class _PhoneAppShellState extends State<PhoneAppShell> {
  String _currentScreen = 'welcome';
  String _loadingGameName = '';

  // Lifted state variables to share between lobby and games
  double _balance = 17.57;
  int _vipLevel = 1;
  double _totalDeposited = 100.00;
  bool _soundOn = true;
  bool _musicOn = true;
  bool _isBankAdded = true;
  String _bankHolderName = 'SUPER HIT';
  String _bankPhoneNumber = '0917088800480';
  String _bankName = 'KOTAK MAHINDRA BANK';
  String _bankAccountNumber = '6055376770';
  String _activeGateway = 'UmPay';
  String _nickname = 'superhit';
  String _avatarPath = 'assets/userprofile/user7.png';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        _currentScreen = 'lobby';
      }
      _balance = prefs.getDouble('balance') ?? 17.57;
      _vipLevel = prefs.getInt('vipLevel') ?? 1;
      _totalDeposited = prefs.getDouble('totalDeposited') ?? 100.00;
      _soundOn = prefs.getBool('soundOn') ?? true;
      _musicOn = prefs.getBool('musicOn') ?? true;
      _isBankAdded = prefs.getBool('isBankAdded') ?? true;
      _bankHolderName = prefs.getString('bankHolderName') ?? 'SUPER HIT';
      _bankPhoneNumber = prefs.getString('bankPhoneNumber') ?? '0917088800480';
      _bankName = prefs.getString('bankName') ?? 'KOTAK MAHINDRA BANK';
      _bankAccountNumber = prefs.getString('bankAccountNumber') ?? '6055376770';
      _activeGateway = prefs.getString('activeGateway') ?? 'UmPay';
      _nickname = prefs.getString('nickname') ?? 'superhit';
      _avatarPath = prefs.getString('avatarPath') ?? 'assets/userprofile/user7.png';
      
      SoundManager.soundOn = _soundOn;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void _updateBalance(double val) {
    setState(() => _balance = val);
    _saveDouble('balance', val);
  }

  void _updateVipLevel(int val) {
    setState(() => _vipLevel = val);
    _saveInt('vipLevel', val);
  }

  void _updateTotalDeposited(double val) {
    setState(() => _totalDeposited = val);
    _saveDouble('totalDeposited', val);
  }

  void _updateNickname(String val) {
    setState(() => _nickname = val);
    _saveString('nickname', val);
  }

  void _updateAvatarPath(String val) {
    setState(() => _avatarPath = val);
    _saveString('avatarPath', val);
  }

  void _updateActiveGateway(String val) {
    setState(() => _activeGateway = val);
    _saveString('activeGateway', val);
  }

  @override
  Widget build(BuildContext context) {
    Widget screenWidget;
    switch (_currentScreen) {
      case 'login':
        screenWidget = LoginScreen(
          key: const ValueKey('login'),
          onBackPressed: () {
            SoundManager.playClick();
            setState(() => _currentScreen = 'welcome');
          },
          onLoginSuccess: () {
            SoundManager.playClick();
            setState(() => _currentScreen = 'lobby');
            _saveBool('isLoggedIn', true);
          },
        );
        break;
      case 'signup':
        screenWidget = SignupScreen(
          key: const ValueKey('signup'),
          onBackPressed: () {
            SoundManager.playClick();
            setState(() => _currentScreen = 'welcome');
          },
        );
        break;
      case 'lobby':
        screenWidget = LobbyScreen(
          key: const ValueKey('lobby'),
          balance: _balance,
          vipLevel: _vipLevel,
          totalDeposited: _totalDeposited,
          soundOn: _soundOn,
          musicOn: _musicOn,
          isBankAdded: _isBankAdded,
          bankHolderName: _bankHolderName,
          bankPhoneNumber: _bankPhoneNumber,
          bankName: _bankName,
          bankAccountNumber: _bankAccountNumber,
          activeGateway: _activeGateway,
          nickname: _nickname,
          avatarPath: _avatarPath,
          onNicknameChanged: _updateNickname,
          onAvatarChanged: _updateAvatarPath,
          onLogoutPressed: () {
            SoundManager.playClick();
            setState(() => _currentScreen = 'welcome');
            _saveBool('isLoggedIn', false);
          },
          onDepositPressed: () {
            SoundManager.playClick();
            setState(() => _currentScreen = 'deposit');
          },
          onPlayGame: (gameName) {
            SoundManager.playClick();
            setState(() {
              _loadingGameName = gameName;
              _currentScreen = 'loading';
            });
          },
          onBalanceChanged: _updateBalance,
          onVipLevelChanged: _updateVipLevel,
          onTotalDepositedChanged: _updateTotalDeposited,
          onSoundToggled: (val) {
            setState(() => _soundOn = val);
            SoundManager.soundOn = val;
            SoundManager.playClick();
            _saveBool('soundOn', val);
          },
          onMusicToggled: (val) {
            setState(() => _musicOn = val);
            _saveBool('musicOn', val);
          },
          onActiveGatewayChanged: _updateActiveGateway,
          onBankDetailsChanged: (isAdded, holder, phone, bank, acc) {
            setState(() {
              _isBankAdded = isAdded;
              _bankHolderName = holder;
              _bankPhoneNumber = phone;
              _bankName = bank;
              _bankAccountNumber = acc;
            });
            _saveBool('isBankAdded', isAdded);
            _saveString('bankHolderName', holder);
            _saveString('bankPhoneNumber', phone);
            _saveString('bankName', bank);
            _saveString('bankAccountNumber', acc);
          },
        );
        break;
      case 'deposit':
        screenWidget = DepositScreen(
          key: const ValueKey('deposit'),
          balance: _balance,
          totalDeposited: _totalDeposited,
          vipLevel: _vipLevel,
          activeGateway: _activeGateway,
          onBalanceChanged: _updateBalance,
          onTotalDepositedChanged: _updateTotalDeposited,
          onVipLevelChanged: _updateVipLevel,
          onActiveGatewayChanged: _updateActiveGateway,
          onBackPressed: () {
            SoundManager.playClick();
            setState(() => _currentScreen = 'lobby');
          },
        );
        break;
      case 'keno':
        screenWidget = KenoGameScreen(
          key: const ValueKey('keno'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'coin_flip':
        screenWidget = CoinFlipGameScreen(
          key: const ValueKey('coin_flip'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'limbo':
        screenWidget = LimboGameScreen(
          key: const ValueKey('limbo'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'dice':
        screenWidget = DiceGameScreen(
          key: const ValueKey('dice'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'roulette':
        screenWidget = RouletteGameScreen(
          key: const ValueKey('roulette'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
          nickname: _nickname,
          avatarPath: _avatarPath,
        );
        break;
      case 'mines':
        screenWidget = MinesGameScreen(
          key: const ValueKey('mines'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'hilo':
        screenWidget = HiLoGameScreen(
          key: const ValueKey('hilo'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'seven_up_down':
        screenWidget = SevenUpDownGameScreen(
          key: const ValueKey('seven_up_down'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          nickname: _nickname,
          avatarPath: _avatarPath,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'andar_bahar':
        screenWidget = AndarBaharGameScreen(
          key: const ValueKey('andar_bahar'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          nickname: _nickname,
          avatarPath: _avatarPath,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'plinko':
        screenWidget = PlinkoGameScreen(
          key: const ValueKey('plinko'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'crash':
        screenWidget = CrashGameScreen(
          key: const ValueKey('crash'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'twist':
        screenWidget = TwistGameScreen(
          key: const ValueKey('twist'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'double':
        screenWidget = DoubleGameScreen(
          key: const ValueKey('double'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          nickname: _nickname,
          avatarPath: _avatarPath,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'ring_of_fortune':
        screenWidget = RingOfFortuneGameScreen(
          key: const ValueKey('ring_of_fortune'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          nickname: _nickname,
          avatarPath: _avatarPath,
          vipLevel: _vipLevel,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'tower_legend':
        screenWidget = TowerLegendScreen(
          key: const ValueKey('tower_legend'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          nickname: _nickname,
          avatarPath: _avatarPath,
          onBalanceChanged: _updateBalance,
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'loading':
        screenWidget = GameLoadingScreen(
          key: const ValueKey('loading'),
          gameKey: _loadingGameName,
          onLoadingComplete: () {
            setState(() {
              _currentScreen = _loadingGameName;
            });
          },
        );
        break;
      case 'welcome':
      default:
        screenWidget = WelcomeScreen(
          key: const ValueKey('welcome'),
          onLoginPressed: () {
            SoundManager.playClick();
            setState(() => _currentScreen = 'login');
          },
          onSignupPressed: () {
            SoundManager.playClick();
            setState(() => _currentScreen = 'signup');
          },
          onSkipPressed: () {
            SoundManager.playClick();
            setState(() => _currentScreen = 'lobby');
          },
        );
        break;
    }

    return PhoneMockupWrapper(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutQuad,
        switchOutCurve: Curves.easeInQuad,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: screenWidget,
      ),
    );
  }
}
