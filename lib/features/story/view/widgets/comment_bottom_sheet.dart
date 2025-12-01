// lib/features/story/view/widgets/comment_bottom_sheet.dart

import 'package:curemate/features/story/model/story_model.dart';
import 'package:curemate/services/api_service.dart';
import 'package:flutter/material.dart';

class CommentBottomSheet extends StatefulWidget {
  final List<CureFeedback> initialFeedbacks;
  final int cureStorySeq;

  const CommentBottomSheet({
    super.key,
    required this.initialFeedbacks,
    required this.cureStorySeq,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  late final List<CureFeedback> _feedbacks;

  @override
  void initState() {
    super.initState();
    _feedbacks = widget.initialFeedbacks;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Text('댓글', style: theme.textTheme.titleMedium),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _feedbacks.isEmpty
                    ? const Center(child: Text('가장 먼저 댓글을 남겨보세요!'))
                    : ListView.builder(
                        controller: controller,
                        itemCount: _feedbacks.length,
                        itemBuilder: (context, index) {
                          final feedback = _feedbacks[index];
                          return _CommentGroup(feedback: feedback);
                        },
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 18), // TODO: 현재 사용자 프로필 이미지
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        decoration: const InputDecoration(
                          hintText: '댓글 달기...',
                          border: InputBorder.none,
                          filled: false,
                        ),
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: 댓글 게시 API 호출 및 목록 새로고침
                        _commentController.clear();
                        _commentFocusNode.unfocus();
                      },
                      child: const Text('게시'),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class _CommentGroup extends StatelessWidget {
  final CureFeedback feedback;

  const _CommentGroup({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentTile(feedback: feedback),
        if (feedback.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 50.0),
            child: Column(
              children: feedback.replies
                  .map((reply) => _CommentGroup(feedback: reply))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// 단일 댓글 UI (새로운 레이아웃 적용)
class _CommentTile extends StatelessWidget {
  final CureFeedback feedback;

  const _CommentTile({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final String baseUrl = ApiService().baseUrl;
    final theme = Theme.of(context);

    final profileUrl = feedback.custProfile?.detailList.isNotEmpty == true
        ? feedback.custProfile!.detailList.first.mediaThumbUrl
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: profileUrl != null && profileUrl.isNotEmpty ? NetworkImage(baseUrl + profileUrl) : null,
            child: profileUrl == null || profileUrl.isEmpty ? const Icon(Icons.person, size: 18) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1행: 작성자, 작성시간
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        feedback.custNickname,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      feedback.regDttm, // TODO: 시간 포매팅
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 2행: 댓글 내용
                Text(feedback.cureFeedbackDesc, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),

                // 3행: 답글 달기
                Text(
                  '답글 달기',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 댓글 좋아요 버튼
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.favorite_border, size: 16, color: theme.colorScheme.secondary),
            onPressed: () {
              print("댓글 좋아요 버튼");
            },
          )
        ],
      ),
    );
  }
}
