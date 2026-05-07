import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';

class EnhancedQrGeneratorScreen extends StatefulWidget {
  const EnhancedQrGeneratorScreen({super.key});

  static Widget builder(BuildContext context) {
    return const EnhancedQrGeneratorScreen();
  }

  @override
  State<EnhancedQrGeneratorScreen> createState() =>
      _EnhancedQrGeneratorScreenState();
}

class _EnhancedQrGeneratorScreenState extends State<EnhancedQrGeneratorScreen> {
  final TextEditingController _contentController = TextEditingController();
  // Customization (size slider) — commented out alongside customization tab.
  // final TextEditingController _sizeController = TextEditingController();

  String _qrData = 'https://example.com';
  double _qrSize = 200.0;
  Color _foregroundColor = Colors.black;
  Color _backgroundColor = Colors.white;
  int _errorLevel = QrErrorCorrectLevel.M;
  bool _hasLogo = false;
  Uint8List? _logoBytes;
  Uint8List? _generatedQrBytes;
  bool _isGenerating = false;

  // URL-only mode: type selector UI commented out.
  // final List<QrType> _qrTypes = [
  //   QrType.url,
  //   QrType.text,
  //   QrType.email,
  //   QrType.phone,
  //   QrType.wifi,
  //   QrType.sms,
  //   QrType.vcard,
  // ];
  // QrType _selectedType = QrType.url;

  // /// 0 = Content, 1 = Customization
  // int _mainTab = 0;

  /// Visual preset (foreground/background for QR)
  int _selectedTemplate = 0;

  static const Color _pageBackground = Color(0xFF1C1F22);
  static const Color _fieldBackground = Color(0xFF25282C);
  static const Color _templateTrayBg = Color(0xFF2A2D32);

  @override
  void initState() {
    super.initState();
    _qrData = 'https://www.example.com';
    // _sizeController.text = _qrSize.toString();
    _contentController.text = _qrData;
    _applyTemplateColors(0);
  }

