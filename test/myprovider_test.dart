import 'dart:convert';

import 'package:cashcheetah/model.dart';
import 'package:cashcheetah/myprovider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loadData skips corrupt saved account records and shows a notice',
      () async {
    final validAccount = jsonEncode(
      Account(title: 'Checking', balanceCents: 1200).toJson(),
    );
    SharedPreferences.setMockInitialValues({
      'accounts': [validAccount, '{bad json'],
    });
    final provider = AccountProvider();

    await provider.loadData();

    expect(provider.accounts, hasLength(1));
    expect(provider.accounts.single.title, 'Checking');
    expect(provider.dataNotice, isNotNull);
  });

  test('loadData allows an intentionally empty saved account list', () async {
    SharedPreferences.setMockInitialValues({'accounts': <String>[]});
    final provider = AccountProvider();

    await provider.loadData();

    expect(provider.accounts, isEmpty);
    expect(provider.currentAccount, isNull);
    expect(provider.dataNotice, isNull);
  });
}
