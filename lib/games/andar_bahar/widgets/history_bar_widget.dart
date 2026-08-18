import 'package:flutter/material.dart';

/// History bar showing previous round outcomes (A=Andar blue, B=Bahar red).
class HistoryBarWidget extends StatelessWidget {
  final List<String> history;

  const HistoryBarWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: const Color(0x33000000),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.white10),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: history.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: 6.0),
              itemBuilder: (context, index) {
                final isA = history[index] == 'A';
                return Container(
                  width: 18.0,
                  height: 18.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isA
                        ? const Color(0xFF1565C0)
                        : const Color(0xFFC62828),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    history[index],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: const Color(0x33000000),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: Colors.white10),
          ),
          child:
              const Icon(Icons.trending_up, color: Colors.white, size: 16.0),
        ),
      ],
    );
  }
}
