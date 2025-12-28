import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/permission_error_handler.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/report_service.dart';
import '../models/report_model.dart';
import '../services/profanity_filter_service.dart';

/// 리포트 화면
/// 
/// WP-4.5: 리포트 및 통계
/// 
/// 매니저가 필터링 통계, 일일/주간/월간 리포트를 조회하고
/// PDF로 다운로드할 수 있는 화면입니다.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportModel? _dailyReport;
  ReportModel? _weeklyReport;
  ReportModel? _monthlyReport;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 리포트 로드
  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 권한 검증
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } on PermissionException catch (e) {
        if (mounted) {
          PermissionErrorHandler.handleError(context, e);
          setState(() {
            _errorMessage = '리포트 조회는 매니저만 사용할 수 있습니다.';
            _isLoading = false;
          });
        }
        return;
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = '권한 확인 중 오류가 발생했습니다: $e';
            _isLoading = false;
          });
        }
        return;
      }

      // 리포트 조회
      final dailyReport = await ReportService.getDailyReport();
      final weeklyReport = await ReportService.getWeeklyReport();
      final monthlyReport = await ReportService.getMonthlyReport();

      if (mounted) {
        setState(() {
          _dailyReport = dailyReport;
          _weeklyReport = weeklyReport;
          _monthlyReport = monthlyReport;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '리포트를 불러오는데 실패했습니다.';
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('권한')) {
          errorMessage = '리포트 조회 권한이 없습니다. 매니저 계정으로 로그인해주세요.';
        } else if (errorString.contains('로그인')) {
          errorMessage = '로그인이 필요합니다.';
        } else if (errorString.contains('네트워크') || errorString.contains('연결')) {
          errorMessage = '네트워크 연결을 확인해주세요.';
        }
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  /// PDF 생성 및 다운로드
  Future<void> _generateAndDownloadPDF(ReportModel report) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF 생성 중...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final pdfBytes = await _generatePDF(report);
      
      if (mounted) {
        // 파일로 저장하고 공유
        await _saveAndSharePDF(pdfBytes, report);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        String userMessage = 'PDF 생성에 실패했습니다.';
        
        if (errorMessage.contains('permission') || errorMessage.contains('권한')) {
          userMessage = 'PDF 생성 권한이 없습니다.';
        } else if (errorMessage.contains('path_provider') || errorMessage.contains('path')) {
          userMessage = '파일 저장 경로를 가져올 수 없습니다.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userMessage\n오류: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      print('❌ PDF 생성 실패: $e');
    }
  }

  /// PDF 파일 저장 및 공유
  Future<void> _saveAndSharePDF(Uint8List pdfBytes, ReportModel report) async {
    try {
      // 파일명 생성 (예: AURA_일일리포트_2024.01.15.pdf)
      final fileName = 'AURA_${_formatPeriod(report.period)}_${_formatDate(report.startDate)}.pdf';
      
      // 임시 디렉토리 가져오기
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      
      // 파일 저장
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      
      if (mounted) {
        // 파일 공유 (다운로드/공유 옵션 제공)
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'AURA 리포트',
          subject: fileName,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF가 생성되었습니다. 파일을 저장하거나 공유할 수 있습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // 공유 실패 시 인쇄 옵션 제공
      print('⚠️ 파일 공유 실패, 인쇄 옵션으로 대체: $e');
      
      if (mounted) {
        final pdfBytes = await _generatePDF(report);
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
      }
    }
  }

  /// PDF 생성
  Future<Uint8List> _generatePDF(ReportModel report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // 헤더
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'AURA 리포트',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatPeriod(report.period),
                    style: pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 리포트 기간
            pw.Text(
              '리포트 기간: ${_formatDate(report.startDate)} ~ ${_formatDate(report.endDate)}',
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 30),

            // 통계 섹션
            pw.Text(
              '통계 요약',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildStatRow('전체 질문 수', '${report.questionStats.totalCount}개'),
            _buildStatRow('필터링된 질문 수', '${report.filteringStats.totalCount}개'),
            _buildStatRow('탐지율', '${report.detectionRate.toStringAsFixed(2)}%'),
            _buildStatRow('위험도 높은 질문', '${report.filteringStats.highCount}개'),
            _buildStatRow('자동 숨김 처리', '${report.filteringStats.autoHiddenCount}개'),
            pw.SizedBox(height: 20),

            // 위험도별 분포
            pw.Text(
              '위험도별 분포',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildStatRow('낮음', '${report.filteringStats.lowCount}개'),
            _buildStatRow('중간', '${report.filteringStats.mediumCount}개'),
            _buildStatRow('높음', '${report.filteringStats.highCount}개'),
            pw.SizedBox(height: 20),

            // 트렌딩 키워드
            pw.Text(
              '이슈성 키워드 트렌드 분석',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            if (report.trendingKeywords.isEmpty) ...[
              pw.Text(
                '분석할 키워드 데이터가 없습니다.',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ] else ...[
              ...report.trendingKeywords.take(10).map((keyword) => _buildKeywordRow(keyword)),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildStatRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildKeywordRow(TrendingKeyword keyword) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(keyword.keyword, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            '${keyword.frequency}회 (위험도: ${keyword.riskLevel})',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatPeriod(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.daily:
        return '일일 리포트';
      case ReportPeriod.weekly:
        return '주간 리포트';
      case ReportPeriod.monthly:
        return '월간 리포트';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '리포트 및 통계',
        role: 'manager',
      ),
      body: Column(
        children: [
          // 탭 바
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '일일 리포트'),
              Tab(text: '주간 리포트'),
              Tab(text: '월간 리포트'),
            ],
          ),

          // 탭 내용
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _errorMessage!,
                                style: AppTypography.body1.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              CustomButton(
                                label: '다시 시도',
                                onPressed: _loadReports,
                                variant: ButtonVariant.primary,
                              ),
                            ],
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildReportTab(_dailyReport, ReportPeriod.daily),
                          _buildReportTab(_weeklyReport, ReportPeriod.weekly),
                          _buildReportTab(_monthlyReport, ReportPeriod.monthly),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTab(ReportModel? report, ReportPeriod period) {
    if (report == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '리포트 데이터를 불러오는 중입니다...',
                style: AppTypography.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 리포트 기간
          Text(
            '리포트 기간: ${_formatDate(report.startDate)} ~ ${_formatDate(report.endDate)}',
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 통계 카드
          _buildStatCard(
            '전체 질문 수',
            '${report.questionStats.totalCount}개',
            Icons.question_answer,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatCard(
            '필터링된 질문 수',
            '${report.filteringStats.totalCount}개',
            Icons.filter_list,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatCard(
            '탐지율',
            '${report.detectionRate.toStringAsFixed(2)}%',
            Icons.trending_up,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatCard(
            '위험도 높은 질문',
            '${report.filteringStats.highCount}개',
            Icons.warning,
            color: Colors.red,
          ),
          const SizedBox(height: AppSpacing.lg),

          // 위험도별 분포
          Text(
            '위험도별 분포',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildRiskDistributionCard(report.filteringStats),
          const SizedBox(height: AppSpacing.lg),

          // 트렌딩 키워드 (트렌드 분석)
          Text(
            '이슈성 키워드 트렌드 분석',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (report.trendingKeywords.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '분석할 키워드 데이터가 없습니다.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '필터링된 질문이 있으면 트렌드 분석이 표시됩니다.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...report.trendingKeywords.map((keyword) => _buildKeywordCard(keyword)),
          const SizedBox(height: AppSpacing.lg),

          // PDF 다운로드 버튼
          CustomButton(
            label: 'PDF 다운로드',
            onPressed: () => _generateAndDownloadPDF(report),
            variant: ButtonVariant.primary,
            isFullWidth: true,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color? color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.primary, size: 32),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color ?? AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskDistributionCard(FilteringStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _buildRiskRow('낮음', stats.lowCount, Colors.blue),
            const SizedBox(height: AppSpacing.sm),
            _buildRiskRow('중간', stats.mediumCount, Colors.orange),
            const SizedBox(height: AppSpacing.sm),
            _buildRiskRow('높음', stats.highCount, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body2,
          ),
        ),
        Text(
          '$count개',
          style: AppTypography.body2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordCard(TrendingKeyword keyword) {
    Color riskColor;
    switch (keyword.riskLevel) {
      case 'high':
        riskColor = Colors.red;
        break;
      case 'medium':
        riskColor = Colors.orange;
        break;
      case 'low':
      default:
        riskColor = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    keyword.keyword,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${keyword.frequency}회 탐지',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                keyword.riskLevel == 'high'
                    ? '위험'
                    : keyword.riskLevel == 'medium'
                        ? '주의'
                        : '낮음',
                style: AppTypography.caption.copyWith(
                  color: riskColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

