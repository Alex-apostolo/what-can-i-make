import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/features/inventory/models/ingredient.dart';
import 'package:what_can_i_make/features/inventory/domain/inventory_service.dart';
import 'package:what_can_i_make/features/inventory/presentation/components/app_bar.dart';
import 'package:what_can_i_make/features/inventory/presentation/components/empty_state.dart';
import 'package:what_can_i_make/features/inventory/presentation/components/grouped_ingredient_list.dart';
import 'package:what_can_i_make/features/inventory/presentation/components/inventory_action_buttons.dart';
import 'package:what_can_i_make/features/inventory/presentation/dialogs/image_picker_bottom_sheet.dart';
import 'package:what_can_i_make/features/inventory/utils/dialog_helper.dart';

class InventoryScreen extends StatefulWidget {
  static const routeName = '/inventory';

  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Ingredient> _ingredients = [];
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

  Future<void> _loadInventory({bool showLoading = true}) async {
    if (showLoading) _setLoading(true);
    final inventoryResult = await _inventoryService.getInventory();
    if (showLoading) _setLoading(false);

    final inventory = _errorHandler.handleFatalEither(
      inventoryResult,
      onRetry: () => _loadInventory(),
    );

    if (inventory != null && mounted) {
      setInventory(inventory);
    }
  }

  void setInventory(List<Ingredient> ingredients) {
    setState(() => _ingredients = ingredients);
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
    _errorHandler.handleEither(await action);
    if (mounted) _loadInventory(showLoading: false);
  }

  void _showAddDialog() {
    DialogHelper.showAddDialog(
      context,
      (IngredientInput ingredientInput) => _handleIngredientAction(
        _inventoryService.addIngredients([ingredientInput]),
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
      () => _handleIngredientAction(_inventoryService.clearInventory()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = _ingredients.isNotEmpty;

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
                          ingredients: _ingredients,
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
              ? InventoryActionButtons(
                onImagesProcessed: _loadInventory,
                showImagePicker: _showImagePicker,
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
