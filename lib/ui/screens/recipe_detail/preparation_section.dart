import 'package:flutter/material.dart';

class PreparationSection extends StatelessWidget {
  final List<String> steps;

  const PreparationSection({
    super.key,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ---- TITLE ----
        const Text(
          "Cooking Instruction",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 15),

        /// ---- EMPTY STATE ----
        if (steps.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              "No cooking steps available",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          )
        else
          /// ---- LISTING STEPS ----
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            separatorBuilder: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(thickness: 1, color: Color(0xFFECECEC)),
            ),
            itemBuilder: (_, index) {
              return _StepCard(
                stepNumber: index + 1,
                text: steps[index],
              );
            },
          ),
      ],
    );
  }
}

/// ---- EACH STEP CARD ----
class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String text;

  const _StepCard({
    required this.stepNumber,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            "STEP $stepNumber",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
