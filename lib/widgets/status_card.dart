import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final bool isEnabled;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatusCard({
    Key? key,
    required this.title,
    required this.isEnabled,
    required this.icon,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? Colors.green : Colors.grey,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle ?? (isEnabled ? 'Enabled' : 'Disabled'),
                      style: TextStyle(
                        fontSize: 14,
                        color: isEnabled ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isEnabled ? Icons.check_circle : Icons.cancel,
                color: isEnabled ? Colors.green : Colors.grey,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
