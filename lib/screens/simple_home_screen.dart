import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'demo_organizer_screen.dart';

class SimpleHomeScreen extends StatelessWidget {
  const SimpleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 标题栏
            const SliverAppBar(
              title: Text(
                'Lumij Photo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.transparent,
              floating: true,
            ),
            
            // 欢迎信息
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            CupertinoIcons.photo_on_rectangle,
                            size: 64,
                            color: CupertinoColors.systemBlue,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '欢迎使用 Lumij Photo',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '智能离线相册整理应用',
                            style: TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 24),
                          CupertinoButton.filled(
                            onPressed: () {
                              _showPermissionDialog(context);
                            },
                            child: const Text('开始整理相册'),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 功能介绍
                    _buildFeatureCard(
                      icon: CupertinoIcons.doc_on_doc,
                      title: '智能识别重复照片',
                      description: '自动检测相似和重复的照片，帮您节省存储空间',
                      color: CupertinoColors.systemOrange,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildFeatureCard(
                      icon: CupertinoIcons.folder_fill,
                      title: '查找大文件',
                      description: '快速定位占用空间最多的照片和视频',
                      color: CupertinoColors.systemRed,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildFeatureCard(
                      icon: CupertinoIcons.hand_draw,
                      title: '手势快速整理',
                      description: '通过简单的滑动手势快速删除或压缩照片',
                      color: CupertinoColors.systemGreen,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildFeatureCard(
                      icon: CupertinoIcons.lock_shield,
                      title: '完全离线运行',
                      description: '所有数据都在您的设备上处理，隐私无忧',
                      color: CupertinoColors.systemPurple,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('需要相册访问权限'),
        content: const Text(
          'Lumij Photo 需要访问您的相册来帮助您整理照片。\n\n'
          '我们承诺：\n'
          '• 所有数据都在您的设备上处理\n'
          '• 不会上传任何照片到服务器\n'
          '• 完全离线运行，保护您的隐私',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后再说'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const DemoOrganizerScreen(),
                ),
              );
            },
            child: const Text('体验演示'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('功能开发中'),
        content: const Text(
          '完整的相册整理功能正在开发中，敬请期待！\n\n'
          '当前版本展示了应用的界面设计和基本架构。',
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
}