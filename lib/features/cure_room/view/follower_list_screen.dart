import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/cure_room/model/cure_room_models.dart';
import 'package:curemate/services/cure_room_service.dart';
import 'package:flutter/material.dart';

class CureRoomFollowerListScreen extends StatefulWidget {
  final int cureSeq;
  final String roomName; // 상단에 살짝 써주면 좋음

  const CureRoomFollowerListScreen({
    super.key,
    required this.cureSeq,
    required this.roomName,
  });

  @override
  State<CureRoomFollowerListScreen> createState() =>
      _CureRoomFollowerListScreenState();
}

class _CureRoomFollowerListScreenState
    extends State<CureRoomFollowerListScreen> {
  final _service = CureRoomService();

  bool _isLoading = false;
  String? _error;
  List<CureInterestModel> _followers = [];

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final list = await _service.getCureInterestList(widget.cureSeq);
    if (!mounted) return;

    setState(() {
      _followers = list;

      // 🔥 개발용 더미 데이터 채우기
      if (_followers.isEmpty) {
        _followers = [
          CureInterestModel(
            cureInterestSeq: 1,
            custSeq: 10,
            cureSeq: widget.cureSeq,
            custNm: '김철수',
            custNickname: '철수',
            custMediaGroupSeq: 0,
            interestProfile: null,
            withdrawYn: 'N',
            regDttm: '2025-12-01',
          ),
          CureInterestModel(
            cureInterestSeq: 2,
            custSeq: 20,
            cureSeq: widget.cureSeq,
            custNm: '이영희',
            custNickname: '영희',
            custMediaGroupSeq: 0,
            interestProfile: null,
            withdrawYn: 'N',
            regDttm: '2025-12-01',
          ),
          CureInterestModel(
            cureInterestSeq: 3,
            custSeq: 21,
            cureSeq: widget.cureSeq,
            custNm: '정해성',
            custNickname: 'Damon',
            custMediaGroupSeq: 0,
            interestProfile: null,
            withdrawYn: 'Y',
            regDttm: '2025-12-01',
          ),
        ];
      }
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _error = '팔로워 목록을 가져오지 못했어요.\n$e';
    });
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final followerCount = _followers.length;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          '팔로워 목록',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.blueTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : _buildContent(followerCount),
      ),
    );
  }

  Widget _buildContent(int followerCount) {
  if (_followers.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '아직 이 큐어룸을 팔로우한 사용자가 없어요.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.blueTextSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 큐어룸 이름 살짝 보여주기
          Text(
            widget.roomName,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          // "팔로워 N"
          Text(
            '팔로워 $followerCount',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.blueTextSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // 하얀 카드 + 리스트
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListView.separated(
                itemCount: _followers.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.lightGrey),
                itemBuilder: (context, index) {
                  final follower = _followers[index];
                  return _buildFollowerRow(follower);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildFollowerRow(CureInterestModel follower) {
  final imgUrl = follower.profileImgUrl;
  final nickname = (follower.custNickname.isNotEmpty)
      ? follower.custNickname
      : follower.custNm; // 닉네임 없으면 실명 fallback

  return ListTile(
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    leading: CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.lightGrey,
      backgroundImage: imgUrl != null ? NetworkImage(imgUrl) : null,
      child: imgUrl == null
          ? Text(
              nickname.substring(0, 1),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            )
          : null,
    ),

    // 🔹 닉네임만 표시!
    title: Text(
      nickname,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.blueTextSecondary,
      ),
    ),

    // 🔹 subtitle 제거
    subtitle: null,

    trailing: follower.isWithdrawn
        ? const Text(
            '탈퇴',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.grey,
            ),
          )
        : null,

    onTap: () {
      // TODO: 나중에 프로필로 이동
    },
  );
}
}
