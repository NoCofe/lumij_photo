import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import 'photo_item.dart';
import 'album_item.dart';

class PhotoGrid extends StatelessWidget {
  final List<dynamic> photos;
  final String title;

  const PhotoGrid({
    super.key,
    required this.photos,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.photo,
                size: 48,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(height: 16),
              Text(
                '暂无$title',
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            MasonryGridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final item = photos[index];
                if (item is PhotoModel) {
                  return PhotoItem(photo: item);
                } else if (item is AlbumModel) {
                  return AlbumItem(album: item);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}