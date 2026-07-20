import 'package:flutter/material.dart';
import '../../../services/kendaraan_service.dart';
import '../../../layout/main_layout.dart';
import 'package:intl/intl.dart';
import 'history_log_detail_page.dart';

class HistoryLogPage extends StatefulWidget {
  const HistoryLogPage({super.key});

  @override
  State<HistoryLogPage> createState() => _HistoryLogPageState();
}

class _HistoryLogPageState extends State<HistoryLogPage> {
  List<dynamic> _allHistory = [];
  List<dynamic> _filteredHistory = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await KendaraanService.getHistoryLog();
      if (!mounted) return;
      setState(() {
        _allHistory = List<dynamic>.from(history)
          ..sort(_compareHistoryNewestFirst);
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  int _compareHistoryNewestFirst(dynamic first, dynamic second) {
    final firstDate = _historyDate(first);
    final secondDate = _historyDate(second);

    if (firstDate != null && secondDate != null) {
      final dateComparison = secondDate.compareTo(firstDate);
      if (dateComparison != 0) return dateComparison;
    } else if (firstDate != null) {
      return -1;
    } else if (secondDate != null) {
      return 1;
    }

    final firstId = int.tryParse(first['id']?.toString() ?? '') ?? 0;
    final secondId = int.tryParse(second['id']?.toString() ?? '') ?? 0;
    return secondId.compareTo(firstId);
  }

  DateTime? _historyDate(dynamic item) {
    final value = item['created_at']?.toString().trim();
    if (value == null || value.isEmpty) return null;

    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;

    for (final format in const [
      'yyyy-MM-dd HH:mm:ss',
      'dd-MM-yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm:ss',
    ]) {
      try {
        return DateFormat(format).parseStrict(value);
      } catch (_) {}
    }
    return null;
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredHistory = List.from(_allHistory);
    } else {
      _filteredHistory = _allHistory.where((item) {
        final itemQuery = (item['query'] ?? '').toString().toLowerCase();
        final rawDate = (item['created_at'] ?? '').toString().toLowerCase();
        final date = _historyDate(item);
        final searchableDates = date == null
            ? rawDate
            : [
                rawDate,
                DateFormat('dd MMM yyyy, HH:mm').format(date),
                DateFormat('dd MMM yyyy').format(date),
                DateFormat('dd/MM/yyyy').format(date),
                DateFormat('dd-MM-yyyy').format(date),
                DateFormat('yyyy-MM-dd').format(date),
                DateFormat('HH:mm').format(date),
              ].join(' ').toLowerCase();

        return itemQuery.contains(query) || searchableDates.contains(query);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      activeIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Riwayat Pencarian",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _applyFilter();
                    }
                  });
                },
              ),
            ],
          ),
          if (_isSearching) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Cari nomor polisi atau tanggal...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(_applyFilter);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => setState(_applyFilter),
            ),
          ],
          const SizedBox(height: 0),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _fetchHistory,
                child: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredHistory.isEmpty) {
      final hasSearchQuery = _searchController.text.trim().isNotEmpty;
      return Center(
        child: Text(
          hasSearchQuery
              ? "Tidak ada hasil untuk \"${_searchController.text.trim()}\"."
              : "Belum ada riwayat pencarian.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView.separated(
        itemCount: _filteredHistory.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final item = _filteredHistory[index];
          final query = item['query'] ?? "-";
          final dateStr = item['created_at'] ?? "";
          String formattedDate = "-";

          if (dateStr.isNotEmpty) {
            try {
              final date = DateTime.parse(dateStr);
              formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
            } catch (_) {
              formattedDate = dateStr;
            }
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4, // Padding kanan dan kiri
              vertical: 0,
            ),
            leading: const CircleAvatar(child: Icon(Icons.search, size: 20)),
            title: Text(
              query,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            subtitle: Text(
              formattedDate,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 28),
            onTap: () {
              final id = int.tryParse(item['id']?.toString() ?? '');
              if (id != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryLogDetailPage(
                      logId: id,
                      initialData: item is Map
                          ? Map<String, dynamic>.from(item)
                          : null,
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
