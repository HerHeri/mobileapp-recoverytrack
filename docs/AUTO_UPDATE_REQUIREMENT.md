# Requirement: Auto Update APK untuk Aplikasi Mobile

## Overview
Fitur auto-update memungkinkan aplikasi mobile (APK) mengecek versi terbaru saat dibuka. Jika tersedia versi baru, pengguna akan mendapat notifikasi untuk mendownload dan meng-install update.

## 1. Database Table: `app_versions`

Buat table baru di Laravel migration:

```sql
CREATE TABLE app_versions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(20) NOT NULL,           -- Contoh: "1.0.1"
    version_code INT NOT NULL,              -- Contoh: 2 (integer, naik setiap release)
    filename VARCHAR(255) NOT NULL,         -- Nama file APK: "rt-v1.0.1.apk"
    file_size BIGINT NULL,                  -- Ukuran file dalam bytes (opsional)
    changelog TEXT NULL,                    -- Catatan perubahan (What's New)
    force_update TINYINT(1) DEFAULT 0,      -- 0 = opsional, 1 = wajib update
    is_active TINYINT(1) DEFAULT 1,         -- 0 = nonaktifkan versi ini
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);
```

### Migration File Lengkap

Buat file migration (copy-paste):

```php
// database/migrations/xxxx_xx_xx_create_app_versions_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('app_versions', function (Blueprint $table) {
            $table->id();
            $table->string('version', 20);
            $table->integer('version_code');
            $table->string('filename', 255);
            $table->bigInteger('file_size')->nullable();
            $table->text('changelog')->nullable();
            $table->boolean('force_update')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_versions');
    }
};
```

### Model Lengkap: `App\Models\AppVersion`

Buat file model (copy-paste):

```php
// app/Models/AppVersion.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppVersion extends Model
{
    protected $table = 'app_versions';

    protected $fillable = [
        'version',
        'version_code',
        'filename',
        'file_size',
        'changelog',
        'force_update',
        'is_active',
    ];

    protected $casts = [
        'version_code' => 'integer',
        'file_size'    => 'integer',
        'force_update' => 'boolean',
        'is_active'    => 'boolean',
    ];
}
```

---

## 2. Folder Download APK

Buat folder untuk menyimpan file APK:

```
public/downloads/
```

Upload APK build ke folder ini. Pastikan file bisa diakses publik:
```
https://api.suntikradar.com/downloads/suntikradar-v1.0.1.apk
```

Atau dari domain utama:
```
https://suntikradar.com/downloads/suntikradar-v1.0.1.apk
```

---

## 3. API Endpoint: `GET /v1/version` (Sudah ada di route list)

Endpoint ini harus mengembalikan data versi terbaru yang aktif.

### Response yang diharapkan Mobile App:

```json
{
    "success": true,
    "data": {
        "version": "1.0.1",
        "version_code": 2,
        "filename": "suntikradar-v1.0.1.apk",
        "download_url": "https://api.suntikradar.com/downloads/suntikradar-v1.0.1.apk",
        "file_size": 15728640,
        "changelog": "- Perbaikan bug login\n- Fitur auto update\n- Peningkatan performa",
        "force_update": false
    }
}
```

### Rekomendasi Controller Logic:

```php
// App\Http\Controllers\Api\V1\VersionController.php

public function check(Request $request)
{
    $latest = AppVersion::where('is_active', 1)
        ->orderBy('version_code', 'desc')
        ->first();

    if (!$latest) {
        return response()->json([
            'success' => true,
            'data' => null  // Tidak ada update tersedia
        ]);
    }

    return response()->json([
        'success' => true,
        'data' => [
            'version'      => $latest->version,
            'version_code' => $latest->version_code,
            'filename'     => $latest->filename,
            'download_url' => url('downloads/' . $latest->filename),
            'file_size'    => $latest->file_size,
            'changelog'    => $latest->changelog,
            'force_update' => (bool) $latest->force_update,
        ]
    ]);
}
```

---

## 4. Admin Panel (Opsional)

Tambahkan halaman CRUD `AppVersion` di admin panel Laravel untuk mengelola:
- Upload APK baru
- Set version, version_code
- Toggle force_update
- Toggle is_active

### Flow Admin:
1. Admin membuka halaman "App Versions"
2. Klik "Tambah Versi Baru"
3. Upload file APK
4. Isi version (contoh: "1.0.2"), version_code (contoh: 3), changelog
5. Centang `force_update` jika update wajib
6. Simpan → APK tersimpan di `public/downloads/` dan record tersimpan di `app_versions`
7. Mobile app akan otomatis mendeteksi versi baru

---

## 5. Nginx / Server Config

Pastikan folder `public/downloads/` bisa diakses langsung. Jika pakai Nginx, default config sudah mengizinkan akses file statis di folder `public`. Jika ada pembatasan, tambahkan:

```nginx
location /downloads/ {
    alias /www/wwwroot/suntikradar.com/suntikradar/public/downloads/;
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

---

## 6. Workflow Auto Update

```
┌─────────────────────────────────────────────────────────┐
│  1. User membuka aplikasi                               │
│  2. App memanggil GET /v1/version                       │
│  3. Bandingkan version_code dari server vs local        │
│  4. Jika server > local:                                │
│     ├─ Tampilkan dialog "Update Tersedia"               │
│     ├─ User klik "Update"                               │
│     ├─ Download APK dari download_url                   │
│     ├─ Setelah download selesai, buka file APK          │
│     └─ Sistem Android akan meminta install              │
│  5. Jika force_update = true:                           │
│     └─ User TIDAK bisa menutup dialog (wajib update)    │
└─────────────────────────────────────────────────────────┘
```

## 7. Catatan Penting

- **version_code** HARUS selalu integer dan NAIK setiap release. Android menggunakan ini untuk menentukan mana versi lebih baru.
- **version** adalah string display (contoh: "1.0.1", "2.0.0")
- **force_update** = true jika update WAJIB (misal: ada bug kritis). User tidak bisa skip.
- **force_update** = false: User bisa pilih "Nanti Saja" untuk menunda update.
- Setiap kali upload APK baru ke `public/downloads/`, jangan lupa insert record ke `app_versions`.
- File APK lama di folder `public/downloads/` sebaiknya tetap disimpan (jangan dihapus) untuk memudahkan rollback jika diperlukan.
- Hotfix 1: Kalau nama APK bisa konflik, beri nama dengan versi: `rt-v1.0.1.apk`, `rt-v1.0.2.apk`.