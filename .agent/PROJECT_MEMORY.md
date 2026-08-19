# Project Memory - Casino Game Project

This document serves as the persistent source of truth for the casino game application, documenting its architecture, active codebase structure, design guidelines, assets, and key implementation details.

---

## 1. Core Architecture & Navigation

*   **Platform & Layout Constraint**: The application is designed for **mobile landscape gameplay** (locked to `landscapeLeft` and `landscapeRight` in [main.dart](file:///Users/satyamkumar/Desktop/coregame/lib/main.dart)).
*   **Viewport Shell Mockup**: On desktop/web, the application is wrapped inside [PhoneMockupWrapper](file:///Users/satyamkumar/Desktop/coregame/lib/shared/widgets/phone_mockup_wrapper.dart), providing a bezel and frame. If run on a mobile device or a small window (width < 900, height < 500), it automatically bypasses the mockup frame to render fullscreen.
*   **Navigation & State Management**: 
    *   [PhoneAppShell](file:///Users/satyamkumar/Desktop/coregame/lib/screens/phone_app_shell.dart) acts as the central router and lifts all global states:
        *   `balance` (currency double)
        *   `vipLevel` (integer 1-8 based on deposit thresholds)
        *   `totalDeposited` (double tracking total player payments)
        *   `soundOn` / `musicOn` (audio settings)
        *   `bankDetails` (holder name, account number, phone, bank name for withdrawal)
        *   `activeGateway` (deposit gateways like UmPay, etc.)
    *   State updates are passed down through parameters and modified back via callback functions (e.g., `onBalanceChanged`, `onBackPressed`).
    *   Transitions use a sliding fade animation switch (`AnimatedSwitcher`).

---

## 2. Active Directory Structure vs. Legacy Duplicates

A key characteristic of this repository is the coexistence of active production code folders and duplicate/legacy folders. Developers must edit the correct files.

### 2.1. Active Files (Production)
*   **App Core & Router**:
    *   [lib/main.dart](file:///Users/satyamkumar/Desktop/coregame/lib/main.dart) - Entry point.
    *   [lib/screens/phone_app_shell.dart](file:///Users/satyamkumar/Desktop/coregame/lib/screens/phone_app_shell.dart) - State parent & page router.
    *   [lib/screens/lobby_screen.dart](file:///Users/satyamkumar/Desktop/coregame/lib/screens/lobby_screen.dart) - Dashboard containing Deposit, Withdraw, VIP status panels, Categories list, and Game grid launcher.
*   **Auth Pages**:
    *   [lib/auth/screens/welcome_screen.dart](file:///Users/satyamkumar/Desktop/coregame/lib/auth/screens/welcome_screen.dart) (Full screen background video play)
    *   [lib/auth/screens/login_screen.dart](file:///Users/satyamkumar/Desktop/coregame/lib/auth/screens/login_screen.dart)
    *   [lib/auth/screens/signup_screen.dart](file:///Users/satyamkumar/Desktop/coregame/lib/auth/screens/signup_screen.dart)
*   **Shared Components**:
    *   [lib/shared/widgets/](file:///Users/satyamkumar/Desktop/coregame/lib/shared/widgets/) - Houses core UI assets (e.g., `game_button.dart`, `animated_character.dart`, `phone_mockup_wrapper.dart`, `win_overlay_card.dart`, `win_lose_toast.dart`).
*   **Audio Helpers**:
    *   [lib/utils/sound_manager.dart](file:///Users/satyamkumar/Desktop/coregame/lib/utils/sound_manager.dart) - Core sounds API.
    *   [lib/utils/sound_helper.dart](file:///Users/satyamkumar/Desktop/coregame/lib/utils/sound_helper.dart) - Implements conditional compilation to direct sound methods to either web (Web Audio API) or mobile (system sounds / haptic feedback).
*   **Active Games**:
    *   Located under [lib/games/](file:///Users/satyamkumar/Desktop/coregame/lib/games/). Each game is defined in its respective subdirectory (e.g. `lib/games/keno/keno_screen.dart`).
    *   *Andar Bahar* is modularized: [lib/games/andar_bahar/](file:///Users/satyamkumar/Desktop/coregame/lib/games/andar_bahar/) contains widgets (`bet_panels.dart`, `card_widgets.dart`, etc.) and models (`playing_card.dart`). All other games contain a single monolithic `_screen.dart` file (e.g., `limbo_screen.dart`).

### 2.2. Legacy / Unused Duplicates
Do not modify these files unless requested, as they are not imported by the main router/views:
*   `lib/screens/<game>_game_screen.dart` (Monolithic copies of game screens)
*   `lib/screens/welcome_screen.dart`, `login_screen.dart`, `signup_screen.dart` (Unused auth screens)
*   `lib/widgets/` (Unused copy of `lib/shared/widgets/`)

---

## 3. The 12 Active Games

1.  **Keno 12** (`keno`): Grid matrix card select & draw numbers game.
2.  **Coin Flip** (`coin_flip`): Simple coin flip betting game with custom animations.
3.  **Limbo Rocket** (`limbo`): Multiplier target prediction crash style game.
4.  **Classic Dice** (`dice`): Target multiplier roll under/over game.
5.  **Mines** (`mines`): Mine avoidance matrix tile reveal game.
6.  **Roulette Rush** (`roulette`): French wheel styling betting dashboard.
7.  **Crash** (`crash`): Exponential multiplier rocket climb / crash game.
8.  **Plinko** (`plinko`): Peg board drop physics game.
9.  **7 Up Down** (`seven_up_down`): Sum of two dice betting game.
10. **HiLo** (`hilo`): Guess higher/lower next playing card game.
11. **Andar Bahar** (`andar_bahar`): Standard Indian table/cards matching game (fully modular layout).
12. **Twist** (`twist`): Custom slot-machine card reels game.
*Note: **Fruit Slash** is visible in the lobby as a mocked category option but invokes a placeholder info popup instead of a game launch.*

---

## 4. Design Language & Tokens

*   **Retro UI Vibe**: Uses standard Material 3 styles mixed with retro typography.
*   **Typography**:
    *   Pixel/Retro Headers: `GoogleFonts.pressStart2pTextTheme`
    *   Input Fields & Readable Body text: Overridden with `Roboto` (bold, sans-serif) to ensure legible input states.
*   **Color Palette**:
    *   Primary: `0xFF00C853` (Vibrant green seed)
    *   Secondary: `0xFFFF5252` (Red accent)
    *   Mockup Canvas Background: `0xFF161618` (Dark matte charcoal)
    *   App Viewport Background: `0xFFEBEBEB` (Light background) or custom dark backgrounds for specific games.
*   **Interactive Elements**: Standardized Duolingo-style 3D buttons (using 3D bottom bevel borders and vertical offset push animations) are declared inside [game_button.dart](file:///Users/satyamkumar/Desktop/coregame/lib/shared/widgets/game_button.dart).
*   **Game Loading & Login Screens**: Styled as a forest night theme with a linear gradient sky, drifting stars (`_StarfieldPainter` / `StarfieldPainter`), a glowing moon, layered vector silhouettes of far/near mountains and pine trees (drawn using custom clippers `FarMountainClipper`, `NearMountainClipper`, and `TreesClipper`), and a progress bar or glassmorphic login card. The titles use pressStart2p or Baloo 2 typography.
*   **User Avatar Synchronization**: The lobby screen user avatar (top-left header circular profile) is synchronized with the active gameplay avatar (`assets/userprofile/user7.png`) so they display the same image.
*   **App Icon / Logo**: The app launcher logo (`assets/newapklogo.png`) has 12% rounded corners with alpha channels correctly removed on iOS to match standard platform specifications and avoid store warnings.
*   **Welcome Screen Logo & Character**: The floating space droid character has been removed. The 'COREGAME' text logo has been redesigned to use a 3D gold-to-orange gradient display font (via `ShaderMask`) with a heavy black outline/shadow, and a tilted cowboy hat asset (`assets/cowboy_hat.png`) positioned dynamically resting on top of the first letter 'C' to match the forest night cowboy loading screen theme.
*   **Andar Bahar 15s Timer & Win Flow**: The 10-second Lottie timers have been replaced with a custom-built, cartoonish capsule timer matching the reference mock-up (with a monospaced "00:SS" readout, ticking clock hands, and red color alerts when time is low). The betting phase is set to 15 seconds. On round completion, the winning sequence executes a 2-phase chip animation: first, chips on losing tables fly to the winning table (1 second), then all table chips fly from the winning table directly to the player profiles (1 second) before transitioning back to the betting phase after 3.8 seconds.

---

## 5. Media & Lottie Assets

The app references multiple types of assets in [pubspec.yaml](file:///Users/satyamkumar/Desktop/coregame/pubspec.yaml):
*   **Background Video**: [assets/bg_video.mp4](file:///Users/satyamkumar/Desktop/coregame/assets/bg_video.mp4) (loops muted in `WelcomeScreen`).
*   **Lottie JSON Animations**:
    *   `assets/10_second_countdown_timer.json` (Timer wheel)
    *   `assets/count_down_red_and_grey_3_to_1.json` (Deal warning)
    *   `assets/7updown/Comp 1.json` (Dice rolling sequence)
*   **Images**: Organised cleanly into subdirectories:
    *   `assets/chips/` - Denominations: 10, 50, 100, 500, 1000, 5000 (5K) ordered ascending from left to right (10 on far left, 5000 on far right). Selected chips animate with vertical offset Y-translation (`-8.0` px).

    *   `assets/logos/` - Game launch cards and title logos (e.g. `keno_logo.png`, `andar_bahar.png`, `twist_logo.png`).
    *   `assets/icons/` - Menu and navigation icons (e.g. `home_icon.png`, `icon_vip_club.png`, `icon_bet_history.png`).
    *   `assets/ABbg.png` - Andar Bahar game board background.

---

## 6. Development Rules & Future Constraints

1.  **Landscape Lock**: Maintain the landscape aspect ratios. UI elements must fit cleanly inside a `390.0` pixel viewport height without causing overflows.
2.  **State Upgrades**: Any additions/modifications to game inputs (like user bets) must update the lifted state in `PhoneAppShell` rather than locally maintaining persistent balances, to ensure synchronized balance updates.
3.  **Active Directory Priority**: Always make changes in `lib/games/` (or `lib/auth/screens/` / `lib/shared/`) instead of the duplicate folders in `lib/screens/` or `lib/widgets/`.
4.  **Avoid Text Double Underlines**: All screen roots should return a `Scaffold` or `Material` widget. Returning a raw `Container` or `Stack` without a Material/Scaffold context causes nested `Text` widgets to render with default fallback double yellow underlines.
5.  **Andar Bahar Bet Panel Opacity**: Andar/Bahar betting panels are 100% opaque (not transparent) mixed with dark values to ensure clear text readability on top of `assets/ABbg.png`. The 'Can bet' labels have been removed from the Andar, Bahar, and Tie panels.
6.  **Andar Bahar 10s Timer Widget**: Positioned next to the center card group (left: `w * 0.66`, top: `h * 0.04`) and enlarged by 30% to dimensions `130.0` width and `52.0` height.
7.  **User Win Gold Overlay**: When the user wins in Andar Bahar, a golden win text overlay (`+Amount`) with a dark high-contrast outline and amber glow is rendered directly centered on top of their avatar, scales/fades out over 1500ms.
8.  **Active Users Widget**: Displays a dynamic fluctuating active user counter (clamped to 30-60) at the bottom-right corner of Andar Bahar. Clicking this widget pops up an elegant "Active Room Players" dialog listing table occupants. 40% of mock bets fly directly from this bottom-right panel to Andar, Bahar, or Tie.
9.  **Andar Bahar Last-3s Timer Widget**: Transitions at 3 seconds to show `assets/10_second_countdown_timer_react_end_loop.json` in the exact same Positioned coordinates (`left: w * 0.66`, `top: h * 0.04`) and size (`130.0` width and `52.0` height) as the 10s timer, remaining active and shaking during the dealing and winner phases until the next round's 10s timer restarts.
10. **Andar Bahar Center 3s Warning**: During the last 3 seconds of betting, the original 3s warning Lottie (`assets/count_down_red_and_grey_3_to_1.json`) displays at the screen center as a high-visibility warning.
11. **7 Up Down Game Design Alignment**: Re-implemented the layout of `seven_up_down_screen.dart` to match Andar Bahar's landscape Stack-based structure. Integrated the shared `MockPlayerWidget`, `UserAvatarWidget` with the golden win float popup animation, and bottom-right `Active Users Widget` (online count 30-60, clickable to show list popup).
12. **7 Up Down Chip Flying Animations**: Implemented flying chip animations using `FlyingChip` and `TableChip` collections. User bets fly chips from the bottom-left corner, mock players fly chips from their left/right side avatar panels, and active online users fly chips from the bottom-right corner. Chip trajectories are strictly straight lines (linear interpolation) with no vertical arc or scale distortion.
13. **7 Up Down Countdown Timers**: Transitioned the countdown timer to play `assets/10_second_countdown_timer.json` from 10s to 4s, and `assets/10_second_countdown_timer_react_end_loop.json` (shaking timer loop) from 3s down to 0 and during dealing/winner phases. The center warning Lottie plays at screen center from 3s to 1s.
14. **Mock Betting Frequency**: Elevated mock player bet frequencies in both Andar Bahar and 7 Up Down screens. The simulation logic now runs 2 to 5 bets per second with a high success rate (70% probability), rendering a significantly more active and premium casino environment.
15. **Mock Player Winnings Flights & Win Overlay**: Added support in both Andar Bahar and 7 Up Down for mock player winnings. When any of the 6 mock players or the active online users badge wins a bet, a reverse coin/chip flight animation triggers from the winner panel back to their coordinates. Visible mock players also trigger a centered golden win text overlay directly on top of their avatar face.
16. **Andar Bahar Player Avatars**: The player profiles (both mock players and the user) are styled as rounded gold-bordered rectangles (`BorderRadius.circular(9.0)`). Above the avatar, VIP mock players display shiny italic gradient title banners with stars/crown decorations, and below they show username and balance in dark translucent tag containers. To prevent visual overlaps, mock columns start at `top: h * 0.18` (height spacing `12.0`), while the User Profile and Active Users Count widgets are positioned independently at the bottom center (`bottom: h * 0.03`) directly to the left and right of the chip selector bar (`left: w * 0.15` and `right: w * 0.15` respectively).
17. **Deposit Screen Package Selector**: Quick selection package cards in the deposit screen are structured with `childAspectRatio = 1.38` (when screenWidth >= 680) and compact vertical bounds (coin image `18.0` width/height, buy button `22.0` height, warning spacer `6.0`, grid spacer `8.0`). This guarantees both selection rows fit fully within the dialog height without scrolling, keeping the top row's blue labels visible at all times.
18. **Lobby Screen Sidebar Position**: The left side layout in the lobby screen (including the alligator avatar, BC.GAME logo, category sidebar, and bottom left action buttons) is shifted closer to the screen bezel by defining a left-only padding offset of `left: 4.0` in the main body `Padding` widget.
19. **Lobby Screen Profile Customization**: Tapping the top-left user avatar in the lobby screen opens a profile customization dialog. The NICKNAME section displays the dynamic nickname (defaults to `superhit`) and includes an `EDIT` button that opens a text input dialog to save a new name. The `EDIT AVATAR` button opens a grid of all 7 available PNG files (`assets/userprofile/user1.png` to `user7.png`). Selecting any avatar updates the profile image synchronously in the lobby header and inside the active gameplay screens (Andar Bahar and Seven Up Down).
20. **Andar Bahar Tie Bet Panel Layout**: Adjusted font sizes inside `TieBetPanel` to `9.0` (label), `14.0` (title), and `7.5` (status) to prevent a vertical RenderFlex layout overflow exception on landscape viewports.
21. **Welcome and Login Screens Redesign**: The Welcome and Login screens backgrounds have been upgraded from static images to the dynamic `NightForestBackground` widget (gradient sky, drifting stars, vector mountains/trees silhouette), matching the loading screen theme.
22. **Grand Master Star Badge**: A gold-to-orange gradient `Icons.star` badge is overlaid using `Positioned(top: -8.0)` directly above the Grand Master (`name == 'Master'`, right side index 0) player avatar in `player_widgets.dart`. The parent `Stack` uses `clipBehavior: Clip.none` to allow the badge to render above the card boundary.
23. **Grand Master Flying Star Trail Animation**: When the Grand Master places a bet (`playerKey == 'R0'`), 20 stars are spawned in sequence (45ms delay each). Stars decrease in size from 24px → 4px. All 20 target the same pre-computed `fixedEndX/fixedEndY` landing point, forming a single comet-tail line. Each star originates from a **different edge of the Grand Master profile card** using 8-direction offset cycling (top/top-right/right/bottom-right/bottom/bottom-left/left/top-left) from `profileCX=0.96, profileCY=0.22`. Star Y-path follows a parabolic arc (`arcLift = -0.18 × 4 × t × (1-t)`). Only the 20th star has `addToTable: true`; all others dissolve on arrival.
24. **`FlyingChip` Model Fields**: `isStar` (bool, default false), `addToTable` (bool, default true), `starSize` (double, default 18.0), `fixedEndX`/`fixedEndY` (optional doubles) added to `_triggerChipFlight`. When `fixedEndX` is provided, random endpoint generation is skipped.
25. **Active Users Widget — True Bottom-Right Corner**: Moved from `right: w*0.15` → `right: w*0.02`. Mock bet coin origin updated to `startX: 0.98, startY: 0.88` to match the widget's actual screen position.
26. **Player Profile Sizes (+3%)**: Mock player avatars: `36px → 37px`, username font `7.0 → 7.2px`. User own profile: avatar `36 → 37 → 38px`, icon `21 → 22 → 23px`, name/balance font `7.5 → 7.7 → 7.9px`.
27. **Grand Master Bet Panel Glow Star**: `_masterBetSpots` (a `Set<String>`) tracks which bet spots (`'andar'`, `'bahar'`, `'tie'`) the Grand Master has placed a bet on in the current round. It is cleared in `_startBettingPhase`. Both `SideBetPanel` and `TieBetPanel` now accept a `hasMasterBet` boolean. When true, a pulsating gold→orange gradient `Icons.star` with an orange glow `BoxShadow` replaces the static dim `star_border` icon. The glow animation uses an internal `AnimationController` (900ms repeat reverse) with opacity/size pulsing from `0.4 → 1.0`. Star position: bottom-left/bottom-right of `SideBetPanel`, top-right of `TieBetPanel`.
28. **7 Up Down Table Visual Redesign (Andar Bahar Style)**: Replaced the game board betting boxes with a custom `SevenUpDownBetPanel` widget matching Andar Bahar's side panel styling. The panels feature base color metallic gradients, top-left monetization coins for total bets, top-right decimal multipliers (`2.0` / `5.0`), bottom-left translucent `"Mine"` user bet badges, and bottom-right glowing Grand Master star badges. Included the `_blinkController` to highlight the winning panel with a golden border and shadow glow for 2.5 seconds at the end of each round.
29. **Coin Flip Header & Background Redesign**: Removed the top-right balance capsule from the header in `lib/games/coin_flip/coin_flip_screen.dart` to make it clean and consistent with Andar Bahar. Moved the wallet balance display to a premium row inside the bet controls container card at the top. Replaced the blue/indigo animated space background with `NightForestBackground` to match the loading screen style forest/mountains/moon theme.
30. **Game Cleanups (Demo Notice, Headers, Boxed Balance)**: Removed the `"COIN FLIP"` game title text from the header bar in `lib/games/coin_flip/coin_flip_screen.dart` and minimized padding to shift the layout up and fill top spacing. Packed the wallet balance display inside a dark border `Container` box at the top of the bet controls card. Removed the bottom `"Betting with 0 will enter demo mode."` warning notice container from Coin Flip (resolving the 28-pixel overflow issue), Limbo, Hi-Lo, and Dice games to make the layout extremely clean.
31. **Consistent Styled Back Buttons**: Replaced the top-left back button design in all 11 games (Coin Flip, 7 Up Down, Limbo, Classic Dice, Mines Multiplier, Hi-Lo, Plinko Cascade, Roulette, Crash, Twist, and Keno 12) with Andar Bahar's signature design: a translucent black container (`Color(0x33000000)`) with rounded corners (` BorderRadius.circular(8.0)`), thin border (`Colors.white24`), and a white `Icons.arrow_back_ios_new` icon (size `16.0`).
32. **Roulette Visual & Board Redesign**: Redesigned `lib/games/roulette/roulette_screen.dart` to match the reference dashboard: swapped layout (wheel on left, board on right). Added a complete interactive board layout with 0, 3x12 numbers grid, 2 TO 1 columns, dozens row, and halves/colors/parity row. Active bets display circular colored poker chips (`10`, `50`, `100`, `500`, `1K`, `5K`) directly on top of the cells. Added a chip selection/arrow bar and a clear bet button at the bottom next to the spin button. Extended `_finishSpin` math to compute Dozens, Columns, and Halves payouts. Re-styled the header with Total Bet box, `R O U L E T T E` RichText title, and trends/settings buttons.
33. **Roulette Wheel Size & Real Chips/Profiles**: Shrunk the Roulette wheel drawing radius by exactly 5% in `_RouletteWheelPainter`. Integrated `UserAvatarWidget` next to the chip selector to render the user's nickname and avatar image with dynamic nudge (on bet) and win text animations. Replaced custom chip containers in both the selector bar and table grid overlays with Andar Bahar's `PokerChipWidget` utilizing genuine chip PNG assets.
34. **Roulette Layout & Sizing Adjustments**: Fixed vertical layout overflow in `_buildWheelContainer` by replacing `AspectRatio` with `Expanded` and centering the custom painter circular dome using `min(size.width, size.height)`. Scaled up the user profile avatar widget by 1.2x and enlarged the poker chips in the bottom selector to `size: 34.0`. Converted the interactive board Column to `mainAxisSize: MainAxisSize.max` and inserted `const Spacer()` to push the profile and chips selector bar to the absolute bottom of the screen.
35. **Roulette Wheel Size Expansion Bug Fix**: Resolved the bug where the wheel appeared tiny by removing two greedy `Spacer` widgets inside `_buildWheelContainer`'s Column. Replaced them with fixed `SizedBox(height: 8.0)` widgets, allowing the `Expanded` CustomPaint to use all available vertical space and display the wheel at its maximum centered diameter.
36. **Twist Metallic Roulette Design**: Upgraded `lib/games/roulette/roulette_screen.dart` to match the Twist metallic design of `roulate.html`. Replaced the wooden rim/bowl with a dark metallic silver-grey shader rim and dark bowl. Added 24 golden outer "twist" ticks rotating with the wheel, 8 opposite-rotating curved semi-transparent gold/white bands inside the bowl, and 4 elegant opposite-rotating gold handles/spokes. Upgraded pocket gradients to premium metallic gold dividers and styled a gold pointer needle at the top.
37. **Roulette Ball Physics Fix**: Fixed the ball animation in both `roulate.html` and the Flutter `_RouletteWheelPainter`. Ball now spins on the outer track during the first 60% of the animation, then smoothly drops inward using Hermite smoothstep easing to settle into the winning pocket center at `(numRingInner + numRingOuter) / 2` radius during the last 40%. Includes subtle bounce oscillation during settle and angle interpolation towards the pocket center. Ball size reduced to `side * 0.014`.
38. **Roulette Auto-Countdown Timer (Like Andar Bahar)**: Converted roulette from a manual SPIN button to an automatic 15-second countdown game loop. Added `_gamePhase` ('betting' → 'spinning' → 'result' → loop), `_timerSeconds`, and `_gameTimer`. Betting phase runs 15 seconds with countdown; when timer hits 0, wheel auto-spins. After result display (3.8s delay), loop restarts. SPIN button replaced with an Andar Bahar-style countdown timer capsule widget (00:SS format with mini clock face, gold/red at 3s). Chips and clear bet are disabled (opacity 0.5) during spinning/result phases. Bets are placed during betting phase only. If no bet is placed, wheel still spins but no deduction/payout occurs.


