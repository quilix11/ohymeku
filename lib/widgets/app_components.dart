import 'package:flutter/material.dart';

class PageHeading extends StatelessWidget {
  final String eyebrow, title, subtitle;
  const PageHeading(
      {super.key,
      required this.eyebrow,
      required this.title,
      required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyebrow.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary)),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.headlineLarge),
          const SizedBox(height: 10),
          Text(subtitle, style: theme.textTheme.bodyMedium),
        ]));
  }
}

class MetricTile extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const MetricTile(
      {super.key,
      required this.icon,
      required this.value,
      required this.label});
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ])));
}

const profileIcons = [
  Icons.person_rounded,
  Icons.flight_rounded,
  Icons.auto_awesome_rounded,
  Icons.local_florist_rounded
];
