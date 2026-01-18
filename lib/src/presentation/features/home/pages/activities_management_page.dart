import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, ReorderableListView, DismissDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/src/core/di/parts/use_case_providers.dart';
import 'package:tempo/src/domain/entities/activity_type.dart';
import 'package:tempo/src/presentation/core/widgets/tempo_design_system.dart';
import 'package:tempo/src/presentation/features/home/dialogs/activity_editor_dialog.dart';
import 'package:tempo/src/presentation/features/home/providers/activity_types_provider.dart';

class ActivitiesManagementPage extends ConsumerWidget {
  const ActivitiesManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We need to watch activityTypesProvider
    final activitiesAsync = ref.watch(activityTypesProvider);

    return CupertinoPageScaffold(
      backgroundColor: TempoDesign.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Manage Activities'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Done'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: activitiesAsync.when(
          data: (activities) {
             if (activities.isEmpty) {
                return const Center(child: Text('No activities'));
             }
             
             // ReorderableListView requires Material styling sometimes or custom proxy.
             // Standard ReorderableListView works in CupertinoApp but looks Material-ish?
             // Let's use it, wrapped in Material widget if needed (Scaffold body handles it usually).
             // Drag handles: Icons.drag_handle (Material). CupertinoIcons.bars?
             
             return ReorderableListView.builder(
               padding: const EdgeInsets.symmetric(vertical: 10),
               itemCount: activities.length,
               onReorder: (oldIndex, newIndex) {
                 if (oldIndex < newIndex) {
                   newIndex -= 1;
                 }
                 final item = activities.removeAt(oldIndex);
                 activities.insert(newIndex, item);
                 
                 // Update Repository
                 final ids = activities.map((e) => e.id).toList();
                 ref.read(reorderActivityTypesUseCaseProvider).call(ids);
               },
               itemBuilder: (context, index) {
                 final activity = activities[index];
                 final color = Color(int.parse(activity.color.replaceAll('#', '0xFF')));
                 
                 return _buildListItem(context, ref, activity, color);
               },
             );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (_, __) => const Center(child: Text('Error')),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, WidgetRef ref, ActivityType activity, Color color) {
    // Using Dismissible for delete
    return Dismissible(
      key: ValueKey(activity.id),
      direction: DismissDirection.endToStart,
      background: Container(
         color: CupertinoColors.destructiveRed,
         alignment: Alignment.centerRight,
         padding: const EdgeInsets.only(right: 20),
         child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
      ),
      confirmDismiss: (direction) async {
         // Ask for confirmation? Or just delete?
         // Deleting activity might affect sessions. Repository handles validation?
         // Repository checks if used.
         try {
            await ref.read(deleteActivityTypeUseCaseProvider).call(activity.id);
            return true; // Dismiss if success
         } catch (e) {
            // Show error if failed (e.g. used)
            // Need context.
            showCupertinoDialog(
              context: context, 
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('Cannot Delete'),
                content: const Text('This activity is used in validation history or sessions.'),
                actions: [
                  CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(ctx)),
                ],
              )
            );
            return false;
         }
      },
      child: Container(
        color: CupertinoColors.systemBackground, // White background for item
        child: CupertinoListTile( // Need to import or create custom? CupertinoListTile is available in updated Flutter.
           // However standard Flutter might not have CupertinoListTile in older versions?
           // SDK ^3.10.0 should have it. Can check.
           // If not, use standard Container + Row.
           // Let's assume Container + Row to be safe and "Soft UI"
           
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
           leading: Container(
             width: 24, 
             height: 24, 
             decoration: BoxDecoration(color: color, shape: BoxShape.circle)
           ),
           title: Text(activity.name, style: const TextStyle(fontSize: 17, color: TempoDesign.textPrimary)),
           trailing: const Icon(CupertinoIcons.bars, color: CupertinoColors.systemGrey3), // Drag handle visual
           onTap: () {
             // Edit
             showCupertinoModalPopup(
               context: context,
               builder: (context) => ActivityEditorDialog(activityToEdit: activity),
             );
           },
        ),
      ),
    );
  }
}

// Minimal CupertinoListTile fallback if not present (simpler to just inline Row)
class CupertinoListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget trailing;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;

  const CupertinoListTile({required this.leading, required this.title, required this.trailing, required this.onTap, required this.padding});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
       onTap: onTap,
       behavior: HitTestBehavior.opaque,
       child: Padding(
         padding: padding,
         child: Row(
           children: [
             leading,
             const SizedBox(width: 12),
             Expanded(child: title),
             trailing,
           ],
         ),
       ),
    );
  }
}
