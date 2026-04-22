import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_screen_controller.g.dart';

class HomeScreenState {
  final bool isEditMode;
  final Set<String> selectedIds; // Для масового видалення категорій

  HomeScreenState({this.isEditMode = false, this.selectedIds = const {}});

  HomeScreenState copyWith({bool? isEditMode, Set<String>? selectedIds}) {
    return HomeScreenState(
      isEditMode: isEditMode ?? this.isEditMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

@riverpod
class HomeScreenController extends _$HomeScreenController {
  @override
  HomeScreenState build() => HomeScreenState();

  void toggleEditMode() {
    state = state.copyWith(
      isEditMode: !state.isEditMode,
      selectedIds: {}, // Скидаємо виділення при виході/вході
    );
  }

  void toggleSelection(String id) {
    final newSelected = Set<String>.from(state.selectedIds);
    if (newSelected.contains(id)) {
      newSelected.remove(id);
    } else {
      newSelected.add(id);
    }
    state = state.copyWith(selectedIds: newSelected);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }
}
