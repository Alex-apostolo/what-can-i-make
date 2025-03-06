import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/domain/services/inventory_service.dart';
import '../../domain/models/ingredient.dart';
import '../shared/dialog_helper.dart';
import 'components/app_bar.dart';
import 'components/empty_state.dart';
import 'components/grouped_ingredient_list.dart';
import 'components/inventory_action_buttons.dart';
import 'dialogs/image_picker_bottom_sheet.dart';

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
    setState(() => _isLoading = isLoading);
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (modalContext) => ImagePickerBottomSheet(
            onImagesProcessed: _loadInventory,
            parentContext: context,
          ),
    );
  }

  void _showAddDialog() {
    DialogHelper.showAddDialog(context, (ingredient) async {
      _errorHandler.handleEither(
        await _inventoryService.addIngredients([ingredient]),
      );
      if (!mounted) return;
      _loadInventory();
    });
  }

  void _showEditDialog(Ingredient item) {
    DialogHelper.showEditDialog(context, item, (updatedIngredient) async {
      _errorHandler.handleEither(
        await _inventoryService.updateIngredient(updatedIngredient),
      );
      if (!mounted) return;
      _loadInventory();
    });
  }

  void _showClearConfirmationDialog() {
    DialogHelper.showClearConfirmationDialog(context, () async {
      _setLoading(true);
      _errorHandler.handleEither(await _inventoryService.clearIngredients());
      if (!mounted) return;
      _loadInventory();
    });
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
                          onDelete: (ingredient) async {
                            _errorHandler.handleEither(
                              await _inventoryService.deleteIngredient(
                                ingredient,
                              ),
                            );
                            if (!mounted) return;
                            _loadInventory();
                          },
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