  void _applyTemplateColors(int index) {
    _selectedTemplate = index;
    final p = theme.colorScheme.primary;
    switch (index) {
      case 0:
        _foregroundColor = p;
        _backgroundColor = _templateTrayBg;
        break;
      case 1:
        _foregroundColor = Colors.black;
        _backgroundColor = Colors.white;
        break;
      case 2:
        _foregroundColor = Colors.white;
        _backgroundColor = _pageBackground;
        break;
      default:
        _foregroundColor = const Color(0xFF1C1F22);
        _backgroundColor = const Color(0xFFE8E8E8);
        break;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    // _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: CustomAppBar(
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowLeftPrimary,
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 16.v),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroHeader(),
              SizedBox(height: 24.v),
              // Content | Customization tabs (customization commented out).
              // _buildMainTabs(),
              // SizedBox(height: 20.v),
              // if (_mainTab == 0)
              _buildContentTab(),
              // else
              //   _buildCustomizationSection(),
              SizedBox(height: 20.v),
              _buildQrPreview(),
              SizedBox(height: 20.v),
              _buildActionButtons(),
              SizedBox(height: 24.v),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      children: [
        CustomImageView(
          imagePath: ImageConstant.imgQrCodeSvgrepoComBlueGray70002,
          height: 80.adaptSize,
          width: 80.adaptSize,
          color: Colors.white38,
        ),
        SizedBox(height: 16.v),
        Text(
          'msg_qr_code_generator_title'.tr,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.v),
        Text(
          'msg_generate_your_customize'.tr.replaceAll('\n', ' '),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  /*
  Widget _buildMainTabs() {
    final primary = theme.colorScheme.primary;
    Widget tabLabel(String key, int index) {
      final selected = _mainTab == index;
      return InkWell(
        onTap: () => setState(() => _mainTab = index),
        child: Column(
          children: [
            Text(
              key.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                color: selected ? primary : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.v),
            Container(
              height: 3.v,
              decoration: BoxDecoration(
                color: selected ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: tabLabel('lbl_content', 0)),
        Expanded(child: tabLabel('lbl_customization', 1)),
      ],
    );
  }
  */

  Widget _buildContentTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // _buildQrTypeSelector(),
        // SizedBox(height: 16.v),
        Text(
          _fieldLabelForType(),
          style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        SizedBox(height: 10.v),
        TextField(
          controller: _contentController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.url,
          maxLines: 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: _fieldBackground,
            hintText: _hintForType(),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.h),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.h,
              vertical: 16.v,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _qrData = value;
            });
          },
        ),
        SizedBox(height: 24.v),
        Text(
          'msg_choose_a_template'.tr,
          style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        SizedBox(height: 12.v),
        _buildTemplateRow(),
      ],
    );
  }

  String _fieldLabelForType() => 'lbl_website_url'.tr;

  String _hintForType() => 'msg_qr_url_placeholder'.tr;

  Widget _buildTemplateRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 14.v),
      decoration: BoxDecoration(
        color: _templateTrayBg,
        borderRadius: BorderRadius.circular(16.h),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, _buildTemplateChip),
      ),
    );
  }

  Widget _buildTemplateChip(int index) {
    final selected = _selectedTemplate == index;
    final primary = theme.colorScheme.primary;
    return InkWell(
      onTap: () => setState(() => _applyTemplateColors(index)),
      borderRadius: BorderRadius.circular(12.h),
      child: Container(
        width: 56.h,
        height: 56.h,
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.22) : _fieldBackground,
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(
            color: selected ? primary : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.qr_code_2,
          color: selected ? primary : Colors.white70,
          size: 28.adaptSize,
        ),
      ),
    );
  }

  /*
  Widget _buildQrTypeSelector() {
    final primary = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "QR Code Type:",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: 8.v),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _qrTypes.map((type) {
              final selected = _selectedType == type;
              return Padding(
                padding: EdgeInsets.only(right: 8.h),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                      _updatePlaceholderText();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.h,
                      vertical: 8.v,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? primary : _fieldBackground,
                      borderRadius: BorderRadius.circular(20.h),
                      border: Border.all(
                        color: selected ? primary : Colors.white12,
                      ),
                    ),
                    child: Text(
                      _getTypeDisplayName(type),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected ? Colors.black87 : Colors.white70,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomizationSection() {
    return Container(
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: _fieldBackground,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'lbl_customization'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.v),
          _buildSizeSelector(),
          SizedBox(height: 16.v),
          _buildColorSelectors(),
          SizedBox(height: 16.v),
          _buildErrorLevelSelector(),
        ],
      ),
    );
  }

  Widget _buildSizeSelector() {
    final primary = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Size: ${_qrSize.toInt()}px",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.v),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: primary,
            inactiveTrackColor: Colors.white24,
            thumbColor: primary,
            overlayColor: primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _qrSize,
            min: 100,
            max: 400,
            divisions: 30,
            onChanged: (value) {
              setState(() {
                _qrSize = value;
                _sizeController.text = value.toInt().toString();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelectors() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Foreground Color",
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 8.v),
              GestureDetector(
                onTap: _selectForegroundColor,
                child: Container(
                  height: 40.v,
                  decoration: BoxDecoration(
                    color: _foregroundColor,
                    borderRadius: BorderRadius.circular(8.h),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.h),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Background Color",
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 8.v),
              GestureDetector(
                onTap: _selectBackgroundColor,
                child: Container(
                  height: 40.v,
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(8.h),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Error Correction Level",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.v),
        Row(
          children: [
            _buildErrorLevelButton("L", QrErrorCorrectLevel.L),
            SizedBox(width: 8.h),
            _buildErrorLevelButton("M", QrErrorCorrectLevel.M),
            SizedBox(width: 8.h),
            _buildErrorLevelButton("Q", QrErrorCorrectLevel.Q),
            SizedBox(width: 8.h),
            _buildErrorLevelButton("H", QrErrorCorrectLevel.H),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorLevelButton(String label, int level) {
    final isSelected = _errorLevel == level;
    final primary = theme.colorScheme.primary;
    return GestureDetector(
      onTap: () {
        setState(() {
          _errorLevel = level;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.v),
        decoration: BoxDecoration(
          color: isSelected ? primary : _templateTrayBg,
          borderRadius: BorderRadius.circular(6.h),
          border: Border.all(color: isSelected ? primary : Colors.white12),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.black87 : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ignore: unused_element — reserved when logo embedding is re-enabled on this screen.
  Widget _buildLogoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Logo (Optional)",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.v),
        Row(
          children: [
            Expanded(
              child: CustomElevatedButton(
                height: 40.v,
                text: _hasLogo ? "Change Logo" : "Add Logo",
                buttonStyle: CustomButtonStyles.outlineBlackTL24,
                buttonTextStyle: CustomTextStyles.titleMediumBold,
                onPressed: _selectLogo,
              ),
            ),
            if (_hasLogo) ...[
              SizedBox(width: 12.h),
              CustomElevatedButton(
                height: 40.v,
                width: 80.h,
                text: "Remove",
                buttonStyle: CustomButtonStyles.fillOnError,
                buttonTextStyle: CustomTextStyles.titleMediumBold,
                onPressed: _removeLogo,
              ),
            ],
          ],
        ),
      ],
    );
  }
  */

  Widget _buildQrPreview() {
    return Container(
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: _fieldBackground,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            "Preview",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.v),
          Container(
            padding: EdgeInsets.all(20.h),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(14.h),
              border: Border.all(color: Colors.white12),
            ),
            child: _buildQrCode(),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCode() {
    if (_qrData.isEmpty) {
      return Container(
        height: _qrSize,
        width: _qrSize,
        decoration: BoxDecoration(
          color: _templateTrayBg,
          borderRadius: BorderRadius.circular(8.h),
        ),
        child: Center(
          child: Text(
            "Enter content to generate QR code",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
        ),
      );
    }

    // Key forces rebuild when colors change; qr_flutter's painter can skip repaint
    // if only styles differ in ways not compared (e.g. container bg vs painter).
    return QrImageView(
      key: ValueKey<int>(
        Object.hash(
          _foregroundColor,
          _backgroundColor,
          _qrSize,
          _errorLevel,
          _qrData,
        ),
      ),
      data: _qrData,
      version: QrVersions.auto,
      size: _qrSize,
      padding: EdgeInsets.zero,
      gapless: true,
      errorCorrectionLevel: _errorLevel,
      backgroundColor: _backgroundColor,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: _foregroundColor,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: _foregroundColor,
      ),
      embeddedImage: _hasLogo && _logoBytes != null
          ? MemoryImage(_logoBytes!)
          : null,
      embeddedImageStyle: _hasLogo && _logoBytes != null
          ? QrEmbeddedImageStyle(size: Size(_qrSize * 0.2, _qrSize * 0.2))
          : null,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomElevatedButton(
                height: 50.v,
                text: _isGenerating ? "Generating..." : "Generate QR Code",
                buttonStyle: CustomButtonStyles.fillPrimary,
                buttonTextStyle: CustomTextStyles.bodySmallBluegray90004,
                onPressed: _isGenerating ? null : _generateQrCode,
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: CustomElevatedButton(
                height: 50.v,
                text: "Save Image",
                buttonStyle: CustomButtonStyles.outlineBlackTL24,
                buttonTextStyle: CustomTextStyles.bodyLargeOnPrimaryContainer,
                onPressed: _generatedQrBytes != null ? _saveQrCode : null,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.v),
        Row(
          children: [
            Expanded(
              child: CustomElevatedButton(
                height: 50.v,
                text: "Share QR Code",
                buttonStyle: CustomButtonStyles.fillYellow,
                buttonTextStyle: CustomTextStyles.bodySmallBluegray90004,
                onPressed: _generatedQrBytes != null ? _shareQrCode : null,
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: CustomElevatedButton(
                height: 50.v,
                text: "Reset",
                buttonStyle: CustomButtonStyles.outlineBlackTL24,
                buttonTextStyle: CustomTextStyles.titleMediumBold,
                onPressed: _resetGenerator,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /*
  void _updatePlaceholderText() {
    switch (_selectedType) {
      case QrType.url:
        _contentController.text = 'https://www.example.com';
        break;
      case QrType.text:
        _contentController.text = 'Hello, World!';
        break;
      case QrType.email:
        _contentController.text = 'mailto:example@email.com';
        break;
      case QrType.phone:
        _contentController.text = 'tel:+1234567890';
        break;
      case QrType.wifi:
        _contentController.text = 'WIFI:T:WPA;S:MyNetwork;P:password123;;';
        break;
      case QrType.sms:
        _contentController.text = 'sms:+1234567890';
        break;
      case QrType.vcard:
        _contentController.text =
            'BEGIN:VCARD\nVERSION:3.0\nFN:John Doe\nEND:VCARD';
        break;
    }
    _qrData = _contentController.text;
  }

  void _selectForegroundColor() async {
    final color = await _showColorPicker(_foregroundColor);
    if (color != null) {
      setState(() {
        _foregroundColor = color;
      });
    }
  }

  void _selectBackgroundColor() async {
    final color = await _showColorPicker(_backgroundColor);
    if (color != null) {
      setState(() {
        _backgroundColor = color;
      });
    }
  }

  Future<Color?> _showColorPicker(Color currentColor) async {
    Color picked = currentColor;
    return showDialog<Color>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Select Color'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: picked,
                onColorChanged: (color) {
                  setDialogState(() {
                    picked = color;
                  });
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, picked),
                child: Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }
  */

  /*
  void _selectLogo() async {
    setState(() {
      _hasLogo = true;
    });
  }

  void _removeLogo() {
    setState(() {
      _hasLogo = false;
      _logoBytes = null;
    });
  }
  */

  Future<void> _generateQrCode() async {
    if (_qrData.isEmpty) {
      showAppToast(
        'Please enter content for the QR code',
        type: ToastificationType.warning,
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final painter = QrPainter(
        data: _qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: _errorLevel,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: _foregroundColor,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: _foregroundColor,
        ),
        // Fills light modules + finder inner areas for exported PNG (package deprecates in favor of wrapping widgets).
        // ignore: deprecated_member_use
        emptyColor: _backgroundColor,
      );

      final picData = await painter.toImageData(_qrSize);
      if (!mounted) return;
      setState(() {
        _generatedQrBytes = picData!.buffer.asUint8List();
        _isGenerating = false;
      });

      if (!mounted) return;
      showAppToast(
        'QR Code generated successfully!',
        type: ToastificationType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
      showAppToast(
        'Error generating QR code: $e',
        type: ToastificationType.error,
      );
    }
  }

  Future<void> _saveQrCode() async {
    if (_generatedQrBytes == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(_generatedQrBytes!);

      if (!mounted) return;
      showAppToast(
        'QR Code saved to: $filePath',
        type: ToastificationType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        'Error saving QR code: $e',
        type: ToastificationType.error,
      );
    }
  }

  Future<void> _shareQrCode() async {
    if (_generatedQrBytes == null) return;

    try {
      // In a real implementation, you would use share_plus package
      // For now, we'll show a message
      showAppToast(
        'Share functionality would be implemented here',
        type: ToastificationType.info,
      );
    } catch (e) {
      showAppToast(
        'Error sharing QR code: $e',
        type: ToastificationType.error,
      );
    }
  }

  void _resetGenerator() {
    setState(() {
      _contentController.text = 'https://www.example.com';
      _qrData = 'https://www.example.com';
      _qrSize = 200.0;
      // _sizeController.text = _qrSize.toString();
      _errorLevel = QrErrorCorrectLevel.M;
      _hasLogo = false;
      _logoBytes = null;
      _generatedQrBytes = null;
      _isGenerating = false;
      // _selectedType = QrType.url;
      // _mainTab = 0;
      _applyTemplateColors(0);
    });
  }

  /*
  String _getTypeDisplayName(QrType type) {
    switch (type) {
      case QrType.url:
        return 'URL';
      case QrType.text:
        return 'Text';
      case QrType.email:
        return 'Email';
      case QrType.phone:
        return 'Phone';
      case QrType.wifi:
        return 'WiFi';
      case QrType.sms:
        return 'SMS';
      case QrType.vcard:
        return 'vCard';
    }
  }
  */
}

// Kept for commented QR type / customization code above.
// ignore: constant_identifier_names
enum QrType { url, text, email, phone, wifi, sms, vcard }

/*
// Simple color picker widget (used by commented _showColorPicker).
class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final Function(Color) onColorChanged;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.pickerColor;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 200,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _colors.length,
        itemBuilder: (context, index) {
          final color = _colors[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedColor = color;
              });
              widget.onColorChanged(color);
            },
            child: Container(
              decoration: BoxDecoration(
                color: color,
                border: Border.all(
                  color: selectedColor == color ? Colors.black : Colors.grey,
                  width: selectedColor == color ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }

  static const List<Color> _colors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.cyan,
    Colors.amber,
    Colors.indigo,
    Colors.brown,
    Colors.grey,
    Colors.lime,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.blueGrey,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.yellowAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
    Colors.cyanAccent,
    Colors.amberAccent,
    Colors.indigoAccent,
  ];
}
*/
