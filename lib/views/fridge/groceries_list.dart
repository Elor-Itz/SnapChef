import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../viewmodels/fridge_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../views/fridge/widgets/ingredient_reminder_dialog.dart';
import '../../models/notifications/ingredient_reminder.dart';

class GroceriesList extends StatelessWidget {
  final VoidCallback? onAdd;

  const GroceriesList({
    super.key,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FridgeViewModel>(
      builder: (context, fridgeViewModel, _) {
        final groceries = fridgeViewModel.filteredGroceries;

        return Column(
          children: [
            Expanded(
              child: groceries.isEmpty
                  ? const Center(
                      child: Text(
                        'No groceries in your list.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: groceries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ingredient = groceries[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          color: Colors.white,
                          child: ListTile(
                            leading: (ingredient.imageURL.isNotEmpty)
                                ? Image.network(
                                    ingredient.imageURL,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Icon(Icons.image_not_supported,
                                          size: 32),
                                    ),
                                  )
                                : SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Icon(Icons.image_not_supported,
                                        size: 32),
                                  ),
                            title: Text(
                              ingredient.count > 1
                                  ? '${ingredient.name} x ${ingredient.count}'
                                  : ingredient.name,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Category: ${ingredient.category}'),
                                Text('Quantity: ${ingredient.count}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.alarm,
                                      color: primaryColor),
                                  tooltip: 'Set Grocery Reminder',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          IngredientReminderDialog(
                                        ingredient: ingredient,
                                        type: ReminderType.grocery,
                                        // onSetAlert is now just a placeholder, or you can remove it if not needed
                                        onSetAlert: (_) {},
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.kitchen,
                                      color: primaryColor),
                                  tooltip: 'Move to Fridge',
                                  onPressed: () async {
                                    final userViewModel =
                                        Provider.of<UserViewModel>(context,
                                            listen: false);
                                    final fridgeId = userViewModel.fridgeId;
                                    if (fridgeId != null &&
                                        fridgeId.isNotEmpty) {
                                      await fridgeViewModel.addGroceryToFridge(
                                          fridgeId, ingredient);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () async {
                                    final userViewModel =
                                        Provider.of<UserViewModel>(context,
                                            listen: false);
                                    final fridgeId = userViewModel.fridgeId;
                                    if (fridgeId != null &&
                                        fridgeId.isNotEmpty) {
                                      await fridgeViewModel.deleteGroceryItem(
                                          fridgeId, ingredient.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}