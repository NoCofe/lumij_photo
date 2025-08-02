import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'lumij_photo.db';
  static const int _databaseVersion = 1;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }
  
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        name TEXT NOT NULL,
        dateTime INTEGER NOT NULL,
        size INTEGER NOT NULL,
        type TEXT NOT NULL,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        albumName TEXT,
        isDeleted INTEGER DEFAULT 0,
        isCompressed INTEGER DEFAULT 0,
        compressedPath TEXT,
        hash TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE albums (
        name TEXT PRIMARY KEY,
        photoCount INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        coverPhotoPath TEXT
      )
    ''');
    
    await db.execute('''
      CREATE INDEX idx_photos_datetime ON photos(dateTime);
    ''');
    
    await db.execute('''
      CREATE INDEX idx_photos_size ON photos(size);
    ''');
    
    await db.execute('''
      CREATE INDEX idx_photos_hash ON photos(hash);
    ''');
  }
  
  // 照片相关操作
  static Future<void> insertPhoto(PhotoModel photo) async {
    final db = await database;
    await db.insert('photos', photo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  static Future<void> insertPhotos(List<PhotoModel> photos) async {
    final db = await database;
    final batch = db.batch();
    for (final photo in photos) {
      batch.insert('photos', photo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }
  
  static Future<List<PhotoModel>> getAllPhotos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('photos', where: 'isDeleted = 0');
    return List.generate(maps.length, (i) => PhotoModel.fromMap(maps[i]));
  }
  
  static Future<List<PhotoModel>> getPhotosBySize({
    int page = 0,
    int pageSize = 50,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'isDeleted = 0',
      orderBy: 'size DESC',
      limit: pageSize,
      offset: page * pageSize,
    );
    return List.generate(maps.length, (i) => PhotoModel.fromMap(maps[i]));
  }

  // 获取照片总数
  static Future<int> getTotalPhotosCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM photos WHERE isDeleted = 0'
    );
    return result.first['count'] as int;
  }

  // 分页获取所有照片
  static Future<List<PhotoModel>> getPhotosWithPagination({
    int page = 0,
    int pageSize = 50,
    String orderBy = 'dateTime DESC',
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'isDeleted = 0',
      orderBy: orderBy,
      limit: pageSize,
      offset: page * pageSize,
    );
    return List.generate(maps.length, (i) => PhotoModel.fromMap(maps[i]));
  }
  
  static Future<List<PhotoModel>> getDuplicatePhotos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM photos 
      WHERE hash IN (
        SELECT hash FROM photos 
        WHERE hash IS NOT NULL AND isDeleted = 0
        GROUP BY hash 
        HAVING COUNT(*) > 1
      )
      ORDER BY hash, dateTime
    ''');
    return List.generate(maps.length, (i) => PhotoModel.fromMap(maps[i]));
  }
  
  static Future<void> updatePhoto(PhotoModel photo) async {
    final db = await database;
    await db.update('photos', photo.toMap(), where: 'id = ?', whereArgs: [photo.id]);
  }
  
  static Future<void> deletePhoto(String id) async {
    final db = await database;
    await db.update('photos', {'isDeleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
  
  // 相册相关操作
  static Future<void> insertAlbum(AlbumModel album) async {
    final db = await database;
    await db.insert('albums', album.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  static Future<List<AlbumModel>> getAllAlbums() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('albums');
    return List.generate(maps.length, (i) => AlbumModel.fromMap(maps[i]));
  }
  
  static Future<List<PhotoModel>> getPhotosByAlbum(String albumName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'albumName = ? AND isDeleted = 0',
      whereArgs: [albumName],
      orderBy: 'dateTime DESC',
    );
    return List.generate(maps.length, (i) => PhotoModel.fromMap(maps[i]));
  }
}