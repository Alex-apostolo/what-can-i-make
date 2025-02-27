import 'package:flutter/material.dart';
import '../models/kitchen_item.dart';
import 'item_card.dart';

class CategorySection extends StatelessWidget {
  final String title;
  final List<KitchenItem> items;
  final Function(KitchenItem) onEdit;
  final Function(KitchenItem) onDelete;

  const CategorySection({
    super.key,
    required this.title,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: true,
      children: [
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No items found'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ItemCard(
                item: items[index],
                onEdit: onEdit,
                onDelete: onDelete,
              );
            },
          ),
      ],
    );
  }
} 