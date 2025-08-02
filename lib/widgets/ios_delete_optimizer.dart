import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import '../models/photo_model.dart';

class IOSDeleteOptimizer {
  // 显示批量删除选择器
  static Future<void> showBatchDeleteSelector({
    required BuildContext context,
    required List<PhotoModel> photos,
    String title = '选择要删除的照片',
  }) async {
    final selectedPhotos = <String>{};
    
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoActionSheet(
          title: Text(title),
          message: Column(
            children: [
              Text('选择多张照片一次性删除，减少确认次数'),
              const SizedBox(height: 12),
              Container(
                height: 300,
                child: ListView.builder(
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    final isSelected = selectedPhotos.contains(photo.id);
                    
                    return CupertinoListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(photo.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text(photo.name),
                      subtitle: Text(_formatFileSize(photo.size)),
                      trailing: isSelected
                          ? const Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.systemBlue)
                          : const Icon(CupertinoIcons.circle),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedPhotos.remove(photo.id);
                          } else {
                            selectedPhotos.add(photo.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            if (selectedPhotos.isNotEmpty)
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  await _performBatchDelete(context, selectedPhotos.toList());
                },
                isDestructiveAction: true,
                child: Text('删除选中的 ${selectedPhotos.length} 张照片'),
              ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  if (selectedPhotos.length == photos.length) {
                    selectedPhotos.clear();
                  } else {
                    selectedPhotos.addAll(photos.map((p) => p.id));
                  }
                });
              },
              child: Text(selectedPhotos.length == photos.length ? '取消全选' : '全选'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ),
      ),
    );
  }
  
  // 显示智能删除建议
  static Future<void> showSmartDeleteSuggestions({
    required BuildContext context,
    required List<PhotoModel> duplicates,
    required List<PhotoModel> largePhotos,
  }) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('智能删除建议'),
        message: const Text('一次性处理多种类型的照片，减少确认次数'),
        actions: [
          if (duplicates.isNotEmpty)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                showBatchDeleteSelector(
                  context: context,
                  photos: duplicates,
                  title: '删除重复照片 (${duplicates.length}张)',
                );
              },
              child: Row(
                children: [
                  const Icon(CupertinoIcons.doc_on_doc, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('删除重复照片 (${duplicates.length}张)')),
                ],
              ),
            ),
          if (largePhotos.isNotEmpty)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                showBatchDeleteSelector(
                  context: context,
                  photos: largePhotos,
                  title: '删除大文件照片 (${largePhotos.length}张)',
                );
              },
              child: Row(
                children: [
                  const Icon(CupertinoIcons.folder_fill, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('删除大文件照片 (${largePhotos.length}张)')),
                ],
              ),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              final allSuggested = [...duplicates, ...largePhotos];
              showBatchDeleteSelector(
                context: context,
                photos: allSuggested,
                title: '删除所有建议照片 (${allSuggested.length}张)',
              );
            },
            isDestructiveAction: true,
            child: Row(
              children: [
                const Icon(CupertinoIcons.trash, size: 20),
                const SizedBox(width: 8),
                Text('删除所有建议 (${duplicates.length + largePhotos.length}张)'),
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
  
  static Future<void> _performBatchDelete(BuildContext context, List<String> photoIds) async {
    // 显示确认对话框
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${photoIds.length} 张照片吗？\n\n这将只需要一次系统确认。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: true,
            child: const Text('删除'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // 显示加载指示器
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 16),
              Text('正在删除照片...'),
            ],
          ),
        ),
      );
      
      try {
        final provider = context.read<PhotoProvider>();
        final deletedCount = await provider.deleteMultiplePhotos(photoIds);
        
        Navigator.pop(context); // 关闭加载对话框
        
        // 显示结果
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('删除完成'),
            content: Text('成功删除 $deletedCount 张照片'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      } catch (e) {
        Navigator.pop(context); // 关闭加载对话框
        
        // 显示错误
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('删除失败'),
            content: Text('删除照片时出现错误：$e'),
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
  
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// 扩展CupertinoListTile（如果不存在）
class CupertinoListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  
  const CupertinoListTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) title!,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    DefaultTextStyle(
                      style: const TextStyle(
                        color: CupertinoColors.secondaryLabel,
                        fontSize: 14,
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}