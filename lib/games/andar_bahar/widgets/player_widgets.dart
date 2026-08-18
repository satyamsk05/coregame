import 'package:flutter/material.dart';

/// Displays mock player avatar, name tag, and balance.
class MockPlayerWidget extends StatelessWidget {
  final String name;
  final double balance;
  final bool isLeft;
  final IconData iconData;
  final Color color;
  final bool showNameTag;

  const MockPlayerWidget({
    super.key,
    required this.name,
    required this.balance,
    required this.isLeft,
    required this.iconData,
    required this.color,
    required this.showNameTag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showNameTag) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLeft) Icon(iconData, color: color, size: 10.0) else const SizedBox(),
              const SizedBox(width: 4.0),
              Text(
                name,
                style: TextStyle(
                  color: color,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4.0),
              if (!isLeft) Icon(iconData, color: color, size: 10.0) else const SizedBox(),
            ],
          ),
          const SizedBox(height: 2.0),
        ],

        // Circular portrait
        Container(
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3.0)],
          ),
          child: ClipOval(
            child: Container(
              color: const Color(0xFF1E2240),
              alignment: Alignment.center,
              child: Icon(
                isLeft ? Icons.person : Icons.person_3,
                color: Colors.white70,
                size: 20.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2.0),

        // Balance Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0x66000000),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on,
                  color: Color(0xFFFFD700), size: 9.0),
              const SizedBox(width: 2.0),
              Text(
                balance.toStringAsFixed(0),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Displays the real user (bottom-left) avatar and balance.
class UserAvatarWidget extends StatelessWidget {
  final double balance;

  const UserAvatarWidget({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: const Color(0xFF00E5FF), width: 1.2),
          ),
          child: ClipOval(
            child: Container(
              color: const Color(0xFF1E2240),
              alignment: Alignment.center,
              child:
                  const Icon(Icons.face, color: Colors.white70, size: 22.0),
            ),
          ),
        ),
        const SizedBox(width: 6.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Satyamsk',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.0,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0x4D000000),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on,
                      color: Color(0xFFFFD700), size: 10.0),
                  const SizedBox(width: 2.0),
                  Text(
                    balance.toStringAsFixed(2),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
