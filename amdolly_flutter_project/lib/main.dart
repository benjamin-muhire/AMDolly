import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SMCJournalApp());
}

const ink = Color(0xFF0B1220);
const panel = Color(0xFF121D2E);
const panel2 = Color(0xFF1B2940);
const mint = Color(0xFF39D6A4);
const red = Color(0xFFFF7185);
const muted = Color(0xFF9AAAC0);

class TradeEntry {
  TradeEntry({
    required this.id,
    required this.date,
    required this.symbol,
    required this.direction,
    required this.session,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit,
    required this.result,
    required this.riskPercent,
    required this.setup,
    required this.notes,
    required this.confluences,
    required this.followedPlan,
  });

  final String id;
  final String date;
  final String symbol;
  final String direction;
  final String session;
  final double entry;
  final double stopLoss;
  final double takeProfit;
  final double result;
  final double riskPercent;
  final String setup;
  final String notes;
  final List<String> confluences;
  final bool followedPlan;

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date, 'symbol': symbol, 'direction': direction,
    'session': session, 'entry': entry, 'stopLoss': stopLoss,
    'takeProfit': takeProfit, 'result': result, 'riskPercent': riskPercent,
    'setup': setup, 'notes': notes, 'confluences': confluences,
    'followedPlan': followedPlan,
  };

  factory TradeEntry.fromJson(Map<String, dynamic> j) => TradeEntry(
    id: j['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
    date: j['date'] ?? '',
    symbol: j['symbol'] ?? 'XAUUSD',
    direction: j['direction'] ?? 'Buy',
    session: j['session'] ?? 'London',
    entry: (j['entry'] as num? ?? 0).toDouble(),
    stopLoss: (j['stopLoss'] as num? ?? 0).toDouble(),
    takeProfit: (j['takeProfit'] as num? ?? 0).toDouble(),
    result: (j['result'] as num? ?? 0).toDouble(),
    riskPercent: (j['riskPercent'] as num? ?? 1).toDouble(),
    setup: j['setup'] ?? '',
    notes: j['notes'] ?? '',
    confluences: List<String>.from(j['confluences'] ?? const []),
    followedPlan: j['followedPlan'] ?? true,
  );
}

class JournalStore extends ChangeNotifier {
  static const _key = 'amdollarfx_smc_trades_v1';
  final List<TradeEntry> trades = [];
  bool loaded = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        trades
          ..clear()
          ..addAll(list.map((e) => TradeEntry.fromJson(Map<String, dynamic>.from(e))));
      } catch (_) {
        // A corrupted saved record should not prevent the journal from opening.
      }
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> add(TradeEntry trade) async {
    trades.insert(0, trade);
    await _save();
  }

  Future<void> delete(String id) async {
    trades.removeWhere((t) => t.id == id);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(trades.map((t) => t.toJson()).toList()));
    notifyListeners();
  }
}

class SMCJournalApp extends StatefulWidget {
  const SMCJournalApp({super.key});
  @override
  State<SMCJournalApp> createState() => _SMCJournalAppState();
}

