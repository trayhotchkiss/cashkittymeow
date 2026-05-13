import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'myprovider.dart';

class TutorialScreen extends StatefulWidget {
  final bool canSkip;

  TutorialScreen({this.canSkip = true});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  final List<_TutorialPage> _pages = [
    _TutorialPage(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Create manual accounts',
      body:
          'Add bank accounts, credit cards, and loans. CashCheetah stays local-only and never connects to a bank.',
    ),
    _TutorialPage(
      icon: Icons.swap_vert,
      title: 'Choose the transaction action',
      body:
          'Use Deposit or Withdrawal/Purchase for bank accounts. Use Payment or Charge for credit cards and loans.',
    ),
    _TutorialPage(
      icon: Icons.add_card,
      title: 'Enter positive amounts',
      body:
          'You type the amount as a positive number. The app applies the balance change internally.',
    ),
    _TutorialPage(
      icon: Icons.sell_outlined,
      title: 'Organize with categories',
      body:
          'Categories like Food, Bills, Gas, Rent, and Paycheck help with simple stats. They do not change balance math.',
    ),
    _TutorialPage(
      icon: Icons.bar_chart,
      title: 'Check stats from the drawer',
      body:
          'Open Stats to see cash, debt, net, per-account totals, and spending by category.',
    ),
    _TutorialPage(
      icon: Icons.file_upload_outlined,
      title: 'Back up your data',
      body:
          'Use Settings to export or restore a JSON backup. Restoring a backup replaces the current local data.',
    ),
  ];

  bool get _isLastPage => _pageIndex == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quick Tour'),
        actions: [
          if (widget.canSkip)
            TextButton(
              onPressed: _finishTutorial,
              child: Text('Skip'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _pageIndex = index),
              itemBuilder: (context, index) {
                final page = _pages[index];
                return SafeArea(
                  top: false,
                  bottom: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final minHeight = constraints.maxHeight > 48
                          ? constraints.maxHeight - 48
                          : 0.0;
                      return SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: minHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(page.icon, size: 72),
                              SizedBox(height: 24),
                              Text(
                                page.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                page.body,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: _PageDots(
                      pageCount: _pages.length,
                      selectedIndex: _pageIndex,
                    ),
                  ),
                  FilledButton(
                    onPressed: _isLastPage ? _finishTutorial : _nextPage,
                    child: Text(_isLastPage ? 'Done' : 'Next'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _controller.nextPage(
      duration: Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finishTutorial() async {
    await context.read<AccountProvider>().completeTutorial();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _PageDots extends StatelessWidget {
  final int pageCount;
  final int selectedIndex;

  _PageDots({required this.pageCount, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(pageCount, (index) {
        final selected = index == selectedIndex;
        return AnimatedContainer(
          duration: Duration(milliseconds: 180),
          width: selected ? 18 : 8,
          height: 8,
          margin: EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).primaryColor : Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _TutorialPage {
  final IconData icon;
  final String title;
  final String body;

  _TutorialPage({
    required this.icon,
    required this.title,
    required this.body,
  });
}
