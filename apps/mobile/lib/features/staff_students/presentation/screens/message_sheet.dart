import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_students_controller.dart';

/// Writes one message to the learners the roster picked. The academy decides who of them it can
/// actually reach, and answers with the count — which is what the roster then reports (§18).
Future<void> showMessageSheet(BuildContext context, {required List<String> studentIds}) =>
    showAppBottomSheet<void>(context, builder: (_) => _MessageSheet(studentIds: studentIds));

class _MessageSheet extends ConsumerWidget {
  const _MessageSheet({required this.studentIds});

  final List<String> studentIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.watch(messageDraftProvider);
    final controller = ref.read(messageDraftProvider.notifier);
    final action = ref.watch(studentActionProvider);

    return AppBottomSheet(
      title: l10n.studentsMessageTitle,
      footer: AppButton(
        label: l10n.studentsMessageSend,
        busy: action.busy,
        onPressed: draft.isReady
            ? () async {
                final sent = await ref
                    .read(studentActionProvider.notifier)
                    .message(
                      studentIds: studentIds,
                      subject: draft.subject.trim(),
                      body: draft.body.trim(),
                      channels: draft.channels,
                    );
                if (!context.mounted) return;
                if (sent) {
                  controller.reset();
                  Navigator.of(context).pop();
                }
              }
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MetaItem(icon: AppIcons.people, label: l10n.studentsSelected(studentIds.length)),
          const SizedBox(height: Space.s3),
          AppTextField(
            label: l10n.studentsMessageSubject,
            initialValue: draft.subject,
            maxLength: MessageDraft.maxSubject,
            required: true,
            onChanged: controller.writeSubject,
          ),
          const SizedBox(height: Space.s3),
          AppTextField(
            label: l10n.studentsMessageBody,
            hintText: l10n.studentsMessageBodyHint,
            helperText: draft.body.trim().isEmpty || draft.hasBody
                ? null
                : l10n.studentsMessageBodyTooShort(MessageDraft.minBody),
            initialValue: draft.body,
            minLines: 4,
            maxLines: 10,
            maxLength: MessageDraft.maxBody,
            required: true,
            onChanged: controller.writeBody,
          ),
          const SizedBox(height: Space.s3),
          Text(l10n.studentsMessageChannels, style: context.type.label),
          const SizedBox(height: Space.s1),
          // At least one channel: the route refuses a message with none, so the app does too.
          CheckboxListTile(
            value: draft.channels.contains('app'),
            title: Text(l10n.studentsMessageChannelApp),
            contentPadding: EdgeInsets.zero,
            onChanged: (_) => controller.toggleChannel('app'),
          ),
          CheckboxListTile(
            value: draft.channels.contains('email'),
            title: Text(l10n.studentsMessageChannelEmail),
            contentPadding: EdgeInsets.zero,
            onChanged: (_) => controller.toggleChannel('email'),
          ),
        ],
      ),
    );
  }
}
