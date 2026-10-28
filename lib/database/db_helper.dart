import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/tangkapan.dart';

/// Pengelola database lokal SQLite. Satu tabel: `tangkapan`.
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static const _namaDb = 'jurnal_nelayan.db';
  static const _tabel = 'tangkapan';

  Database? _db;

  Future<Database> get database async => _db ??= await _buka();

  Future<void> _buatTabel(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $_tabel (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        jenis_ikan TEXT NOT NULL,
        berat_kg REAL NOT NULL,
        harga_per_kg REAL,
        catatan TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<Database> _buka() async {
    final lokasi = join(await getDatabasesPath(), _namaDb);
    return openDatabase(
      lokasi,
      version: 2,
      onCreate: (db, versi) => _buatTabel(db),
      // Versi 2: kolom latitude, longitude, dan path_foto dihapus.
      // Tabel dibuat ulang agar data lama tetap aman.
      onUpgrade: (db, lama, baru) async {
        if (lama < 2) {
          await db.transaction((txn) async {
            await txn.execute('ALTER TABLE $_tabel RENAME TO ${_tabel}_lama');
            await _buatTabel(txn);
            await txn.execute('''
              INSERT INTO $_tabel
                (id, tanggal, jenis_ikan, berat_kg, harga_per_kg, catatan)
              SELECT id, tanggal, jenis_ikan, berat_kg, harga_per_kg, catatan
              FROM ${_tabel}_lama
            ''');
            await txn.execute('DROP TABLE ${_tabel}_lama');
          });
        }
      },
    );
  }

  /// Create: mengembalikan id baris baru.
  Future<int> tambah(Tangkapan t) async {
    final db = await database;
    final data = t.toMap()..remove('id'); // id dibuat otomatis
    return db.insert(_tabel, data);
  }

  /// Read: semua catatan, terbaru di atas.
  Future<List<Tangkapan>> semua() async {
    final db = await database;
    final baris = await db.query(_tabel, orderBy: 'tanggal DESC, id DESC');
    return baris.map(Tangkapan.fromMap).toList();
  }

  /// Update: mengembalikan jumlah baris yang berubah.
  Future<int> ubah(Tangkapan t) async {
    final db = await database;
    return db.update(_tabel, t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  /// Delete: mengembalikan jumlah baris yang terhapus.
  Future<int> hapus(int id) async {
    final db = await database;
    return db.delete(_tabel, where: 'id = ?', whereArgs: [id]);
  }
}