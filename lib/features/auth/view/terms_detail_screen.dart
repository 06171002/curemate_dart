// lib/features/auth/view/terms_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/services/terms_service.dart';
import 'package:curemate/features/auth/model/policy_model.dart';
import 'package:curemate/features/auth/viewmodel/auth_viewmodel.dart';

class TermsDetailScreen extends StatefulWidget {
  final int initialPolicySeq; // 활성화할 약관 ID (쿼리 파라미터로 받음)

  const TermsDetailScreen({
    super.key,
    required this.initialPolicySeq,
  });

  @override
  State<TermsDetailScreen> createState() => _TermsDetailScreenState();
}

class _TermsDetailScreenState extends State<TermsDetailScreen> with TickerProviderStateMixin {
  final TermsService _termsService = TermsService();

  TabController? _tabController; // 데이터 로드 후 초기화되므로 nullable
  List<PolicyModel> _policies = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPolicies();
    });
  }

  // API 호출하여 약관 목록 로드
  Future<void> _loadPolicies() async {
    // 1. AuthViewModel에서 custSeq 가져오기
    final authViewModel = context.read<AuthViewModel>();
    final int? custSeq = authViewModel.custSeq;

    if (custSeq == null) {
      if (mounted) {
        setState(() {
          _errorMessage = '사용자 정보를 찾을 수 없습니다.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // 2. custSeq 전달 및 isDetail: true 설정 (상세 내용 포함 조회)
      final allPolicies = await _termsService.getPolicyList(isDetail: true);

      final List<PolicyModel> validPolicies = allPolicies.where((policy) {
        return policy.policyDesc != null && policy.policyDesc!.trim().isNotEmpty;
      }).toList();

      if (mounted) {
        setState(() {
          _policies = validPolicies;
          _isLoading = false;

          // 탭 컨트롤러 초기화
          if (_policies.isNotEmpty) {
            // 전달받은 ID에 해당하는 인덱스 찾기
            int initialIndex = _policies.indexWhere((p) => p.policySeq == widget.initialPolicySeq);
            if (initialIndex == -1) initialIndex = 0; // 못 찾으면 첫 번째

            _tabController = TabController(
              length: _policies.length,
              vsync: this,
              initialIndex: initialIndex,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '약관 내용을 불러오는데 실패했습니다.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppColors.mainBtn)),
      );
    }

    if (_errorMessage != null || _policies.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text('오류', style: TextStyle(color: Colors.black)),
        ),
        body: Center(child: Text(_errorMessage ?? '약관 데이터가 없습니다.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          '약관 상세',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        // ✅ 탭바 구성
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // 탭이 많으면 스크롤 가능
          labelColor: AppColors.mainBtn,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.mainBtn,
          indicatorWeight: 3,
          tabAlignment: TabAlignment.start, // Flutter 3.13+ 정렬 옵션
          tabs: _policies.map((policy) {
            return Tab(text: policy.policyNm);
          }).toList(),
        ),
      ),
      // ✅ 탭 내용 (좌우 슬라이드)
      body: TabBarView(
        controller: _tabController,
        children: _policies.map((policy) {
          return _buildPolicyContent(policy);
        }).toList(),
      ),
    );
  }

  Widget _buildPolicyContent(PolicyModel policy) {
    if (policy.policyDesc == null || policy.policyDesc!.isEmpty) {
      return const Center(
        child: Text('상세 내용이 없습니다.', style: TextStyle(color: Colors.grey)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Html(
        data: policy.policyDesc,
        style: {
          "body": Style(
            fontSize: FontSize(14.0),
            color: Colors.black87,
            lineHeight: LineHeight(1.6),
            margin: Margins.zero,
          ),
          "h3": Style(
            fontSize: FontSize(16.0),
            fontWeight: FontWeight.bold,
            margin: Margins.only(top: 20, bottom: 10),
          ),
        },
      ),
    );
  }
}