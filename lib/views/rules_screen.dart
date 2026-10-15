import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/rules.dart';
import 'package:poka_fugou_app/constants/strings.dart';

/// ルール画面（ポカ富豪 / ポーカー / 大富豪 をタブで切り替え）
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.rulesTitle),
          bottom: const TabBar(
            tabs: [
              Tab(text: AppStrings.appTitle),
              Tab(text: AppStrings.pokerTitle),
              Tab(text: AppStrings.daifugoTitle),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RuleList(sections: Rules.pokaFugou),
            _RuleList(sections: Rules.poker),
            _RuleList(sections: Rules.daifugo),
          ],
        ),
      ),
    );
  }
}

/// 1 タブ分のルール一覧
class _RuleList extends StatelessWidget {
  final List<RuleSection> sections;

  const _RuleList({required this.sections});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (context, index) => _RuleSectionView(sections[index]),
    );
  }
}

/// 見出し・箇条書き・表を縦に並べる
class _RuleSectionView extends StatelessWidget {
  final RuleSection section;

  const _RuleSectionView(this.section);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final note = section.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        for (final line in section.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('・'),
                Expanded(child: Text(line)),
              ],
            ),
          ),
        if (section.table.isNotEmpty) ...[
          const SizedBox(height: 4),
          _table(context),
        ],
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(note, style: textTheme.bodySmall),
        ],
      ],
    );
  }

  Widget _table(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rows = section.table;
    return Table(
      border: TableBorder.all(color: colors.outlineVariant),
      columnWidths: rows.first.length == 2
          ? const {0: IntrinsicColumnWidth()}
          : null,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (int i = 0; i < rows.length; i++)
          TableRow(
            decoration: i == 0
                ? BoxDecoration(color: colors.surfaceContainerHighest)
                : null,
            children: [
              for (final cell in rows[i])
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    cell,
                    style: i == 0
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
