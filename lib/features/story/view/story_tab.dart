// lib/features/story/view/story_tab.dart

import 'package:curemate/features/story/model/story_model.dart';
import 'package:curemate/features/story/view/widgets/comment_bottom_sheet.dart';
import 'package:curemate/features/story/viewmodel/story_viewmodel.dart';
import 'package:curemate/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StoryTab extends StatelessWidget {
  const StoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<StoryViewModel>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          primary: false,
          title: Text('뿌듯일지', style: theme.textTheme.titleLarge),
          floating: true,
          snap: true,
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: Icon(Icons.add_box_outlined, color: theme.appBarTheme.actionsIconTheme?.color),
              onPressed: () {
                // TODO: 새 게시글 작성 화면으로 이동
              },
            ),
          ],
        ),
        _buildBody(context, viewModel),
      ],
    );
  }

  Widget _buildBody(BuildContext context, StoryViewModel viewModel) {
    if (viewModel.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (viewModel.stories.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text('첫 번째 뿌듯일지를 작성해보세요!'),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final story = viewModel.stories[index];
          return StoryPostItem(story: story);
        },
        childCount: viewModel.stories.length,
      ),
    );
  }
}

class StoryPostItem extends StatefulWidget {
  final StoryModel story;

  const StoryPostItem({super.key, required this.story});

  @override
  State<StoryPostItem> createState() => _StoryPostItemState();
}

class _StoryPostItemState extends State<StoryPostItem> {
  bool _isExpanded = false;
  int _currentPageIndex = 0; // 현재 이미지 페이지 인덱스

  // 숫자를 포매팅하는 헬퍼 함수
  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}만';
    }
    return NumberFormat('#,###').format(count);
  }

  // 아이콘과 카운트를 보여주는 재사용 가능한 버튼 위젯
  Widget _buildActionChip(BuildContext context, {
    required IconData icon,
    int? count,
    Color? iconColor,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Row의 크기를 내용물에 맞게 조절
          children: [
            Icon(icon, color: iconColor ?? colorScheme.secondary, size: 22),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count),
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final String baseUrl = ApiService().baseUrl;

    final String? profileImageUrl = widget.story.cureProfile?.detailList.isNotEmpty == true
        ? widget.story.cureProfile!.detailList.first.mediaThumbUrl
        : null;

    final imageDetails = widget.story.storyProfile?.detailList;

    final bool showSeeMore = widget.story.cureStoryDesc.length > 100 && !_isExpanded;
    final bool isInterested = widget.story.interestYn == 'Y';

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? NetworkImage("$baseUrl$profileImageUrl")
                      : null,
                  child: (profileImageUrl == null || profileImageUrl.isEmpty)
                      ? const Icon(Icons.storefront, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.story.cureNm,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    isInterested ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16,
                    color: isInterested ? colorScheme.primary : colorScheme.secondary,
                  ),
                  label: Text(
                    isInterested ? '관심환자' : '비관심환자',
                    style: textTheme.labelSmall?.copyWith(
                      color: isInterested ? colorScheme.primary : colorScheme.secondary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: isInterested
                        ? colorScheme.primary.withOpacity(0.1)
                        : colorScheme.secondary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.story.regDttm.length > 10 ? widget.story.regDttm.substring(0, 10) : widget.story.regDttm,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.secondary),
                )
              ],
            ),
          ),

          // 2. 본문 이미지
          if (imageDetails != null && imageDetails.isNotEmpty)
            Column(
              children: [
                AspectRatio(
                  aspectRatio: 1 / 1,
                  child: PageView.builder(
                    itemCount: imageDetails.length,
                    onPageChanged: (index) => setState(() => _currentPageIndex = index),
                    itemBuilder: (context, index) {
                      final detail = imageDetails[index];
                      final String? relativeUrl = detail.mediaUrl;
                      final String? imageUrl = relativeUrl != null ? "$baseUrl$relativeUrl" : null;
                      return imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Container(color: Colors.grey[200], child: const Center(child: Text('이미지 로드 실패')));
                    },
                  ),
                ),
                if (imageDetails.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(imageDetails.length, (index) {
                      return Container(
                        width: 8.0, height: 8.0,
                        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPageIndex == index
                              ? colorScheme.primary
                              : colorScheme.secondary.withOpacity(0.4),
                        ),
                      );
                    }),
                  ),
              ],
            )
          else
            AspectRatio(
              aspectRatio: 1 / 1,
              child: Container(color: Colors.grey[200], child: const Center(child: Text('미디어 없음'))),
            ),

          // 3. 액션 버튼 (모두 _buildActionChip으로 통일)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Row(
              children: [
                _buildActionChip(
                  context,
                  icon: false ? Icons.favorite : Icons.favorite_border, // TODO: 좋아요 여부 연동
                  iconColor: false ? colorScheme.error : colorScheme.secondary,
                  count: widget.story.cheeringCount,
                  onPressed: () {},
                ),
                _buildActionChip(
                  context,
                  icon: Icons.chat_bubble_outline,
                  count: widget.story.feedbackCount,
                  onPressed: () async {
                    // ViewModel을 통해 댓글 데이터를 가져옵니다.
                    final feedbacks = await context.read<StoryViewModel>().fetchFeedbacks(widget.story.cureStorySeq);
                    
                    // BottomSheet를 띄웁니다.
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => CommentBottomSheet(
                        initialFeedbacks: feedbacks,
                        cureStorySeq: widget.story.cureStorySeq,
                      ),
                    );
                  },
                ),
                const Spacer(),
                _buildActionChip(context, icon: Icons.share_outlined, onPressed: () {}),
                _buildActionChip(context, icon: Icons.more_horiz, onPressed: () {}),
              ],
            ),
          ),

          // 4. 본문 내용
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: showSeeMore ? () => setState(() => _isExpanded = true) : null,
                  child: RichText(
                    text: TextSpan(
                      style: textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: "${widget.story.custNickname} ",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: widget.story.cureStoryDesc),
                      ],
                    ),
                    maxLines: _isExpanded ? null : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showSeeMore)
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = true),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text('...더보기', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
