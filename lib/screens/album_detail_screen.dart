import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/album_model.dart';
import '../models/photo_model.dart';
import '../providers/photo_provider.dart';
import '../widgets/photo_grid.dart';

class AlbumDetailScreen extends StatefulWidget {
  final AlbumModel album;

  const AlbumDetailScreen({
    super.key,
    required this.album,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<PhotoModel> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbumPhotos();
  }

  Future<void> _loadAlbumPhotos() async {
    try {
      final provider = context.read<PhotoProvider>();
      final photos = await provider.getAlbumPhotos(widget.album.name);
      
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('加载失败'),
            content: Text('无法加载相册照片：$e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 相册标题栏
            SliverAppBar(
              title: Text(widget.album.name),
              backgroundColor: Colors.transparent,
              floating: true,
              actions: [
                IconButton(
                  onPressed: () => _showAlbumInfo(),
                  icon: const Icon(CupertinoIcons.info),
                ),
              ],
            ),
            
            // 相册统计信息
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.collections,
                        color: CupertinoColors.systemBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.album.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.album.photoCount} 张照片/视频',
                              style: const TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_photos.isNotEmpty)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _startOrganizing(),
                          child: const Text('整理'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 照片网格
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CupertinoActivityIndicator(),
                  ),
                ),
              )
            else
              PhotoGrid(
                photos: _photos,
                title: '相册照片',
              ),
          ],
        ),
      ),
    );
  }

  void _showAlbumInfo() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(widget.album.name),
        message: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('照片数量', '${widget.album.photoCount}'),
            _buildInfoRow('创建时间', _formatDate(widget.album.createdAt)),
            _buildInfoRow('更新时间', _formatDate(widget.album.updatedAt)),
            if (widget.album.coverPhotoPath != null)
              _buildInfoRow('封面照片', '已设置'),
          ],
        ),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: CupertinoColors.secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }

  void _startOrganizing() {
    // TODO: 实现相册整理功能
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('整理相册'),
        content: const Text('相册整理功能正在开发中，敬请期待！'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日';
  }
}