class _SMCJournalAppState extends State<SMCJournalApp> {
  final store = JournalStore();
  int tab = 0;

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AMDolly',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: ink,
          colorScheme: ColorScheme.fromSeed(seedColor: mint, brightness: Brightness.dark),
          appBarTheme: const AppBarTheme(backgroundColor: ink, foregroundColor: Colors.white),
          inputDecorationTheme: InputDecorationTheme(
            filled: true, fillColor: panel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF263750))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: mint)),
            labelStyle: const TextStyle(color: muted),
          ),
        ),
        home: !store.loaded
          ? const Scaffold(body: Center(child: CircularProgressIndicator(color: mint)))
          : Scaffold(
              body: SafeArea(
                child: IndexedStack(
                  index: tab,
                  children: [
                    DashboardPage(store: store, onAdd: () => _openAdd(context)),
                    HistoryPage(store: store),
                    PlaybookPage(),
                  ],
                ),
              ),
              floatingActionButton: tab == 0 || tab == 1
                ? FloatingActionButton.extended(
                    onPressed: () => _openAdd(context),
                    backgroundColor: mint, foregroundColor: ink,
                    icon: const Icon(Icons.add_chart), label: const Text('Log trade', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                : null,
              bottomNavigationBar: NavigationBar(
                backgroundColor: panel,
                indicatorColor: mint.withOpacity(.18),
                selectedIndex: tab,
                onDestinationSelected: (i) => setState(() => tab = i),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Overview'),
                  NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Trades'),
                  NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'SMC playbook'),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final result = await Navigator.of(context).push<TradeEntry>(
      MaterialPageRoute(builder: (_) => AddTradePage()),
    );
    if (result != null) await store.add(result);
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.store, required this.onAdd});
  final JournalStore store;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final trades = store.trades;
    final wins = trades.where((t) => t.result > 0).length;
    final losses = trades.where((t) => t.result < 0).length;
    final netR = trades.fold<double>(0, (sum, t) => sum + t.result);
    final winRate = trades.isEmpty ? 0.0 : wins / trades.length * 100;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset('assets/amdolly_logo.png', width: 48, height: 48, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AMDolly', style: TextStyle(fontSize: 13, color: mint, letterSpacing: 1.6, fontWeight: FontWeight.bold)),
                  Text('Trading journal', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                ])),
                const Icon(Icons.shield_moon_outlined, color: muted),
              ]),
              const SizedBox(height: 22),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [Color(0xFF173B43), Color(0xFF14243A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(color: mint.withOpacity(.23)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('YOUR EXECUTION SCORECARD', style: TextStyle(color: mint, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('${netR >= 0 ? '+' : ''}${netR.toStringAsFixed(2)}R', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
                  const Text('Net result in R · based on results you record', style: TextStyle(color: muted, fontSize: 12)),
                  const SizedBox(height: 18),
                  Row(children: [
                    _metric('Win rate', '${winRate.toStringAsFixed(0)}%'),
                    _metric('Wins', '$wins'),
                    _metric('Losses', '$losses'),
                    _metric('Trades', '${trades.length}'),
                  ]),
                ]),
              ),
              const SizedBox(height: 22),
              const Text('Market focus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _marketCard('XAUUSD', 'Gold', Icons.auto_awesome, const Color(0xFFFFD166))),
                const SizedBox(width: 12),
                Expanded(child: _marketCard('BTCUSD', 'Bitcoin', Icons.currency_bitcoin, const Color(0xFFFFA45B))),
              ]),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Recent trades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${trades.length} logged', style: const TextStyle(color: muted, fontSize: 12)),
              ]),
              const SizedBox(height: 10),
            ]),
          ),
        ),
        if (trades.isEmpty)
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
            child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                const Icon(Icons.edit_note, size: 42, color: mint),
                const SizedBox(height: 10),
                const Text('Your journal starts here', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                const Text('Record the setup, confluences, outcome and lesson—not just the profit.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.4)),
                const SizedBox(height: 14),
                FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Log your first trade')),
              ]),
            ),
          ))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (context, i) => TradeTile(trade: trades[i]),
              childCount: trades.length > 4 ? 4 : trades.length,
            )),
          ),
      ],
    );
  }

  Widget _metric(String label, String value) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 3), Text(label, style: const TextStyle(color: muted, fontSize: 10)),
  ]));

  Widget _marketCard(String symbol, String name, IconData icon, Color accent) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: accent.withOpacity(.25))),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: accent.withOpacity(.13), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: accent)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(name, style: const TextStyle(color: muted, fontSize: 11)),
      ]),
    ]),
  );
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.store});
  final JournalStore store;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
        child: Row(children: [
          Icon(Icons.receipt_long, color: mint, size: 28), SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Trade history', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text('Review your decisions and execution', style: TextStyle(color: muted, fontSize: 12)),
          ])),
        ]),
      ),
      Expanded(child: store.trades.isEmpty
        ? const EmptyState(icon: Icons.history, title: 'No trades yet', subtitle: 'Use “Log trade” to record your first setup.')
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: store.trades.length,
            itemBuilder: (context, i) {
              final t = store.trades[i];
              return Dismissible(
                key: ValueKey(t.id),
                direction: DismissDirection.endToStart,
                background: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight, decoration: BoxDecoration(color: red.withOpacity(.18), borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.delete_outline, color: red)),
                confirmDismiss: (_) async => await showDialog<bool>(
                  context: context, builder: (ctx) => AlertDialog(
                    title: const Text('Delete trade?'),
                    content: const Text('This removes the trade from this device.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                    ],
                  ),
                ) ?? false,
                onDismissed: (_) => store.delete(t.id),
                child: TradeTile(trade: t, expanded: true),
              );
            },
          )),
    ]);
  }
}

