import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PhoneMockupWrapper extends StatelessWidget {
  final Widget child;

  const PhoneMockupWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 1. Detect if running on mobile platforms (Android or iOS)
    final bool isMobilePlatform = defaultTargetPlatform == TargetPlatform.android ||
                                  defaultTargetPlatform == TargetPlatform.iOS;

    // 2. Check the logical dimensions of the active screen window
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double deviceHeight = MediaQuery.of(context).size.height;

    // If running on a real mobile device or the window size is too small to fit the mockup,
    // bypass the phone frame chassis mockup entirely and render full screen.
    final bool shouldBypass = isMobilePlatform || deviceWidth < 900.0 || deviceHeight < 500.0;

    if (shouldBypass) {
      return child;
    }

    // Landscape Phone Dimensions (standard widescreen profile)
    const double screenWidth = 844.0;
    const double screenHeight = 390.0;
    const double bezel = 14.0;

    final double phoneWidth = screenWidth + (bezel * 2);
    final double phoneHeight = screenHeight + (bezel * 2);

    return Scaffold(
      backgroundColor: const Color(0xFF161618), // Dark slate matte workspace background
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. External side buttons (mocked physical buttons outside the chassis)
                      // Volume buttons (Top edge, when landscape)
                      Positioned(
                        top: -3.0,
                        left: 140.0,
                        child: Container(
                          width: 45.0,
                          height: 3.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4E4E52),
                            borderRadius: BorderRadius.circular(1.0),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -3.0,
                        left: 200.0,
                        child: Container(
                          width: 45.0,
                          height: 3.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4E4E52),
                            borderRadius: BorderRadius.circular(1.0),
                          ),
                        ),
                      ),
                      // Power Button (Bottom edge, when landscape)
                      Positioned(
                        bottom: -3.0,
                        right: 140.0,
                        child: Container(
                          width: 60.0,
                          height: 3.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4E4E52),
                            borderRadius: BorderRadius.circular(1.0),
                          ),
                        ),
                      ),

                      // 2. Phone Main Chassis (Body)
                      Container(
                        width: phoneWidth,
                        height: phoneHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C0C0E), // Phone bezel matte black
                          borderRadius: BorderRadius.circular(42.0),
                          border: Border.all(
                            color: const Color(0xFF28282B), // Chrome dark metal border
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 40.0,
                              spreadRadius: 2.0,
                              offset: const Offset(0, 20),
                            ),
                            BoxShadow(
                              color: const Color(0xFF00C853).withOpacity(0.05), // Soft green glow reflecting app style
                              blurRadius: 60.0,
                              spreadRadius: 5.0,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 3. Dynamic Island / Front Camera Notch (Left side in landscape)
                            Positioned(
                              left: 10.0,
                              child: Container(
                                width: 8.0,
                                height: 48.0,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(4.0),
                                  border: Border.all(
                                    color: const Color(0xFF1E1E20),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Front Camera Sensor circle inside island
                            Positioned(
                              left: 12.0,
                              child: Container(
                                width: 4.0,
                                height: 4.0,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0E1326),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),

                            // Speaker grill notch on left edge
                            Positioned(
                              left: 3.0,
                              child: Container(
                                width: 2.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252528),
                                  borderRadius: BorderRadius.circular(1.0),
                                ),
                              ),
                            ),

                            // 4. The Simulated Mobile Screen
                            Padding(
                              padding: EdgeInsets.all(bezel),
                              child: Container(
                                width: screenWidth,
                                height: screenHeight,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBEBEB),
                                  borderRadius: BorderRadius.circular(30.0), // Rounded viewport
                                ),
                                child: child,
                              ),
                            ),

                            // Screen glare overlay reflection (pure premium polish)
                            IgnorePointer(
                              child: Padding(
                                padding: EdgeInsets.all(bezel),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30.0),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.06),
                                        Colors.white.withOpacity(0.01),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.35, 1.0],
                                    ),
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
            ),
          ),
        ),
      ),
    );
  }
}
