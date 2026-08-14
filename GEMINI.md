# CORE Game Codebase Blueprint & Rules

This rule file provides a comprehensive explanation of the project's structure, patterns, and state-management conventions. **Any assistant reading this file must follow these rules and conventions when writing, modifying, or analyzing code in this repository.**

---

## 🛠️ Tech Stack & Configurations

- **Framework**: Flutter (Dart SDK `^3.12.2`)
- **UI System**: Material 3 Design
- **Orientation**: Locked to **Landscape** (`landscapeLeft`, `landscapeRight` set in [main.dart](file:///Users/satyamkumar/Desktop/coregame/lib/main.dart)).
- **Typography**: 
  - Retro Gaming Headers: `GoogleFonts.pressStart2p`
  - Readability / Input Fields: `Roboto`
- **Asset Scope**: Assets are loaded from the `assets/` directory (mapped in `pubspec.yaml`).

---

## 📂 Codebase Directory Structure

```
coregame/
├── lib/
│   ├── main.dart                      # App entry point, orientation lock, Material Theme configuration.
│   ├── screens/
│   │   ├── phone_app_shell.dart       # Core Router & Stateful Hub (holds lifted states).
│   │   ├── welcome_screen.dart        # Launch screen (Login / Sign Up / Skip buttons).
│   │   ├── login_screen.dart          # Login form.
│   │   ├── signup_screen.dart         # Sign up form.
│   │   ├── lobby_screen.dart          # Main lobby with tabs, settings, profile, and game menu.
│   │   ├── coin_flip_game_screen.dart # Coin Flip game screen.
│   │   ├── dice_game_screen.dart      # Dice rolling game screen.
│   │   ├── keno_game_screen.dart      # Keno numbers matching game screen.
│   │   └── limbo_game_screen.dart     # Limbo multiplier game screen.
│   └── widgets/
│       ├── animated_character.dart    # Custom character animations.
│       ├── animated_game_background.dart # Dynamic animated backgrounds for games.
│       ├── game_button.dart           # Custom gaming-styled button.
│       ├── phone_mockup_wrapper.dart  # Desktop browser chassis wrapper.
│       └── swipe_slider.dart          # Custom swipe-to-activate slider.
```

---

## 🔄 Core Architecture & Patterns

### 1. State Lifting & Syncing
To prevent state desynchronization across the app, critical user states are lifted to the parent [PhoneAppShell](file:///Users/satyamkumar/Desktop/coregame/lib/screens/phone_app_shell.dart):
- **User Balance**: `_balance` (e.g. 17.57)
- **VIP Level & Deposited Total**: `_vipLevel`, `_totalDeposited`
- **Volume Settings**: `_soundOn`, `_musicOn`
- **Linked Bank Details**: `_isBankAdded`, `_bankHolderName`, `_bankPhoneNumber`, `_bankName`, `_bankAccountNumber`
- **Payment Configs**: `_activeGateway`

**Rule**: All game screens and sub-screens MUST receive these state variables as constructor parameters and modify them via callbacks (e.g., `onBalanceChanged(newBalance)` or `onBankDetailsChanged(...)`). Do NOT instantiate local duplicates of these states in individual screens.

### 2. Screen Routing
Routing is managed statefully inside `_PhoneAppShellState` using a `_currentScreen` string:
- `'welcome'` - Entry Screen
- `'login'` - Authentication (Login)
- `'signup'` - Authentication (Register)
- `'lobby'` - Game selection list and settings
- `'keno'`, `'coin_flip'`, `'limbo'`, `'dice'` - Dedicated game screens

Transitions between screens are handled smoothly by `AnimatedSwitcher` using custom fade and slide transitions.

### 3. Responsive Chassis Design
The entire app layout is wrapped inside [PhoneMockupWrapper](file:///Users/satyamkumar/Desktop/coregame/lib/widgets/phone_mockup_wrapper.dart).
- **Desktop/Web Viewports**: Displays a beautiful landscape phone chassis bezel around the application UI to emulate a mobile app look.
- **Mobile Viewports / Small Windows**: Automatically detects screen sizes (`deviceWidth < 900.0` or `deviceHeight < 500.0`) or mobile platforms (iOS/Android) and bypasses the chassis wrapper to render full screen.

---

## ⚠️ Key Development Guidelines

1. **Keep it Landscape**: Always design screens keeping landscape ratios in mind (standard screen size target is `844 x 390`).
2. **Sync the Balance**: When a user wins or places a bet in any game (Dice, Keno, Limbo, Coin Flip), invoke `onBalanceChanged` immediately so the lobby balance stays perfectly in sync.
3. **Use Mockup-Friendly Layouts**: Keep pages flexible and wrapped properly so they fit nicely within the landscape chassis viewport without overflowing.
4. **Follow Theme Styling**: Use Retro retro-gaming style widgets for game controls and standard clean modern inputs for account management fields.
