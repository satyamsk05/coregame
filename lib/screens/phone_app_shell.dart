import 'package:flutter/material.dart';
import '../widgets/phone_mockup_wrapper.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'lobby_screen.dart';
import 'keno_game_screen.dart';
import 'coin_flip_game_screen.dart';
import 'limbo_game_screen.dart';
import 'dice_game_screen.dart';

class PhoneAppShell extends StatefulWidget {
  const PhoneAppShell({super.key});

  @override
  State<PhoneAppShell> createState() => _PhoneAppShellState();
}

class _PhoneAppShellState extends State<PhoneAppShell> {
  String _currentScreen = 'welcome';

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
  Widget build(BuildContext context) {
    Widget screenWidget;
    switch (_currentScreen) {
      case 'login':
        screenWidget = LoginScreen(
          key: const ValueKey('login'),
          onBackPressed: () => setState(() => _currentScreen = 'welcome'),
        );
        break;
      case 'signup':
        screenWidget = SignupScreen(
          key: const ValueKey('signup'),
          onBackPressed: () => setState(() => _currentScreen = 'welcome'),
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
          onLogoutPressed: () => setState(() => _currentScreen = 'welcome'),
          onPlayGame: (gameName) => setState(() => _currentScreen = gameName),
          onBalanceChanged: (val) => setState(() => _balance = val),
          onVipLevelChanged: (val) => setState(() => _vipLevel = val),
          onTotalDepositedChanged: (val) => setState(() => _totalDeposited = val),
          onSoundToggled: (val) => setState(() => _soundOn = val),
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
      case 'welcome':
      default:
        screenWidget = WelcomeScreen(
          key: const ValueKey('welcome'),
          onLoginPressed: () => setState(() => _currentScreen = 'login'),
          onSignupPressed: () => setState(() => _currentScreen = 'signup'),
          onSkipPressed: () => setState(() => _currentScreen = 'lobby'),
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

