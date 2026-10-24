import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/reports/excel_export.dart';
import 'package:transport_hisab/features/reports/pdf_export.dart';

/// Generic report viewer with date range, vehicle filter, sticky header, horizontal scroll, totals row
class ReportViewer extends ConsumerStatefulWidget {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final List<String> totals;
  final DateTimeRange? initialDateRange;
  final List<int>? vehicleIds;
  final ValueChanged<DateTimeRange>? onDateRangeChanged;
  final Future<void> Function(DateTimeRange, int?) onExportExcel;
  final Future<void> Function(DateTimeRange, int?) onExportPdf;

  const ReportViewer({
    super.key,
    required this.title,
    required this.headers,
    required this.rows,
    required this.totals,
    this.initialDateRange,
    this.vehicleIds,
    this.onDateRangeChanged,
    required this.onExportExcel,
    required this.onExportPdf,
  });

  @override
  ConsumerState<ReportViewer> createState() => _ReportViewerState();
}

class _ReportViewerState extends ConsumerState<ReportViewer> {
  late DateTimeRange _dateRange;
  int? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initialDateRange ?? DateTimeRange(
      start: DateTime(DateTime.now().year, DateTime.now().month, 1),
      end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59),
    );
  }

  @override
  void didUpdateWidget(ReportViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDateRange != null && widget.initialDateRange != oldWidget.initialDateRange) {
      _dateRange = widget.initialDateRange!;
    }
  }

  Future<void> _showFilterDialog() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      widget.onDateRangeChanged?.call(picked);
    }
  }

  void _showExportDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.table_view),
              title: Text(l10n.exportExcel),
              onTap: () {
                Navigator.pop(context);
                widget.onExportExcel(_dateRange, _selectedVehicleId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(l10n.exportPdf),
              onTap: () {
                Navigator.pop(context);
                widget.onExportPdf(_dateRange, _selectedVehicleId);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: l10n.filter,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _showExportDialog(context),
            tooltip: l10n.export,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          _FilterBar(
            dateRange: _dateRange,
            onDateRangeChanged: (range) => setState(() => _dateRange = range),
            vehicleId: null, // TODO: Add vehicle filter
            onVehicleChanged: (id) => setState(() {}),
          ),
          // Report Table
          Expanded(
            child: _ReportTable(
              headers: widget.headers,
              rows: widget.rows,
              totals: widget.totals,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final DateTimeRange dateRange;
  final ValueChanged<DateTimeRange> onDateRangeChanged;
  final int? vehicleId;
  final ValueChanged<int?> onVehicleChanged;

  const _FilterBar({
    required this.dateRange,
    required this.onDateRangeChanged,
    this.vehicleId,
    required this.onVehicleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // Date Range
          Expanded(
            child: InkWell(
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: dateRange,
                );
                if (range != null) {
                  onDateRangeChanged(range);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${formatDate(dateRange.start, short: true)} - ${formatDate(dateRange.end, short: true)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Vehicle Filter (placeholder)
          Expanded(
            child: DropdownButtonFormField<int>(
              value: null,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.vehicleLabel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.allVehicles)),
              ],
              onChanged: (value) {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<String> totals;

  const _ReportTable({
    required this.headers,
    required this.rows,
    required this.totals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No data for selected period', style: Theme.of(context).textTheme.headlineSmall), // i18n-ignore
          ],
        ),
      );
    }

    return Column(
      children: [
        // Table with horizontal scroll
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith((states) =>
                    Theme.of(context).colorScheme.surfaceContainerHighest),
                headingRowHeight: 48,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 60,
                columnSpacing: 16,
                horizontalMargin: 16,
                columns: headers.map((h) => DataColumn(
                  label: Text(h, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                )).toList(),
                rows: rows.map((row) => DataRow(
                  cells: row.map((cell) => DataCell(Text(cell))).toList(),
                )).toList(),
              ),
            ),
          ),
        ),
        // Totals Row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Text(AppLocalizations.of(context)!.totalLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: totals.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(t, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}