class TradeTile extends StatelessWidget {
  const TradeTile({super.key, required this.trade, this.expanded = false});
  final TradeEntry trade;
  final bool expanded;
  @override
  Widget build(BuildContext context) {
    final positive = trade.result >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: panel2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: panel2, borderRadius: BorderRadius.circular(10)),
            child: Text(trade.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          const SizedBox(width: 8),
          Text(trade.direction.toUpperCase(), style: TextStyle(color: trade.direction == 'Buy' ? mint : red, fontSize: 11, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${trade.result >= 0 ? '+' : ''}${trade.result.toStringAsFixed(2)}R', style: TextStyle(color: positive ? mint : red, fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        const SizedBox(height: 10),
        Text(trade.setup.isEmpty ? 'SMC setup' : trade.setup, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Text('${trade.date} · ${trade.session} session · Risk ${trade.riskPercent.toStringAsFixed(1)}%', style: const TextStyle(color: muted, fontSize: 11)),
        if (expanded) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: trade.confluences.map((c) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: mint.withOpacity(.09), borderRadius: BorderRadius.circular(8)),
            child: Text(c, style: const TextStyle(color: mint, fontSize: 10)),
          )).toList()),
          const SizedBox(height: 10),
          Text('Entry ${trade.entry}  ·  SL ${trade.stopLoss}  ·  TP ${trade.takeProfit}', style: const TextStyle(color: muted, fontSize: 11)),
          if (trade.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(trade.notes, style: const TextStyle(height: 1.4)),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Icon(trade.followedPlan ? Icons.check_circle_outline : Icons.warning_amber_rounded, size: 16, color: trade.followedPlan ? mint : red),
            const SizedBox(width: 6),
            Text(trade.followedPlan ? 'Followed my plan' : 'Broke my plan', style: TextStyle(fontSize: 11, color: trade.followedPlan ? mint : red)),
          ]),
        ],
      ]),
    );
  }
}

class AddTradePage extends StatefulWidget {
  @override
  State<AddTradePage> createState() => _AddTradePageState();
}

class _AddTradePageState extends State<AddTradePage> {
  final formKey = GlobalKey<FormState>();
  final entryC = TextEditingController();
  final slC = TextEditingController();
  final tpC = TextEditingController();
  final resultC = TextEditingController(text: '0');
  final riskC = TextEditingController(text: '1');
  final setupC = TextEditingController();
  final notesC = TextEditingController();
  String symbol = 'XAUUSD';
  String direction = 'Buy';
  String session = 'London';
  DateTime date = DateTime.now();
  bool followedPlan = true;
  final selected = <String>{};
  final confluences = const [
    'Higher-timeframe bias', 'Liquidity sweep', 'BOS / CHoCH',
    'Order block', 'Fair value gap', 'Premium / discount',
    'Session timing', 'Displacement', 'Retest / entry trigger',
    'Clear invalidation', 'Risk-to-reward checked',
  ];

  @override
  void dispose() {
    for (final c in [entryC, slC, tpC, resultC, riskC, setupC, notesC]) { c.dispose(); }
    super.dispose();
  }

