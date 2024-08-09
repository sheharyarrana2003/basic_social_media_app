import 'package:flutter/material.dart';

class BuildTextBox extends StatelessWidget {
  final String text;
  final String sectionName;
  final void Function()? onPressed;
  const BuildTextBox(
      {super.key,
      required this.text,
      required this.sectionName,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      margin: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionName,
                style: TextStyle(
                    color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
              IconButton(
                  onPressed: onPressed,
                  icon: Icon(
                    Icons.edit,
                    color: Colors.grey[500],
                  )),
            ],
          ),
          Text(text),
        ],
      ),
    );
  }
}
