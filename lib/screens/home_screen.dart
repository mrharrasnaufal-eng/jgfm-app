import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'home_tabs/untukmu_tab.dart';
import 'home_tabs/terbaru_tab.dart';
import 'home_tabs/peringkat_tab.dart';
import 'home_tabs/kategori_tab.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final String logoUrl;
  final String announcement;

  const HomeScreen({
    super.key,
    this.logoUrl = '',
    this.announcement = '',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabLabels = [
    AppStrings.tabUntukmu,
    AppStrings.tabTerbaru,
    AppStrings.tabPeringkat,
    AppStrings.tabKategori,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar area
            _buildAppBar(),

            // Announcement banner
            if (widget.announcement.isNotEmpty) _buildAnnouncement(),

            // TabBar
            _buildTabBar(),

            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  UntukmuTab(),
                  TerbaruTab(),
                  PeringkatTab(),
                  KategoriTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Logo
          if (widget.logoUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                width: 28,
                height: 28,
                child: Image.network(
                  widget.logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.movie_filter_rounded,
                    color: AppTheme.accent,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ] else ...[
            const Icon(
              Icons.movie_filter_rounded,
              color: AppTheme.accent,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          const Text(
            AppStrings.appName,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Search button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
            icon: const Icon(
              Icons.search_rounded,
              color: AppTheme.textPrimary,
              size: 24,
            ),
            tooltip: 'Cari',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          // Koin button
          IconButton(
            onPressed: () {
              // TODO: Navigate to koin/coins screen
            },
            icon: const Icon(
              Icons.monetization_on_rounded,
              color: AppTheme.gold,
              size: 24,
            ),
            tooltip: 'Koin',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncement() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.campaign_rounded,
            color: AppTheme.secondary.withOpacity(0.8),
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.announcement,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppFontSize.caption,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textTertiary,
        labelStyle: const TextStyle(
          fontSize: AppFontSize.body,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: AppFontSize.body,
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: AppTheme.accent,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        dividerHeight: 0,
        tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
      ),
    );
  }
}