  double _number(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
  String? _requiredNumber(String? v) {
    if (v == null || v.trim().isEmpty || double.tryParse(v.trim()) == null) return 'Enter a valid number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log a trade'), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
          children: [
            const SectionTitle('01 · Trade details', 'Record the facts first.'),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: symbol, decoration: const InputDecoration(labelText: 'Market'),
                items: const [DropdownMenuItem(value: 'XAUUSD', child: Text('XAUUSD · Gold')), DropdownMenuItem(value: 'BTCUSD', child: Text('BTCUSD · Bitcoin'))],
                onChanged: (v) => setState(() => symbol = v ?? symbol))),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(value: direction, decoration: const InputDecoration(labelText: 'Direction'),
                items: const [DropdownMenuItem(value: 'Buy', child: Text('Buy / Long')), DropdownMenuItem(value: 'Sell', child: Text('Sell / Short'))],
                onChanged: (v) => setState(() => direction = v ?? direction))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: session, decoration: const InputDecoration(labelText: 'Session'),
                items: const [DropdownMenuItem(value: 'Asia', child: Text('Asia')), DropdownMenuItem(value: 'London', child: Text('London')), DropdownMenuItem(value: 'New York', child: Text('New York')), DropdownMenuItem(value: 'Other', child: Text('Other'))],
                onChanged: (v) => setState(() => session = v ?? session))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 17), foregroundColor: Colors.white, side: const BorderSide(color: Color(0xFF263750))),
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (d != null) setState(() => date = d);
                },
                icon: const Icon(Icons.calendar_today, size: 16), label: Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
              )),
            ]),
            const SizedBox(height: 12),
            TextFormField(controller: setupC, decoration: const InputDecoration(labelText: 'Setup name', hintText: 'e.g. London liquidity sweep + FVG')),
            const SizedBox(height: 12),
            const SectionTitle('02 · Price & risk', 'Use your broker’s quoted prices.'),
            Row(children: [
              Expanded(child: TextFormField(controller: entryC, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _requiredNumber, decoration: const InputDecoration(labelText: 'Entry price'))),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: slC, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _requiredNumber, decoration: const InputDecoration(labelText: 'Stop loss'))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: tpC, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _requiredNumber, decoration: const InputDecoration(labelText: 'Take profit'))),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: riskC, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _requiredNumber, decoration: const InputDecoration(labelText: 'Risk (%)'))),
            ]),
            const SizedBox(height: 12),
            TextFormField(controller: resultC, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), validator: _requiredNumber,
              decoration: const InputDecoration(labelText: 'Outcome in R', helperText: 'Examples: 2 = +2R win · -1 = -1R loss · 0 = breakeven')),
            const SizedBox(height: 20),
            const SectionTitle('03 · SMC confluences', 'Select only what was actually present.'),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)),
              child: Column(children: confluences.map((c) => CheckboxListTile(
                dense: true, contentPadding: EdgeInsets.zero, activeColor: mint,
                title: Text(c, style: const TextStyle(fontSize: 13)),
                value: selected.contains(c),
                onChanged: (v) => setState(() { if (v == true) { selected.add(c); } else { selected.remove(c); } }),
              )).toList()),
            ),
            const SizedBox(height: 18),
            const SectionTitle('04 · Review', 'Build discipline by reviewing your process.'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero, activeColor: mint, value: followedPlan,
              title: const Text('I followed my trading plan', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Be honest—even a winning rule-break is worth reviewing.', style: TextStyle(color: muted, fontSize: 11)),
              onChanged: (v) => setState(() => followedPlan = v),
            ),
            const SizedBox(height: 10),
            TextFormField(controller: notesC, maxLines: 4, decoration: const InputDecoration(labelText: 'Notes & lesson learned', hintText: 'What did you see? What confirmed the idea? What would you improve?')),
            const SizedBox(height: 22),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: mint, foregroundColor: ink, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final t = TradeEntry(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  symbol: symbol, direction: direction, session: session,
                  entry: _number(entryC), stopLoss: _number(slC), takeProfit: _number(tpC),
                  result: _number(resultC), riskPercent: _number(riskC), setup: setupC.text.trim(),
                  notes: notesC.text.trim(), confluences: selected.toList(), followedPlan: followedPlan,
                );
                Navigator.pop(context, t);
              },
              icon: const Icon(Icons.save_outlined), label: const Text('Save trade to journal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            const Text('Stored locally on this device. Back up your data before uninstalling the app.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class PlaybookPage extends StatelessWidget {
  PlaybookPage({super.key});
  final items = const [
    ('Higher-timeframe bias', 'Start with context: trend, range, key highs/lows and meaningful dealing ranges.'),
    ('POI + consolidation', 'Mark a meaningful point of interest (order block, fair value gap or key level). Wait for price to stall or consolidate there; define the range high and low. Consolidation alone is not an entry signal.'),
    ('False break / liquidity grab', 'Watch for price to briefly break one side of the consolidation, take nearby liquidity, then close back inside the range. A wick alone is not proof; wait for your planned confirmation.'),
    ('Reversal confirmation', 'Look for displacement away from the false break and, where applicable, a BOS / CHoCH or a fresh fair value gap in the intended direction. Do not assume every sweep reverses.'),
    ('Entry & invalidation', 'Plan the entry trigger after confirmation. Define invalidation beyond the sweep extreme and calculate position size before entry. If the setup is unclear, skip it.'),
    ('Premium / discount', 'Use the relevant dealing range as context, not as a standalone entry signal.'),
    ('Risk & execution', 'Set the stop where the idea is invalidated, calculate position size, and respect your pre-defined risk limit.'),
    ('Post-trade review', 'Record which confluences were present, whether you followed the plan, and one specific lesson. Judge process as well as outcome.'),
  ];

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
    SliverToBoxAdapter(child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.menu_book, color: mint, size: 28), SizedBox(width: 10), Text('SMC playbook', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 8),
        const Text('A repeatable checklist for your XAUUSD and BTCUSD process.', style: TextStyle(color: muted)),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: mint.withOpacity(.09), borderRadius: BorderRadius.circular(18), border: Border.all(color: mint.withOpacity(.22))),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.filter_alt_outlined, color: mint, size: 24), SizedBox(width: 12),
            Expanded(child: Text('Confluence is context, not certainty. More checked boxes do not guarantee a trade will win. Wait for a clear invalidation and a setup that fits your plan.', style: TextStyle(height: 1.45))),
          ]),
        ),
      ]),
    )),
    SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), sliver: SliverList(delegate: SliverChildBuilderDelegate(
      (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: mint.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
            child: Text('${i + 1}'.padLeft(2, '0'), style: const TextStyle(color: mint, fontWeight: FontWeight.bold, fontSize: 11))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(items[i].$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6), Text(items[i].$2, style: const TextStyle(color: muted, height: 1.45, fontSize: 12)),
          ])),
        ]),
      ),
      childCount: items.length,
    ))),
  ]);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
    ]),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(30),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 52, color: mint), const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: muted)),
    ]),
  ));
}
