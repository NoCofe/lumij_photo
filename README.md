# Lumij Photo - 智能离线相册整理应用

一款专为iOS风格设计的智能相册整理应用，帮助您轻松管理和整理照片，完全离线运行，保护您的隐私。

## ✨ 主要功能

### 🔍 智能识别乱糟糟的相册
- **重复照片检测**: 智能识别相似或重复的照片视频，按相似度排序
- **大文件识别**: 快速找出占用空间最多的大照片大视频，按文件大小排序  
- **智能分类**: 按相簿和日期自动分类整理
- **进度追踪**: 快速查看每月整理进度，了解相册状态

### 📱 轻轻一划，快速整理
- **直观手势操作**:
  - 左右划动：切换照片
  - 向上滑动：删除照片
  - 向下滑动：压缩照片（节省存储空间）
- **一键添加**: 快速将照片添加到指定相簿
- **批量处理**: 高效处理大量照片

### 💝 贴心功能
- **智能提醒**: 自定义每周提醒，时刻保持图库井然有序
- **原生设计**: 极简、原生iOS风格设计，仿佛苹果自带软件
- **完全离线**: 所有数据都在您的设备上处理，隐私无忧
- **压缩优化**: 智能压缩算法，在保持质量的同时节省空间

## 🛠 技术特性

- **Flutter框架**: 跨平台原生性能
- **离线优先**: 无需网络连接，完全本地处理
- **智能算法**: 基于文件哈希的重复检测
- **数据库存储**: SQLite本地数据库，快速检索
- **权限管理**: 安全的相册访问权限控制

## 📱 支持平台

- iOS 12.0+
- Android 6.0+

## 🚀 开始使用

### 环境要求
- Flutter 3.8.1+
- Dart 3.0+
- iOS开发需要Xcode 14+
- Android开发需要Android Studio

### 安装步骤

1. 克隆项目
```bash
git clone https://github.com/your-username/lumij_photo.git
cd lumij_photo
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
# iOS
flutter run -d ios

# Android  
flutter run -d android
```

## 📦 主要依赖

- `photo_manager`: 相册和媒体文件访问
- `flutter_image_compress`: 图片压缩处理
- `sqflite`: 本地数据库存储
- `provider`: 状态管理
- `permission_handler`: 权限管理
- `flutter_local_notifications`: 本地通知

## 🏗 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── photo_model.dart     # 照片数据模型
│   └── album_model.dart     # 相册数据模型
├── services/                # 服务层
│   ├── database_service.dart    # 数据库服务
│   ├── photo_service.dart       # 照片处理服务
│   └── notification_service.dart # 通知服务
├── providers/               # 状态管理
│   └── photo_provider.dart # 照片状态管理
├── screens/                 # 页面
│   ├── home_screen.dart         # 主页面
│   ├── photo_organizer_screen.dart # 照片整理页面
│   └── settings_screen.dart     # 设置页面
└── widgets/                 # 组件
    ├── photo_grid.dart          # 照片网格
    ├── photo_item.dart          # 照片项
    ├── album_item.dart          # 相册项
    ├── stats_card.dart          # 统计卡片
    └── swipeable_photo_card.dart # 可滑动照片卡片
```

## 🔒 隐私保护

- ✅ 完全离线运行，不上传任何数据
- ✅ 所有照片处理都在本地完成
- ✅ 不收集任何个人信息
- ✅ 开源透明，代码可审查

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 联系我们

如有问题或建议，请通过以下方式联系：
- 提交 GitHub Issue
- 发送邮件至：[your-email@example.com]

---

**Lumij Photo** - 让相册整理变得简单而优雅 📸✨
