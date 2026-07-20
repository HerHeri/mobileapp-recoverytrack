import 'package:flutter/material.dart';

class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102B52), Color(0xFF07162F), Color(0xFF0B2345)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF42CFFF), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x9942CFFF), blurRadius: 10, spreadRadius: 1),
          BoxShadow(color: Color(0x660A70FF), blurRadius: 22, spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFBD58), Color(0xFFFFD17A)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Color(0x66FFB84D), blurRadius: 12),
              ],
            ),
            child: const Text(
              'DISCLAIMER',
              style: TextStyle(
                color: Color(0xFF29313C),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Stack(
            alignment: Alignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Informasi kendaraan dalam Aplikasi '),
                      TextSpan(
                        text: 'bersifat referensi awal',
                        style: TextStyle(color: Color(0xFFFFC857)),
                      ),
                      TextSpan(text: ' dan '),
                      TextSpan(
                        text:
                            'tidak dapat digunakan sebagai dasar penentuan '
                            'status tunggakan maupun tindakan terhadap kendaraan.',
                        style: TextStyle(color: Color(0xFFFFC857)),
                      ),
                      TextSpan(text: ' Pengguna '),
                      TextSpan(
                        text:
                            'wajib melakukan verifikasi kepada pihak terkait.',
                        style: TextStyle(color: Color(0xFFFFC857)),
                      ),
                      TextSpan(
                        text:
                            ' Setiap penyalahgunaan informasi sepenuhnya '
                            'menjadi tanggung jawab pengguna',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFF29C7FF),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _ValidationDocumentIcon(),
              SizedBox(width: 16),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Untuk validasi akurasi data'),
                      TextSpan(
                        text: 'wajib konfirmasi',
                        style: TextStyle(color: Color(0xFFFFD34E)),
                      ),
                      TextSpan(text: '\nke perusahaan pembiayaan terkait'),
                    ],
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InformationStatusRow extends StatelessWidget {
  const InformationStatusRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Status Informasi',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD52A),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFFFD52A)),
              boxShadow: const [
                BoxShadow(color: Color(0xFFFFD52A), blurRadius: 8),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Color.fromARGB(255, 0, 0, 0),
                  size: 17,
                ),
                SizedBox(width: 6),
                Text(
                  'Wajib Validasi',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationDocumentIcon extends StatelessWidget {
  const _ValidationDocumentIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 58,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            child: Icon(
              Icons.description_outlined,
              color: Color(0xFF31D4FF),
              size: 48,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A2448),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF31D4FF),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
