import 'package:flutter/material.dart';
import '../shared/widgets/phone_mockup_wrapper.dart';
import '../utils/sound_manager.dart';

// Auth screens
import '../auth/screens/welcome_screen.dart';
import '../auth/screens/login_screen.dart';
import '../auth/screens/signup_screen.dart';

// Lobby
import 'lobby_screen.dart';

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

  @override
  void initState() {
    super.initState();
    SoundManager.soundOn = _soundOn;
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
          onLogoutPressed: () {
            SoundManager.playClick();
            setState(() => _currentScreen = 'welcome');
          },
          onPlayGame: (gameName) {
            SoundManager.playClick();
            setState(() {
              _loadingGameName = gameName;
              _currentScreen = 'loading';
            });
          },
          onBalanceChanged: (val) => setState(() => _balance = val),
          onVipLevelChanged: (val) => setState(() => _vipLevel = val),
          onTotalDepositedChanged: (val) => setState(() => _totalDeposited = val),
          onSoundToggled: (val) {
            setState(() => _soundOn = val);
            SoundManager.soundOn = val;
            SoundManager.playClick();
          },
          onMusicToggled: (val) => setState(() => _musicOn = val),
          onActiveGatewayChanged: (val) => setState(() => _activeGateway = val),
          onBankDetailsChanged: (isAdded, holder, phone, bank, acc) {
            setState(() {
              _isBankAdded = isAdded;
              _bankHolderName = holder;
              _bankPhoneNumber = phone;
              _bankName = bank;
              _bankAccountNumber = acc;
            });
          },
        );
        break;
      case 'keno':
        screenWidget = KenoGameScreen(
          key: const ValueKey('keno'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: (val) => setState(() => _balance = val),
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'coin_flip':
        screenWidget = CoinFlipGameScreen(
          key: const ValueKey('coin_flip'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: (val) => setState(() => _balance = val),
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'limbo':
        screenWidget = LimboGameScreen(
          key: const ValueKey('limbo'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: (val) => setState(() => _balance = val),
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'dice':
        screenWidget = DiceGameScreen(
          key: const ValueKey('dice'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: (val) => setState(() => _balance = val),
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'roulette':
        screenWidget = RouletteGameScreen(
          key: const ValueKey('roulette'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: (val) => setState(() => _balance = val),
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'mines':
        screenWidget = MinesGameScreen(
          key: const ValueKey('mines'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: (val) => setState(() => _balance = val),
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'hilo':
        screenWidget = HiLoGameScreen(
          key: const ValueKey('hilo'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: (val) => setState(() => _balance = val),
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'seven_up_down':
        screenWidget = SevenUpDownGameScreen(
          key: const ValueKey('seven_up_down'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: (val) => setState(() => _balance = val),
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'andar_bahar':
        screenWidget = AndarBaharGameScreen(
          key: const ValueKey('andar_bahar'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: (val) => setState(() => _balance = val),
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'plinko':
        screenWidget = PlinkoGameScreen(
          key: const ValueKey('plinko'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: (val) => setState(() => _balance = val),
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'crash':
        screenWidget = CrashGameScreen(
          key: const ValueKey('crash'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: (val) => setState(() => _balance = val),
          onBackPressed: () => setState(() => _currentScreen = 'lobby'),
        );
        break;
      case 'twist':
        screenWidget = TwistGameScreen(
          key: const ValueKey('twist'),
          balance: _balance,
          soundOn: _soundOn,
          musicOn: _musicOn,
          onBalanceChanged: (val) => setState(() => _balance = val),
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
