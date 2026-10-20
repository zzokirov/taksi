import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';

class ReviewSubmitModal extends StatefulWidget {
  final int appointmentId;
  final String barberName;
  final Future<bool> Function(int rating, String comment) onSubmit;

  const ReviewSubmitModal({
    super.key,
    required this.appointmentId,
    required this.barberName,
    required this.onSubmit,
  });

  @override
  State<ReviewSubmitModal> createState() => _ReviewSubmitModalState();
}

class _ReviewSubmitModalState extends State<ReviewSubmitModal> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    setState(() => _isLoading = true);
    final success = await widget.onSubmit(_rating, _commentController.text.trim());
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fikr va baho muvaffaqiyatli saqlandi. Rahmat!"),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Xizmatga baho bering",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "${widget.barberName} xizmatidan qoniqdingizmi?",
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),

          // 5-Star Rating selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNum = index + 1;
              return IconButton(
                icon: Icon(
                  starNum <= _rating ? Icons.star : Icons.star_border,
                  color: AppColors.gold,
                  size: 36,
                ),
                onPressed: () => setState(() => _rating = starNum),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Comment
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              hintText: "Sartarosh va xizmat haqida fikringizni yozing...",
            ),
          ),
          const SizedBox(height: 20),

          CustomButton(
            text: "Fikrni yuborish",
            isLoading: _isLoading,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
