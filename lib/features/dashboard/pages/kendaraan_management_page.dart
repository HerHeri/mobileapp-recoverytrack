import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../models/kendaraan.dart';
import '../../../services/admin_kendaraan_service.dart';
import '../../../services/auth_service.dart';

/// Role yang diizinkan mengakses halaman ini
const _allowedRoles = {
  'super_admin',
  'admin',
  'admin_leasing',
  'Super Admin',
  'Admin',
  'Admin Leasing',
  'super admin',
  'admin leasing',
};

class KendaraanManagementPage extends StatefulWidget {
  const KendaraanManagementPage({super.key});

  @override
  State<KendaraanManagementPage> createState() =>
      _KendaraanManagementPageState();
}

class _KendaraanManagementPageState extends State<KendaraanManagementPage> {
  // ── Profile / Role ─────────────────────────────────────────────────────────
  String? _role;
  int? _userId;
  bool _profileLoading = true;
  String? _profileError;

  // ── Data Kendaraan ─────────────────────────────────────────────────────────
  final List<KendaraanAdmin> _items = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _perPage = 10;
  bool _listLoading = false;
  bool _listLoadingMore = false;
  String? _listError;
  int _totalData = 0;

  // ── Search ─────────────────────────────────────────────────────────────────
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  // ── Scroll ─────────────────────────────────────────────────────────────────
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  bool get _isAdminLeasing =>
      _role == 'admin_leasing' ||
      _role == 'Admin Leasing' ||
      _role == 'admin leasing' ||
      _role == 'Admin' ||
      _role == 'admin' ||
      _role == 'super_admin' ||
      _role == 'Super Admin' ||
      _role == 'super admin';
  bool get _accessAllowed => _role != null && _allowedRoles.contains(_role);

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_listLoadingMore &&
        _currentPage < _lastPage) {
      _loadMore();
    }
  }

  // ── Load Profile ───────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    setState(() {
      _profileLoading = true;
      _profileError = null;
    });
    try {
      final res = await AuthService.getProfile();
      final data =
          (res['data'] as Map<String, dynamic>?) ??
          (res['user'] as Map<String, dynamic>?) ??
          res;
      setState(() {
        _role = data['role']?.toString();
        _userId = int.tryParse(data['id']?.toString() ?? '');
        _profileLoading = false;
      });
      if (_accessAllowed) _fetchKendaraan(reset: true);
    } catch (e) {
      setState(() {
        _profileError = e.toString().replaceAll('Exception: ', '');
        _profileLoading = false;
      });
    }
  }

  // ── Fetch Kendaraan ────────────────────────────────────────────────────────

  Future<void> _fetchKendaraan({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _items.clear();
    }

    setState(() {
      if (reset) {
        _listLoading = true;
        _listError = null;
      } else {
        _listLoadingMore = true;
      }
    });

    try {
      final result = await AdminKendaraanService.getKendaraan(
        q: _searchQuery.isEmpty ? null : _searchQuery,
        page: _currentPage,
      );
      setState(() {
        if (reset) _items.clear();
        _items.addAll(result.data);
        _lastPage = result.lastPage;
        _totalData = result.total;
        _listLoading = false;
        _listLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _listError = e.toString().replaceAll('Exception: ', '');
        _listLoading = false;
        _listLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_currentPage >= _lastPage) return;
    _currentPage++;
    await _fetchKendaraan();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = value.trim());
      _fetchKendaraan(reset: true);
    });
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(KendaraanAdmin item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_rounded,
            color: Theme.of(ctx).colorScheme.error,
          ),
        ),
        title: const Text('Hapus Data?'),
        content: Text(
          'Data kendaraan ${item.noPolisi} akan dihapus permanen dan tidak dapat dikembalikan.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await AdminKendaraanService.deleteKendaraan(item.id);
      if (!mounted) return;
      _showSnack('Data ${item.noPolisi} berhasil dihapus', success: true);
      _fetchKendaraan(reset: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceAll('Exception: ', ''), success: false);
    }
  }

  // ── Input Manual ───────────────────────────────────────────────────────────

  Future<void> _openManualForm({KendaraanAdmin? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualInputSheet(
        existing: existing,
        autoNarasumberId: _isAdminLeasing ? _userId : null,
      ),
    );
    if (result == true && mounted) {
      _showSnack('Data berhasil disimpan', success: true);
      _fetchKendaraan(reset: true);
    }
  }

  // ── Import Excel ───────────────────────────────────────────────────────────

  Future<void> _openImportDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ImportExcelDialog(
        autoNarasumberId: _isAdminLeasing ? _userId : null,
      ),
    );

    if (result == true) {
      _showSnack("Import data berhasil.", success: true);

      await _fetchKendaraan(reset: true);
    }
  }

  // ── Download Template ──────────────────────────────────────────────────────

  Future<void> _downloadTemplate() async {
    _showSnack('Mengunduh template...', success: true, duration: 2);

    try {
      final path = await AdminKendaraanService.downloadTemplate();

      if (!mounted) return;

      final result = await OpenFilex.open(path);

      if (!mounted) return;

      if (result.type == ResultType.done) {
        _showSnack(
          'Template berhasil diunduh.\n'
          'Lokasi: Folder Download\n'
          'Nama file: template-import-kendaraan.csv',
          success: true,
          duration: 6,
        );
      } else {
        _showSnack(
          'Template berhasil diunduh.\nLokasi:\n$path',
          success: true,
          duration: 6,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showSnack(e.toString().replaceAll('Exception: ', ''), success: false);
    }
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────

  void _showSnack(String msg, {required bool success, int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success
            ? const Color(0xFF22863A)
            : Colors.red.shade700,
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),

            Expanded(
              child: Column(
                children: [
                  _buildTopBar(theme),
                  Expanded(child: _buildMobileList(theme)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(9, 2, 9, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF536DFE), Color(0xFF7C4DFF)],
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF536DFE).withValues(alpha: .18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(5),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Manajemen Kendaraan",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),

                SizedBox(height: 2),
              ],
            ),
          ),

          PopupMenuButton<String>(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white),
            ),
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              switch (value) {
                case "download":
                  _downloadTemplate();
                  break;

                case "import":
                  _openImportDialog();
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: "download",
                child: Row(
                  children: [
                    Icon(Icons.download_rounded),
                    SizedBox(width: 10),
                    Text("Download Template"),
                  ],
                ),
              ),

              if (_accessAllowed)
                const PopupMenuItem(
                  value: "import",
                  child: Row(
                    children: [
                      Icon(Icons.upload_file_rounded),
                      SizedBox(width: 10),
                      Text("Import Excel"),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Column(
      children: [
        _buildTopBar(theme),
        Expanded(
          child: _listLoading
              ? const Center(child: CircularProgressIndicator())
              : _listError != null
              ? _buildErrorState(
                  _listError!,
                  () => _fetchKendaraan(reset: true),
                )
              : _items.isEmpty
              ? _buildEmptyState()
              : isMobile
              ? _buildMobileList(theme)
              : _buildDesktopTable(theme),
        ),
      ],
    );
  }

  Widget _buildMobileList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () => _fetchKendaraan(reset: true),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$_totalData Data",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),

              const Spacer(),

              FilledButton.icon(
                onPressed: _openManualForm,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Tambah", style: TextStyle(fontSize: 14)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ..._items.map(
            (e) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _showDetail(e),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(
                          0xFF536DFE,
                        ).withOpacity(.12),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          size: 24,
                          color: Color(0xFF536DFE),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.noPolisi,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              e.typeMotor ?? "-",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),

                            if (e.namaLeasing != null)
                              Text(
                                "${e.namaLeasing} • ${e.namaCabang ?? '-'}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_listLoadingMore)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Cari kendaraan",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: const Color.fromARGB(255, 200, 200, 200),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 46,
            height: 46,
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _fetchKendaraan(reset: true),
              child: const Icon(Icons.refresh_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(KendaraanAdmin item) {
    final details = <MapEntry<String, String?>>[
      MapEntry('Tahun', item.tahun),
      MapEntry('Warna', item.warna),
      MapEntry('OVD', item.ovd),
      MapEntry('Leasing', item.namaLeasing),
      MapEntry('No Mesin', item.noMesin),
      MapEntry('No Rangka', item.noRangka),
      MapEntry('Cabang', item.namaCabang),
      MapEntry('Nama STNK', item.namaStnk),
      MapEntry('Nomor HP', item.noHp),
      MapEntry('Kontrak', item.nomorKontrak),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 20),

                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF536DFE).withOpacity(.12),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        size: 24,
                        color: Color(0xFF536DFE),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      item.noPolisi,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      item.typeMotor ?? "-",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: details.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 14,
                            childAspectRatio: 2.7,
                          ),
                      itemBuilder: (_, index) {
                        final detail = details[index];

                        return _detailItem(detail.key, detail.value);
                      },
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _openManualForm(existing: item);
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text("Edit"),
                          ),
                        ),

                        const SizedBox(width: 10),

                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              backgroundColor: Colors.red.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmDelete(item);
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text("Hapus"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailItem(String title, String? value) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            (value?.isNotEmpty ?? false) ? value! : "-",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _detailTile(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            value?.isNotEmpty == true ? value! : "-",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(ThemeData theme) {
    final dataSource = KendaraanDataSource(
      items: _items,
      onEdit: (item) => _openManualForm(existing: item),
      onDelete: (item) => _confirmDelete(item),
    );

    return RefreshIndicator(
      onRefresh: () => _fetchKendaraan(reset: true),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: PaginatedDataTable(
          header: Text('Total Data: $_totalData'),
          columns: const [
            DataColumn(label: Text('No. Polisi')),
            DataColumn(label: Text('Tipe Motor')),
            DataColumn(label: Text('Tahun')),
            DataColumn(label: Text('No. Mesin')),
            DataColumn(label: Text('No. Rangka')),
            DataColumn(label: Text('Leasing')),
            DataColumn(label: Text('Cabang')),
            DataColumn(label: Text('Nama STNK')),
            DataColumn(label: Text('No. HP')),
            DataColumn(label: Text('Warna')),
            DataColumn(label: Text('Aksi')),
          ],
          source: dataSource,
          rowsPerPage: _perPage,
          availableRowsPerPage: const [10, 20, 50, 100],
          onRowsPerPageChanged: (value) {
            if (value != null) {
              setState(() {
                _perPage = value;
                _currentPage = 1;
              });
              _fetchKendaraan(reset: true);
            }
          },
          onPageChanged: (pageIndex) {
            setState(() {
              _currentPage = pageIndex + 1;
            });
            _fetchKendaraan();
          },
          sortColumnIndex: 0,
          sortAscending: true,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Belum ada data kendaraan'
                  : 'Data tidak ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Tambah data manual atau import file Excel'
                  : 'Coba ubah kata kunci pencarian',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Akses Ditolak',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur ini hanya tersedia untuk Admin Leasing, Admin, dan Super Admin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// KENDARAAN DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

class KendaraanDataSource extends DataTableSource {
  final List<KendaraanAdmin> items;
  final Function(KendaraanAdmin) onEdit;
  final Function(KendaraanAdmin) onDelete;

  KendaraanDataSource({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow getRow(int index) {
    final item = items[index];
    return DataRow(
      cells: [
        DataCell(Text(item.noPolisi)),
        DataCell(Text(item.typeMotor ?? '-')),
        DataCell(Text(item.tahun ?? '-')),
        DataCell(Text(item.noMesin ?? '-')),
        DataCell(Text(item.noRangka ?? '-')),
        DataCell(Text(item.namaLeasing ?? '-')),
        DataCell(Text(item.namaCabang ?? '-')),
        DataCell(Text(item.namaStnk ?? '-')),
        DataCell(Text(item.noHp ?? '-')),
        DataCell(Text(item.warna ?? '-')),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => onEdit(item),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => onDelete(item),
                tooltip: 'Hapus',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  int get rowCount => items.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// KENDARAAN CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _KendaraanCard extends StatelessWidget {
  final KendaraanAdmin item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _KendaraanCard({
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF536DFE), Color(0xFF7C4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.noPolisi,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Edit
                _actionBtn(
                  icon: Icons.edit_rounded,
                  tooltip: 'Edit',
                  onPressed: onEdit,
                ),
                // Delete
                _actionBtn(
                  icon: Icons.delete_rounded,
                  tooltip: 'Hapus',
                  onPressed: onDelete,
                  danger: true,
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _infoTile('Tipe Motor', item.typeMotor ?? '-'),
                    ),
                    Expanded(child: _infoTile('Tahun', item.tahun ?? '-')),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        'No. Mesin',
                        item.noMesin ?? '-',
                        fullWidth: true,
                      ),
                    ),
                    Expanded(
                      child: _infoTile(
                        'No. Rangka',
                        item.noRangka ?? '-',
                        fullWidth: true,
                      ),
                    ),
                  ],
                ),
                if (item.namaLeasing != null || item.namaCabang != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (item.namaLeasing != null)
                        Expanded(
                          child: _infoTile('Leasing', item.namaLeasing!),
                        ),
                      if (item.namaCabang != null)
                        Expanded(child: _infoTile('Cabang', item.namaCabang!)),
                    ],
                  ),
                ],
                if (item.namaStnk != null) ...[
                  const SizedBox(height: 6),
                  _infoTile('Nama STNK', item.namaStnk!, fullWidth: true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: danger
                ? Colors.red.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: danger ? Colors.red.shade200 : Colors.white,
            size: 17,
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, {bool fullWidth = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8892A4),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MANUAL INPUT BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _ManualInputSheet extends StatefulWidget {
  final KendaraanAdmin? existing;
  final int? autoNarasumberId;

  const _ManualInputSheet({this.existing, this.autoNarasumberId});

  @override
  State<_ManualInputSheet> createState() => _ManualInputSheetState();
}

class _ManualInputSheetState extends State<_ManualInputSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nopolCtrl = TextEditingController();
  final _mesinCtrl = TextEditingController();
  final _rangkaCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _namaStnkCtrl = TextEditingController();
  final _warnaCtrl = TextEditingController();
  final _tahunCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();
  final _kontrakCtrl = TextEditingController();
  final _leasingCtrl = TextEditingController();
  final _cabangCtrl = TextEditingController();
  final _ovdCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nopolCtrl.text = e.noPolisi;
      _mesinCtrl.text = e.noMesin ?? '';
      _rangkaCtrl.text = e.noRangka ?? '';
      _typeCtrl.text = e.typeMotor ?? '';
      _namaStnkCtrl.text = e.namaStnk ?? '';
      _warnaCtrl.text = e.warna ?? '';
      _tahunCtrl.text = e.tahun ?? '';
      _noHpCtrl.text = e.noHp ?? '';
      _kontrakCtrl.text = e.nomorKontrak ?? '';
      _leasingCtrl.text = e.leasingId.toString();
      _cabangCtrl.text = e.cabangId.toString();
      _ovdCtrl.text = e.ovd ?? '';
    }
  }

  @override
  void dispose() {
    _nopolCtrl.dispose();
    _mesinCtrl.dispose();
    _rangkaCtrl.dispose();
    _typeCtrl.dispose();
    _namaStnkCtrl.dispose();
    _warnaCtrl.dispose();
    _tahunCtrl.dispose();
    _noHpCtrl.dispose();
    _kontrakCtrl.dispose();
    _leasingCtrl.dispose();
    _cabangCtrl.dispose();
    _ovdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = <String, dynamic>{
      'no_polisi': _nopolCtrl.text.trim().toUpperCase(),
      if (_mesinCtrl.text.trim().isNotEmpty) 'no_mesin': _mesinCtrl.text.trim(),
      if (_rangkaCtrl.text.trim().isNotEmpty)
        'no_rangka': _rangkaCtrl.text.trim(),
      if (_typeCtrl.text.trim().isNotEmpty) 'type_motor': _typeCtrl.text.trim(),
      if (_namaStnkCtrl.text.trim().isNotEmpty)
        'nama_stnk': _namaStnkCtrl.text.trim(),
      if (_warnaCtrl.text.trim().isNotEmpty) 'warna': _warnaCtrl.text.trim(),
      if (_tahunCtrl.text.trim().isNotEmpty) 'tahun': _tahunCtrl.text.trim(),
      if (_noHpCtrl.text.trim().isNotEmpty) 'no_hp': _noHpCtrl.text.trim(),
      if (_kontrakCtrl.text.trim().isNotEmpty)
        'nomor_kontrak': _kontrakCtrl.text.trim(),
      if (_leasingCtrl.text.trim().isNotEmpty)
        'leasing_id': _leasingCtrl.text.trim(),
      if (_cabangCtrl.text.trim().isNotEmpty)
        'cabang_id': _cabangCtrl.text.trim(),
      // Untuk Admin Leasing, narasumber_id otomatis diisi
      if (widget.autoNarasumberId != null)
        'narasumber_id': widget.autoNarasumberId,
      if (_ovdCtrl.text.trim().isNotEmpty) 'ovd': _ovdCtrl.text.trim(),
    };

    try {
      await AdminKendaraanService.saveKendaraan(body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF536DFE), Color(0xFF7C4DFF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEdit ? Icons.edit_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit
                            ? 'Edit Data Kendaraan'
                            : 'Tambah Data Kendaraan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isEdit
                            ? 'Perbarui informasi kendaraan'
                            : 'Isi data kendaraan secara manual',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(
                      _nopolCtrl,
                      'No. Polisi *',
                      Icons.credit_card_rounded,
                      required: true,
                      hint: 'Contoh: B 1234 XYZ',
                      caps: true,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      _mesinCtrl,
                      'No. Mesin',
                      Icons.settings_rounded,
                      required: false,
                      caps: true,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      _rangkaCtrl,
                      'No. Rangka',
                      Icons.article_rounded,
                      required: false,
                      caps: true,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            _typeCtrl,
                            'Tipe Motor',
                            Icons.two_wheeler_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            _tahunCtrl,
                            'Tahun',
                            Icons.calendar_today_rounded,
                            number: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(
                      _namaStnkCtrl,
                      'Nama STNK',
                      Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            _warnaCtrl,
                            'Warna',
                            Icons.palette_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            _noHpCtrl,
                            'No. HP',
                            Icons.phone_rounded,
                            number: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(_kontrakCtrl, 'No. Kontrak', Icons.numbers_rounded),
                    const SizedBox(height: 10),
                    _field(_ovdCtrl, 'OVD', Icons.countertops),
                    const SizedBox(height: 10),
                    _field(
                      _leasingCtrl,
                      'Leasing',
                      Icons.article_rounded,
                      required: false,
                      caps: true,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      _cabangCtrl,
                      'Cabang',
                      Icons.article_rounded,
                      required: false,
                      caps: true,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_saving ? 'Menyimpan...' : 'Simpan Data'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF536DFE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    bool number = false,
    bool caps = false,
    String? hint,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      textCapitalization: caps
          ? TextCapitalization.characters
          : TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// IMPORT EXCEL DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _ImportExcelDialog extends StatefulWidget {
  final int? autoNarasumberId;

  const _ImportExcelDialog({this.autoNarasumberId});

  @override
  State<_ImportExcelDialog> createState() => _ImportExcelDialogState();
}

class _ImportExcelDialogState extends State<_ImportExcelDialog> {
  PlatformFile? _pickedFile;
  String _uploadType = 'tambah'; // 'tambah' | 'replace'
  bool _uploading = false;
  bool _polling = false;
  ImportProgress? _progress;
  String? _uploadError;
  Timer? _pollTimer;
  String? _importId;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  bool get _isDone => _progress?.isFinished ?? false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        _uploadError = null;
      });
    }
  }

  Future<void> _startImport() async {
    if (_pickedFile == null) {
      setState(() => _uploadError = 'Pilih file terlebih dahulu');
      return;
    }

    final filePath = _pickedFile!.path;
    if (filePath == null) {
      setState(() => _uploadError = 'Path file tidak valid');
      return;
    }

    setState(() {
      _uploading = true;
      _uploadError = null;
      _progress = null;
    });

    try {
      print("autoNarasumberId = ${widget.autoNarasumberId}");
      final res = await AdminKendaraanService.importKendaraan(
        filePath: filePath,
        uploadType: _uploadType,
        narasumberId: widget.autoNarasumberId,
      );

      final id =
          res['data']?['import_id']?.toString() ?? res['import_id']?.toString();

      if (id == null) {
        // Jika server langsung selesai tanpa polling
        setState(() {
          _uploading = false;
          _progress = ImportProgress(
            status: 'done',
            processed: 0,
            total: 0,
            message: res['message']?.toString() ?? 'Import selesai',
          );
        });
        return;
      }

      _importId = id;
      setState(() {
        _uploading = false;
        _polling = true;
        _progress = ImportProgress(
          status: 'processing',
          processed: 0,
          total: 0,
          message: 'Sedang memproses...',
        );
      });

      _startPolling();
    } catch (e) {
      setState(() {
        _uploading = false;
        _uploadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_importId == null || !mounted) return;
      try {
        final prog = await AdminKendaraanService.getImportProgress(_importId!);
        print("status    : ${prog.status}");
        print("isDone    : ${prog.isDone}");
        print("isError   : ${prog.isError}");
        print("isFinished: ${prog.isFinished}");
        print("message   : ${prog.message}");
        if (!mounted) return;
        setState(() {
          _progress = prog;
        });
        if (prog.isFinished) {
          _pollTimer?.cancel();

          setState(() {
            _polling = false;
            _progress = prog;
          });

          await Future.delayed(const Duration(seconds: 1));

          if (mounted && !prog.isError) {
            Navigator.of(context).pop(true);
          }
        }
      } catch (_) {
        // silent – keep polling
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22863A), Color(0xFF2EA04F)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.table_chart_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Data Excel',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Upload file .xlsx / .xls / .csv',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_uploading && !_polling)
                      IconButton(
                        onPressed: () => Navigator.pop(context, _isDone),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Pilih File ─────────────────────────────────────────
                if (!_polling) ...[
                  Text(
                    'File Excel',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _uploading ? null : _pickFile,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _pickedFile != null
                            ? const Color(0xFF22863A).withValues(alpha: 0.07)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _pickedFile != null
                              ? const Color(0xFF22863A)
                              : theme.colorScheme.outlineVariant,
                          width: _pickedFile != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _pickedFile != null
                                ? Icons.check_circle_rounded
                                : Icons.upload_file_rounded,
                            color: _pickedFile != null
                                ? const Color(0xFF22863A)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _pickedFile != null
                                  ? _pickedFile!.name
                                  : 'Tap untuk memilih file',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _pickedFile != null
                                    ? const Color(0xFF22863A)
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: _pickedFile != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (_pickedFile != null)
                            Text(
                              _formatFileSize(_pickedFile!.size),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Upload Type ────────────────────────────────────
                  Text(
                    'Mode Upload',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _uploadTypeOption(
                    value: 'tambah',
                    title: 'Tambah Data',
                    subtitle: 'Menambahkan data baru tanpa menghapus yang lama',
                    icon: Icons.add_circle_outline_rounded,
                    color: const Color(0xFF536DFE),
                  ),
                  const SizedBox(height: 6),
                  _uploadTypeOption(
                    value: 'replace',
                    title: 'Ganti Semua',
                    subtitle:
                        'Mengganti seluruh data dengan data dari file ini',
                    icon: Icons.swap_horiz_rounded,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Progress ───────────────────────────────────────────
                if (_progress != null) _buildProgress(theme),

                // ── Error ──────────────────────────────────────────────
                if (_uploadError != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _uploadError!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Action Buttons ─────────────────────────────────────
                if (_isDone) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Selesai'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF22863A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else if (!_polling) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _uploading
                              ? null
                              : () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: (_uploading || _pickedFile == null)
                              ? null
                              : _startImport,
                          icon: _uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upload_rounded),
                          label: Text(_uploading ? 'Mengupload...' : 'Upload'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF22863A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(ThemeData theme) {
    final prog = _progress!;
    final isDone = prog.isDone;
    final isError = prog.isError;
    final progressColor = isError
        ? Colors.red.shade600
        : isDone
        ? const Color(0xFF22863A)
        : const Color(0xFF536DFE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_polling)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF536DFE),
                ),
              )
            else
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.error_rounded,
                color: progressColor,
                size: 18,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _polling
                    ? 'Memproses...'
                    : (isDone ? 'Import Selesai!' : 'Terjadi Kesalahan'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: progressColor,
                ),
              ),
            ),
            if (prog.total > 0)
              Text(
                '${prog.processed}/${prog.total}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _polling && prog.total == 0 ? null : prog.progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 8,
          ),
        ),
        if (prog.message != null) ...[
          const SizedBox(height: 8),
          Text(
            prog.message!,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (prog.errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baris dengan kesalahan (${prog.errors.length}):',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                ...prog.errors
                    .take(5)
                    .map(
                      (e) => Text(
                        '• $e',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                if (prog.errors.length > 5)
                  Text(
                    '... dan ${prog.errors.length - 5} kesalahan lainnya',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade500),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _uploadTypeOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final selected = _uploadType == value;
    return GestureDetector(
      onTap: _uploading ? null : () => setState(() => _uploadType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? color
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.radio_button_checked_rounded, color: color, size: 20)
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: Colors.grey,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';
  }
}
