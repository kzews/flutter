import 'package:flutter/material.dart';

class CustomDataColumn extends StatelessWidget {
  final Widget label;
  final bool isSorted;
  final bool ascending;
  final Function(bool) onSort;

  const CustomDataColumn({
    Key? key,
    required this.label,
    required this.isSorted,
    required this.ascending,
    required this.onSort,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onSort(!isSorted || !ascending);
      },
      child: Row(
        children: [
          (label),
          SizedBox(width: 5), // Add some spacing between text and icon
          if (isSorted)
            Icon(
              ascending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Theme.of(context).primaryColor,
            ),
        ],
      ),
    );
  }
}
