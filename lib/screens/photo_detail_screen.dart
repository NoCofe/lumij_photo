import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/photo_model.dart';
import '../providers/photo_provider.dart';
import '../services/operation_service.dart';
import 'video_player_screen.dart';

class PhotoDetailScreen extends StatelessWidget {
  final PhotoModel photo;

  const PhotoDetailScreen({
    super.key,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(photo.name),
        actions: [
          IconButton(
            onPressed: () => _showPhotoInfo(context),
            icon: const Icon(CupertinoIcons.info),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: photo.type == 'image'
              ? Image.file(
                  File(photo.compressedPath ?? photo.path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorWidget();
                  },
                )
              : _buildVideoWidget(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: CupertinoIcons.share,
                label: '分享',
                onPressed: () => _sharePhoto(context),
              ),
              _buildActionButton(
                icon: CupertinoIcons.delete,
                label: '删除',
                onPressed: () => _deletePhoto(context),
              ),
              _buildActionButton(
                icon: CupertinoIcons.arrow_down_to_line,
                label: '压缩',
                onPressed: () => _compressPhoto(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoWidget() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.play_circle,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            '视频预览',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            photo.name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) => CupertinoButton.filled(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => VideoPlayerScreen(video: photo),
                  ),
                );
              },
              child: const Text('播放视频'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            '无法加载图片',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '文件可能已被移动或删除',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoInfo(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(photo.name),
        message: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('类型', photo.type == 'image' ? '图片' : '视频'),
            _buildInfoRow('大小', _formatFileSize(photo.size)),
            _buildInfoRow('尺寸', '${photo.width} × ${photo.height}'),
            _buildInfoRow('创建时间', _formatDate(photo.dateTime)),
            _buildInfoRow('路径', photo.path),
            if (photo.isCompressed)
              _buildInfoRow('状态', '已压缩'),
            if (photo.albumName != null)
              _buildInfoRow('相册', photo.albumName!),
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
            width: 60,
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

  void _sharePhoto(BuildContext context) {
    // TODO: 实现分享功能
    _showFeatureNotImplemented(context, '分享功能');
  }

  void _deletePhoto(BuildContext context) async {
    // 检查删除权限
    final hasPermission = await OperationService.requestDeletePermission(context);
    if (!hasPermission) return;
    
    // 执行删除操作
    final provider = Provider.of<PhotoProvider>(context, listen: false);
    final success = await provider.deletePhoto(photo.id);
    
    if (success) {
      Navigator.pop(context); // 返回上一页
      OperationService.showSuccessMessage(context, '照片已删除');
    } else {
      OperationService.showErrorMessage(context, '删除失败，请重试');
    }
  }

  void _compressPhoto(BuildContext context) async {
    if (photo.type != 'image') {
      OperationService.showErrorMessage(context, '只能压缩图片文件');
      return;
    }

    if (photo.isCompressed) {
      OperationService.showErrorMessage(context, '此图片已经被压缩过了');
      return;
    }

    // 检查压缩权限
    final hasPermission = await OperationService.requestCompressPermission(context);
    if (!hasPermission) return;
    
    // 执行压缩操作
    final provider = Provider.of<PhotoProvider>(context, listen: false);
    await provider.compressPhoto(photo.id);
    
    OperationService.showSuccessMessage(context, '图片已压缩', color: CupertinoColors.systemOrange);
  }

  void _playVideo(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => VideoPlayerScreen(video: photo),
      ),
    );
  }

  void _showFeatureNotImplemented(BuildContext context, String feature) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(feature),
        content: const Text('此功能正在开发中，敬请期待！'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}