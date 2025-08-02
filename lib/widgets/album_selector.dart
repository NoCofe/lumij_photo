import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import '../services/operation_service.dart';

class AlbumSelector {
  static Future<void> show({
    required BuildContext context,
    required Function(String albumName) onAlbumSelected,
  }) async {
    // 检查相册操作权限
    final hasPermission = await OperationService.requestAlbumPermission(context);
    if (!hasPermission) return;
    
    // 获取真实相册列表
    final provider = context.read<PhotoProvider>();
    await provider.loadAlbums();
    final albums = provider.albums;
    
    if (!context.mounted) return;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('选择相册'),
        message: albums.isEmpty 
            ? const Text('未找到相册，将创建新相册')
            : const Text('选择要添加到的相册'),
        actions: [
          // 显示真实相册
          ...albums.map((album) => CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              onAlbumSelected(album.name);
            },
            child: Row(
              children: [
                const Icon(CupertinoIcons.collections, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(album.name),
                ),
                Text(
                  '${album.photoCount}',
                  style: const TextStyle(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )),
          
          // 分隔线
          if (albums.isNotEmpty)
            CupertinoActionSheetAction(
              onPressed: () {},
              child: const Divider(),
            ),
          
          // 创建新相册选项
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showCreateAlbumDialog(context, onAlbumSelected);
            },
            child: const Row(
              children: [
                Icon(CupertinoIcons.add, size: 20),
                SizedBox(width: 8),
                Text('创建新相册'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }
  
  static void _showCreateAlbumDialog(
    BuildContext context,
    Function(String albumName) onAlbumSelected,
  ) {
    final TextEditingController controller = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('创建新相册'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入相册名称：'),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: '相册名称',
              autofocus: true,
              onSubmitted: (value) {
                final albumName = value.trim();
                if (albumName.isNotEmpty) {
                  Navigator.pop(context);
                  onAlbumSelected(albumName);
                }
              },
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final albumName = controller.text.trim();
              if (albumName.isNotEmpty) {
                Navigator.pop(context);
                onAlbumSelected(albumName);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}