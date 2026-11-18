import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../dashboard/viewmodels/home_viewmodel.dart';
import '../../viewmodels/analytics_viewmodel.dart';

class SystemSettingsModal extends StatefulWidget {
  final String initialUrl;

  const SystemSettingsModal({
    super.key,
    required this.initialUrl,
  });

  /// Hàm tiện ích gọi mở Modal từ bất kỳ đâu
  static Future<void> show(BuildContext context) async {
    final currentUrl = await ApiClient.instance.getBaseUrl();
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SystemSettingsModal(initialUrl: currentUrl),
    );
  }

  @override
  State<SystemSettingsModal> createState() => _SystemSettingsModalState();
}

class _SystemSettingsModalState extends State<SystemSettingsModal> {
  late final TextEditingController _urlController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleResetSeedData() async {
    setState(() => _isSubmitting = true);
    final analyticsVm = context.read<AnalyticsViewModel>();
    final homeVm = context.read<HomeViewModel>();

    await analyticsVm.resetAndSeedDemoData();
    await homeVm.loadDashboard();

    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleSaveUrl() async {
    setState(() => _isSubmitting = true);
    final analyticsVm = context.read<AnalyticsViewModel>();
    final homeVm = context.read<HomeViewModel>();

    await analyticsVm.updateBackendUrl(_urlController.text);
    await homeVm.refreshQuotaStatus();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MDL-03: Cấu hình Hệ thống & Demo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _urlController,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              labelText: 'Backend Server URL (Node.js)',
              hintText: 'http://10.0.2.2:3000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Nạp lại Seed Data',
                  icon: Icons.restore,
                  variant: AppButtonVariant.outline,
                  isLoading: _isSubmitting,
                  onPressed: _handleResetSeedData,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Lưu cấu hình IP',
                  icon: Icons.save_outlined,
                  variant: AppButtonVariant.primary,
                  isLoading: _isSubmitting,
                  onPressed: _handleSaveUrl,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}