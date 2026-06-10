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
        _allHistory = history;
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

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredHistory = List.from(_allHistory);
    } else {
      _filteredHistory = _allHistory.where((item) {
        final itemQuery = (item['query'] ?? '').toString().toLowerCase();
        return itemQuery.contains(query);
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
                hintText: "Cari nomor polisi...",
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
          const SizedBox(height: 12),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
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
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
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
            leading: const CircleAvatar(child: Icon(Icons.search)),
            title: Text(
              query,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(formattedDate),
            trailing: const Icon(Icons.chevron_right, size: 16),
            onTap: () {
              final id = item['id'];
              if (id != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryLogDetailPage(logId: id),
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
