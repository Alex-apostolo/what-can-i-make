import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/core/models/ingredient.dart';
import 'package:what_can_i_make/features/inventory/utils/dialog_helper.dart';
import 'components/app_bar.dart';
import 'components/empty_state.dart';
import 'components/grouped_ingredient_list.dart';
import 'components/inventory_action_buttons.dart';
import 'dialogs/image_picker_bottom_sheet.dart';
import '../domain/inventory_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Ingredient> _inventory = [];
  bool _isLoading = true;
  late final InventoryService _inventoryService;
  late final ErrorHandler _errorHandler;

  @override
  void initState() {
    super.initState();
    _inventoryService = context.read<InventoryService>();
    _errorHandler = context.read<ErrorHandler>();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    if (!mounted) return;

    _setLoading(true);

    final ingredients = _errorHandler.handleEither(
      await _inventoryService.getIngredients(),
    );

    if (!mounted) return;
    setInventory(ingredients);
    _setLoading(false);
  }

  void setInventory(List<Ingredient> ingredients) {
    setState(() => _inventory = ingredients);
  }

  void _setLoading(bool isLoading) {
    if (!mounted) return;
    setState(() => _isLoading = isLoading);
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (modalContext) => ImagePickerBottomSheet(
            onImagesProcessed: _loadInventory,
            parentContext: context,
          ),
    );
  }

  Future<void> _handleIngredientAction(Future<dynamic> action) async {
    _setLoading(true);
    _errorHandler.handleEither(await action);
    if (mounted) _loadInventory();
  }

  void _showAddDialog() {
    DialogHelper.showAddDialog(
      context,
      (Ingredient ingredient) => _handleIngredientAction(
        _inventoryService.addIngredients([ingredient]),
      ),
    );
  }

  void _showEditDialog(Ingredient item) {
    DialogHelper.showEditDialog(
      context,
      item,
      (Ingredient updatedIngredient) => _handleIngredientAction(
        _inventoryService.updateIngredient(updatedIngredient),
      ),
    );
  }

  void _deleteIngredient(Ingredient ingredient) {
    _handleIngredientAction(_inventoryService.deleteIngredient(ingredient));
  }

  void _showClearConfirmationDialog() {
    DialogHelper.showClearConfirmationDialog(
      context,
      () => _handleIngredientAction(_inventoryService.clearIngredients()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = _inventory.isNotEmpty;

    return Scaffold(
      appBar: HomeAppBar(
        hasItems: hasItems,
        onAddPressed: _showAddDialog,
        onClearPressed: _showClearConfirmationDialog,
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [const CircularProgressIndicator()],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadInventory,
                child:
                    hasItems
                        ? GroupedIngredientList(
                          ingredients: _inventory,
                          onEdit: _showEditDialog,
                          onDelete: _deleteIngredient,
                        )
                        : EmptyState(
                          onAddPressed: _showAddDialog,
                          onScanPressed: _showImagePicker,
                        ),
              ),
      floatingActionButton:
          hasItems
              ? InventoryActionButtons(onImagesProcessed: _loadInventory)
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
