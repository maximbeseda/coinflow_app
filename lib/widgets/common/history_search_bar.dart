import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../providers/all_providers.dart';
import '../../database/app_database.dart';
import '../../theme/app_colors_extension.dart';

class HistorySearchBar extends ConsumerStatefulWidget {
  final CategoryType? specificType;

  const HistorySearchBar({super.key, this.specificType});

  @override
  ConsumerState<HistorySearchBar> createState() => _HistorySearchBarState();
}

class _HistorySearchBarState extends ConsumerState<HistorySearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialQuery = ref.read(filterProvider).searchQuery;
      if (initialQuery.isNotEmpty) {
        _searchController.text = initialQuery;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // 👇 Ми можемо просто скасувати таймер через безпечний виклик `?.`,
    // замість складної перевірки з `!`
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(filterProvider.notifier).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        style: TextStyle(color: colors.textMain, fontSize: 16),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'search_transactions'.tr(),
          hintStyle: TextStyle(color: colors.textSecondary),
          prefixIcon: Icon(Icons.search, color: colors.textSecondary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    _focusNode.unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
