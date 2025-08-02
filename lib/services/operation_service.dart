import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class OperationService {
  static bool _hasDeletePermission = false;
  static bool _hasCompressPermission = false;
  static bool _hasAlbumPermission = false;
  
  // 获取删除权限状态
  static bool get hasDeletePermission => _hasDeletePermission;
  static bool get hasCompressPermission => _hasCompressPermission;
  static bool get hasAlbumPermission => _hasAlbumPermission;
  
  // 请求删除权限
  static Future<bool> requestDeletePermission(BuildContext context) async {
    if (_hasDeletePermission) return true;
    
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('删除权限确认'),
        content: const Text(
          '您即将开始删除照片操作。\n\n'
          '• 删除的照片将无法恢复\n'
          '• 本次会话中不会再次询问\n'
          '• 您可以随时在设置中重置权限\n\n'
          '确定要继续吗？',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              _hasDeletePermission = true;
              Navigator.pop(context, true);
            },
            child: const Text('确定，开始删除'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  // 请求压缩权限
  static Future<bool> requestCompressPermission(BuildContext context) async {
    if (_hasCompressPermission) return true;
    
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('压缩权限确认'),
        content: const Text(
          '您即将开始压缩照片操作。\n\n'
          '• 压缩后图片质量会有所降低\n'
          '• 原图将被压缩版本替换\n'
          '• 本次会话中不会再次询问\n\n'
          '确定要继续吗？',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              _hasCompressPermission = true;
              Navigator.pop(context, true);
            },
            child: const Text('确定，开始压缩'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  // 请求相册操作权限
  static Future<bool> requestAlbumPermission(BuildContext context) async {
    if (_hasAlbumPermission) return true;
    
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('相册操作确认'),
        content: const Text(
          '您即将开始相册整理操作。\n\n'
          '• 照片将被添加到指定相册\n'
          '• 本次会话中不会再次询问\n'
          '• 您可以随时修改照片的相册分类\n\n'
          '确定要继续吗？',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              _hasAlbumPermission = true;
              Navigator.pop(context, true);
            },
            child: const Text('确定，开始整理'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  // 重置所有权限（用于设置页面）
  static void resetAllPermissions() {
    _hasDeletePermission = false;
    _hasCompressPermission = false;
    _hasAlbumPermission = false;
  }
  
  // 显示操作成功提示
  static void showSuccessMessage(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color ?? CupertinoColors.systemGreen,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // 显示操作失败提示
  static void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle_fill,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: CupertinoColors.systemRed,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // 显示批量操作确认
  static Future<bool> showBatchOperationConfirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }
}