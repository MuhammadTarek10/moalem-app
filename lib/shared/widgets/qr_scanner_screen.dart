import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  final bool isMultiScan;
  final Future<String?> Function(String)? onCodeScanned;
  final String? title;

  const QrScannerScreen({
    super.key,
    this.isMultiScan = false,
    this.onCodeScanned,
    this.title,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final List<String> _scannedCodes = [];
  String? _lastScannedName;
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        if (!widget.isMultiScan) {
          Navigator.pop(context, code);
          return;
        }

        if (_scannedCodes.contains(code)) {
          // Already scanned
          return;
        }

        setState(() {
          _isProcessing = true;
        });

        if (widget.onCodeScanned != null) {
          final name = await widget.onCodeScanned!(code);
          if (name != null) {
            setState(() {
              _scannedCodes.add(code);
              _lastScannedName = name;
            });
          }
        } else {
          setState(() {
            _scannedCodes.add(code);
          });
        }

        // Delay a bit to allow user to see feedback and prevent rapid scans
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ??
              (widget.isMultiScan ? 'تحديد الطلاب' : 'Scan QR Code'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _handleCapture),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250.w,
              height: 250.w,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.orange : AppColors.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : null,
            ),
          ),

          // Feedback text
          Positioned(
            top: 50.h,
            left: 20.w,
            right: 20.w,
            child: Column(
              children: [
                if (widget.isMultiScan)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'تم تحديد: ${_scannedCodes.length}',
                      style: TextStyle(color: Colors.white, fontSize: 18.sp),
                    ),
                  ),
                if (_lastScannedName != null)
                  Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        _lastScannedName!,
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Action Buttons
          if (widget.isMultiScan)
            Positioned(
              bottom: 40.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isProcessing = false;
                        _lastScannedName = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'تحديد طالب اخر',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: _scannedCodes.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context, _scannedCodes);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'إضافة الدرجة',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Positioned(
              bottom: 50.h,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Point camera at QR code',
                  style: TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
