import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';

class CheckInBottomSheet extends StatelessWidget {
  final CheckInModel checkin;

  const CheckInBottomSheet({super.key, required this.checkin});

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('dd/MM/yyyy • HH:mm').format(checkin.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Ảnh chính với Hero animation
            if (checkin.images.isNotEmpty)
              Hero(
                tag: "checkin-${checkin.id}",
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    checkin.images.first,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Category + vibe
            Row(
              children: [
                Image.network(
                  checkin.categoryIcon,
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 20,
                      color: Colors.grey),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  checkin.categoryId,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  checkin.vibeIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 10),
                Text(
                  checkin.vibeId,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Nội dung
            if (checkin.content.isNotEmpty)
              Card(
                elevation: 0,
                color: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    checkin.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Vị trí + thời gian
            Row(
              children: [
                const Icon(Icons.place, color: Colors.red, size: 20),
                const SizedBox(width: 6),
                Text(
                  "${checkin.latitude.toStringAsFixed(5)}, ${checkin.longitude.toStringAsFixed(5)}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Ảnh phụ
            if (checkin.images.length > 1)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ảnh khác",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: checkin.images.length - 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          checkin.images[index + 1],
                          width: 120,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
