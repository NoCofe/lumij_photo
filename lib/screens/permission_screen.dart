import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/photo_service.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionGranted;

  const PermissionScreen({
    super.key,
    required this.onPermissionGranted,
  });

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.lock_shield,
                size: 80,
                color: CupertinoColors.systemBlue,
              ),
              const SizedBox(height: 24),
              const Text(
                '需要相册访问权限',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Lumij Photo 需要访问您的相册来帮助您整理照片。',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '我们承诺：',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPromiseItem('🔒', '所有数据都在您的设备上处理'),
                    _buildPromiseItem('🚫', '不会上传任何照片到服务器'),
                    _buildPromiseItem('📱', '完全离线运行，保护您的隐私'),
                    _buildPromiseItem('🗑️', '您可以随时删除应用和数据'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_isRequesting)
                const CupertinoActivityIndicator()
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: _requestPermission,
                        child: const Text('授权访问相册'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      onPressed: _openSettings,
                      child: const Text('打开设置'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromiseItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      final hasPermission = await PhotoService.requestPermission();
      
      if (hasPermission) {
        widget.onPermissionGranted();
      } else {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isRequesting = false;
      });
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  void _showPermissionDeniedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('权限被拒绝'),
        content: const Text(
          '无法获取相册访问权限。您可以在设置中手动开启权限，或者点击"打开设置"按钮。',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后再说'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _openSettings();
            },
            child: const Text('打开设置'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('出现错误'),
        content: Text('请求权限时出现错误：$error'),
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