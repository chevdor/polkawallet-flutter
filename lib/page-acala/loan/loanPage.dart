import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polka_wallet/common/consts/settings.dart';
import 'package:polka_wallet/page-acala/loan/loanAdjustPage.dart';
import 'package:polka_wallet/page-acala/loan/loanCard.dart';
import 'package:polka_wallet/page-acala/loan/loanChart.dart';
import 'package:polka_wallet/service/substrateApi/api.dart';
import 'package:polka_wallet/store/acala/acala.dart';
import 'package:polka_wallet/store/app.dart';
import 'package:polka_wallet/utils/UI.dart';
import 'package:polka_wallet/utils/format.dart';
import 'package:polka_wallet/utils/i18n/index.dart';

class LoanPage extends StatefulWidget {
  LoanPage(this.store);

  static const String route = '/acala/loan';
  final AppStore store;

  @override
  _LoanPageState createState() => _LoanPageState(store);
}

class _LoanPageState extends State<LoanPage> {
  _LoanPageState(this.store);

  final AppStore store;

  String _tab = 'DOT';

  Future<void> _fetchData() async {
    print('refresh');
    await Future.wait([
      webApi.acala.fetchLoanTypes(),
      webApi.acala.fetchPrices(),
    ]);
    webApi.acala.fetchAccountLoans();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globalLoanRefreshKey.currentState.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map dic = I18n.of(context).acala;
    bool haveLoan = true;
    return Scaffold(
      appBar: AppBar(title: Text(dic['loan.title']), centerTitle: true),
      body: Observer(
        builder: (_) {
          LoanData loan = store.acala.loans[_tab];

          Color cardColor = Theme.of(context).cardColor;
          Color primaryColor = Theme.of(context).primaryColor;
          return SafeArea(
            child: RefreshIndicator(
                key: globalLoanRefreshKey,
                onRefresh: _fetchData,
                child: Column(
                  children: <Widget>[
                    CurrencyTab(store.acala.loanTypes, _tab, store.acala.prices,
                        (i) {
                      setState(() {
                        _tab = i;
                      });
                    }),
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          loan.collaterals > BigInt.zero
                              ? LoanCard(loan)
                              : Container(),
                          loan.debitAmount == BigInt.zero
                              ? LoanChart(loan)
                              : Container()
                        ],
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            color: Colors.blue,
                            child: FlatButton(
                              padding: EdgeInsets.only(top: 16, bottom: 16),
                              child: Text(
                                dic['loan.borrow'],
                                style: TextStyle(color: cardColor),
                              ),
                              onPressed: () => Navigator.of(context).pushNamed(
                                  LoanAdjustPage.route,
                                  arguments: 'borrow'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: primaryColor,
                            child: FlatButton(
                              padding: EdgeInsets.only(top: 16, bottom: 16),
                              child: Text(
                                dic['loan.payback'],
                                style: TextStyle(color: cardColor),
                              ),
                              onPressed: () => Navigator.of(context).pushNamed(
                                  LoanAdjustPage.route,
                                  arguments: 'payback'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
          );
        },
      ),
    );
  }
}

class CurrencyTab extends StatelessWidget {
  CurrencyTab(this.tabs, this.activeTab, this.prices, this.onTabChange);
  final String activeTab;
  final List<LoanType> tabs;
  final Map<String, BigInt> prices;
  final Function(String) onTabChange;

  @override
  Widget build(BuildContext context) {
    final Map dic = I18n.of(context).acala;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16.0, // has the effect of softening the shadow
            spreadRadius: 4.0, // has the effect of extending the shadow
            offset: Offset(
              2.0, // horizontal, move right 10
              2.0, // vertical, move down 10
            ),
          )
        ],
      ),
      child: Row(
        children: tabs.map((i) {
          String price =
              Fmt.token(prices[i.token], decimals: acala_token_decimals);
          return Expanded(
            child: GestureDetector(
              child: Container(
                  padding: EdgeInsets.only(top: 8, bottom: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: activeTab == i.token
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).cardColor,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 32,
                        margin: EdgeInsets.only(right: 8),
                        child: activeTab == i.token
                            ? Image.asset('assets/images/assets/${i.token}.png')
                            : Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).dividerColor,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(32),
                                  ),
                                ),
                              ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            i.token,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: activeTab == i.token
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).unselectedWidgetColor,
                            ),
                          ),
                          Text(
                            '\$$price',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).unselectedWidgetColor,
                            ),
                          )
                        ],
                      )
                    ],
                  )),
              onTap: () {
                if (activeTab != i.token) {
                  onTabChange(i.token);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
