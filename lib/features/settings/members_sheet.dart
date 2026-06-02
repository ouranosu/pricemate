import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/debug.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';

Future<void> showMembersSheet(BuildContext context, AppStore store) async {
  final spaceId = store.activeSpaceId;
  debugLog('showMembersSheet open spaceId=$spaceId');
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetTitle(title: '家族メンバー'),
              Expanded(
                child: spaceId == null
                    ? const Center(child: Text('スペースに参加していません。'))
                    : FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('sharedSpaces')
                            .doc(spaceId)
                            .collection('members')
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text('メンバーを取得できませんでした。'),
                            );
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(child: Text('メンバーはいません。'));
                          }
                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data();
                              final displayName =
                                  data['displayName'] as String? ??
                                  docs[index].id;
                              final role =
                                  data['role'] as String? ?? 'member';
                              return ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(displayName),
                                subtitle: Text(
                                  role == 'owner' ? '招待者' : 'メンバー',
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
