import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/localization/l10n_ext.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:expo_spot/features/group/widgets/group_member_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<void> showCreateGroupSheet(BuildContext context) async {
  await context.setLocale(context.locale);
  if (!context.mounted) return;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const CreateGroupSheet(),
  );
}

class CreateGroupSheet extends ConsumerStatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  ConsumerState<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<CreateGroupSheet> {
  final _nameController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onCreateGroup() async {
    if (_creating) return;
    setState(() => _creating = true);
    HapticFeedback.mediumImpact();
    ref.read(activeGroupProvider.notifier).createNewGroup(
          displayName: _nameController.text,
        );
    if (mounted) setState(() => _creating = false);
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.92;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border),
          ),
          child: group.sessionActive
              ? ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxSheetHeight),
                  child: _InviteAndMembersView(group: group, bottomSafe: bottomSafe),
                )
              : _CreateGroupForm(
                  nameController: _nameController,
                  creating: _creating,
                  onCreate: _onCreateGroup,
                  bottomSafe: bottomSafe,
                ),
        ),
      ),
    );
  }
}

class _CreateGroupForm extends StatelessWidget {
  const _CreateGroupForm({
    required this.nameController,
    required this.creating,
    required this.onCreate,
    required this.bottomSafe,
  });

  final TextEditingController nameController;
  final bool creating;
  final VoidCallback onCreate;
  final double bottomSafe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 20 + bottomSafe),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 18),
          Text(
            context.l10n('create_group_step_title', fallbackKey: 'create_group'),
            style: AppTypography.display(context).copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n('create_group_step_sub', fallbackKey: 'hero_subtitle'),
            style: AppTypography.subtitle(context),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onCreate(),
            decoration: InputDecoration(
              hintText: context.l10n(
                'create_group_name_hint',
                fallbackKey: 'create_group_modal_title',
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
                borderSide: const BorderSide(color: AppColors.keppelGreen, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Material(
            color: AppColors.bottleGreen,
            borderRadius: BorderRadius.circular(AppRadii.button),
            child: InkWell(
              onTap: creating ? null : onCreate,
              borderRadius: BorderRadius.circular(AppRadii.button),
              child: SizedBox(
                height: 52,
                child: Center(
                  child: creating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.l10n(
                            'create_group_confirm',
                            fallbackKey: 'continue_action',
                          ),
                          style: AppTypography.button(context).copyWith(color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteAndMembersView extends StatelessWidget {
  const _InviteAndMembersView({
    required this.group,
    required this.bottomSafe,
  });

  final ActiveGroupState group;
  final double bottomSafe;

  @override
  Widget build(BuildContext context) {
    final link = 'https://expospot.local/join/${group.inviteCode}';
    final custom = group.customGroupName?.trim();
    final title = (custom != null && custom.isNotEmpty)
        ? custom
        : context.l10n(group.groupNameKey, fallbackKey: 'create_group_modal_title');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: AppTypography.display(context).copyWith(fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n('create_group_modal_sub'),
                  style: AppTypography.subtitle(context),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: QrImageView(
                      data: link,
                      size: 168,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.bottleGreen,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.bottleGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  group.inviteCode,
                  textAlign: TextAlign.center,
                  style: AppTypography.englishMetric(context).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      context.l10n(
                        'create_group_members_title',
                        fallbackKey: 'map_members_title',
                      ),
                      style: AppTypography.display(context).copyWith(fontSize: 16),
                    ),
                    const Spacer(),
                    Text(
                      'map_member_count'.tr(namedArgs: {
                        'online': '${group.onlineCount}',
                        'total': '${group.totalMembers}',
                      }),
                      style: AppTypography.label(context).copyWith(
                        color: AppColors.keppelGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (group.members.length <= 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      context.l10n(
                        'create_group_members_waiting',
                        fallbackKey: 'group_visitors_status',
                      ),
                      style: AppTypography.label(context).copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                for (final member in group.members) ...[
                  GroupMemberTile(member: member, compact: true),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomSafe),
          child: Material(
            color: AppColors.bottleGreen,
            borderRadius: BorderRadius.circular(AppRadii.button),
            child: InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('link_copied'.tr()),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.bottleGreen,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(AppRadii.button),
              child: SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    'copy_invite_link'.tr(),
                    style: AppTypography.button(context).copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
