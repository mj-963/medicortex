import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final Function(String?)? onYearChanged;
  final Function(String?)? onTypeChanged;
  final Function(String?)? onSortChanged;
  final String? selectedYear;
  final String? selectedType;
  final String selectedSort;

  const FilterBar({
    super.key,
    this.onYearChanged,
    this.onTypeChanged,
    this.onSortChanged,
    this.selectedYear,
    this.selectedType,
    this.selectedSort = 'Relevance',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Year',
              icon: Icons.calendar_today,
              items: const [
                'All Years',
                '2024',
                '2023',
                '2022',
                '2021',
                'Last 5 years',
              ],
              selectedValue: selectedYear,
              onChanged: onYearChanged,
            ),
            const SizedBox(width: 12),
            _FilterChip(
              label: 'Study Type',
              icon: Icons.science,
              items: const [
                'All Types',
                'Clinical Trial',
                'Meta-Analysis',
                'Review',
                'Randomized Controlled Trial',
              ],
              selectedValue: selectedType,
              onChanged: onTypeChanged,
            ),
            const SizedBox(width: 12),
            _FilterChip(
              label: 'Sort',
              icon: Icons.sort,
              items: const [
                'Relevance',
                'Date (Newest)',
                'Date (Oldest)',
                'Citation Count',
              ],
              selectedValue: selectedSort,
              onChanged: onSortChanged,
            ),
            const SizedBox(width: 16),
            // Results count placeholder
            Text(
              'Filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final String? selectedValue;
  final Function(String?)? onChanged;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.items,
    this.selectedValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedValue != null && selectedValue != items[0];

    return PopupMenuButton<String>(
      onSelected: (value) {
        onChanged?.call(value);
      },
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem<String>(value: item, child: Text(item));
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
            const SizedBox(width: 6),
            Text(
              selectedValue ?? label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }
}
