import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/operation_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _weeklyReminderEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            
            // 通知设置
            _buildSection(
              title: '通知设置',
              children: [
                _buildSwitchTile(
                  title: '每周整理提醒',
                  subtitle: '每周日上午10点提醒您整理照片',
                  value: _weeklyReminderEnabled,
                  onChanged: (value) {
                    setState(() {
                      _weeklyReminderEnabled = value;
                    });
                    if (value) {
                      _showSuccessMessage('已开启每周提醒');
                    } else {
                      _showSuccessMessage('已关闭每周提醒');
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 操作设置
            _buildSection(
              title: '操作设置',
              children: [
                _buildTile(
                  title: '重置操作权限',
                  subtitle: '重置删除、压缩、相册操作的确认权限',
                  trailing: const Icon(CupertinoIcons.refresh),
                  onTap: () => _resetOperationPermissions(),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 存储设置
            _buildSection(
              title: '存储设置',
              children: [
                _buildTile(
                  title: '清理缓存',
                  subtitle: '清理应用缓存文件',
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () => _showClearCacheDialog(),
                ),
                _buildTile(
                  title: '压缩质量',
                  subtitle: '调整照片压缩质量',
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () => _showCompressionSettings(),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 关于
            _buildSection(
              title: '关于',
              children: [
                _buildTile(
                  title: '版本信息',
                  subtitle: 'Lumij Photo v1.0.0',
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () => _showAboutDialog(),
                ),
                _buildTile(
                  title: '隐私政策',
                  subtitle: '查看隐私政策',
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () => _showPrivacyPolicy(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  void _showClearCacheDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('清理缓存'),
        content: const Text('确定要清理应用缓存吗？这将删除所有临时文件。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              // TODO: 实现清理缓存逻辑
              _showSuccessMessage('缓存已清理');
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showCompressionSettings() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('选择压缩质量'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('已设置为高质量');
            },
            child: const Text('高质量 (90%)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('已设置为中等质量');
            },
            child: const Text('中等质量 (70%)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('已设置为低质量');
            },
            child: const Text('低质量 (50%)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('关于 Lumij Photo'),
        content: const Text(
          'Lumij Photo 是一款智能离线相册整理应用，帮助您轻松管理和整理照片。\n\n'
          '• 完全离线运行，保护隐私\n'
          '• 智能识别重复照片\n'
          '• 一键压缩大文件\n'
          '• 简洁的iOS风格设计',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('隐私政策'),
        content: const Text(
          'Lumij Photo 承诺保护您的隐私：\n\n'
          '• 所有数据都在您的设备上处理\n'
          '• 不会上传任何照片到服务器\n'
          '• 不会收集个人信息\n'
          '• 完全离线运行',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _resetOperationPermissions() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('重置操作权限'),
        content: const Text(
          '重置后，下次进行删除、压缩或相册操作时将重新询问确认。\n\n'
          '这有助于防止误操作。',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              OperationService.resetAllPermissions();
              _showSuccessMessage('操作权限已重置');
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CupertinoColors.systemGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}