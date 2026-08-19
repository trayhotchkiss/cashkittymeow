import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model.dart';
import 'myprovider.dart';

class ManageAccountsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    final accounts = provider.accounts;

    return Scaffold(
      appBar: AppBar(title: Text('Manage Accounts')),
      body: SafeArea(
        top: false,
        child: accounts.isEmpty
            ? Center(child: Text('No accounts yet.'))
            : ReorderableListView.builder(
                buildDefaultDragHandles: false,
                padding: EdgeInsets.fromLTRB(0, 8, 0, 24),
                itemCount: accounts.length,
                onReorder: provider.reorderAccount,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  final selected = index == provider.currentAccountIndex;
                  return _ManageAccountRow(
                    key: ValueKey(account),
                    account: account,
                    selected: selected,
                    index: index,
                  );
                },
              ),
      ),
    );
  }
}

class _ManageAccountRow extends StatelessWidget {
  final Account account;
  final bool selected;
  final int index;

  _ManageAccountRow({
    required super.key,
    required this.account,
    required this.selected,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: selected ? Theme.of(context).highlightColor : null,
      leading: ReorderableDragStartListener(
        index: index,
        child: Icon(Icons.drag_handle),
      ),
      title: Text(account.title),
      subtitle: Text(_subtitleText),
      trailing: selected ? Icon(Icons.check_circle_outline) : null,
    );
  }

  String get _subtitleText {
    final availableCredit = account.formattedAvailableCredit;
    if (availableCredit == null) {
      return account.accountType.label;
    }
    return '${account.accountType.label} - Available: $availableCredit';
  }
}
