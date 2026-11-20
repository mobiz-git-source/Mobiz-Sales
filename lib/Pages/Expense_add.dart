// import 'dart:nativewrappers/_internal/vm/lib/core_patch.dart';

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/ExpensesPage.dart';
import 'package:mobizapp/Pages/homepage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import '../Components/commonwidgets.dart';
import '../Models/ExpenseDrop_model.dart';
import '../Models/LoginModelClass.dart';
import '../Utilities/rest_ds.dart';
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'homepage_Driver.dart';

class ExpenseAdd extends StatefulWidget {
  static const routeName = "/ExpenseAdd";

  const ExpenseAdd({super.key});

  @override
  State<ExpenseAdd> createState() => _ExpenseAddState();
}

class _ExpenseAddState extends State<ExpenseAdd> {
  // ---------------------------------------------------------------------
  // UI-only constants (design). Change these to retheme the screen.
  // ---------------------------------------------------------------------
  static const Color _uiPrimary = Color(0xFF4A3AC4);
  static const Color _uiPrimaryDark = Color(0xFF3B2DA3);
  static const Color _uiHeaderStart = Color(0xFF5B4BD0);
  static const Color _uiHeaderEnd = Color(0xFF4636B8);
  static const Color _uiSoft = Color(0xFFE9E5FC);
  static const Color _uiLabel = Color(0xFF3A22B8);
  static const Color _uiBorder = Color(0xFFDCD7F6);
  static const Color _uiText = Color(0xFF1E1B4B);
  static const Color _uiHint = Color(0xFF8E89B8);
  static const String _uiCurrency = 'AED';

  // Max digits allowed after the decimal point in Amount / Vat Amount.
  static const int _maxDecimalInput = 3;

  late Future<VisitReasonResponse> futureExpenseReason;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _vatAmountController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  List<File> _attachedImages = [];
  Expense? selectedexpense;
  String? _amount;
  String? _vatAmount;
  String? _totalAmount;
  DateTime? _selectedDate = DateTime.now();
  TextEditingController remark = TextEditingController();
  @override
  void initState() {
    super.initState();
    futureExpenseReason = fetchExpenses();
    _amountController.addListener(_calculateTotalAmount);
    _vatAmountController.addListener(_calculateTotalAmount);
    _dateController.text = DateHelper.displayFromDateTime(_selectedDate!);
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateTotalAmount);
    _vatAmountController.removeListener(_calculateTotalAmount);
    _amountController.dispose();
    _vatAmountController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // UI helpers (design only)
  // ---------------------------------------------------------------------

  InputDecoration _inputDecoration({
    String? hint,
    bool showCurrency = false,
    bool filled = false,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );

    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(color: _uiHint, fontWeight: FontWeight.w400),
      filled: filled,
      fillColor: filled ? const Color(0xFFE6E4F2) : null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: border(const Color(0xFFB9B1EA)),
      focusedBorder: border(_uiPrimary, 1.5),
      errorBorder: border(Colors.red.shade400),
      focusedErrorBorder: border(Colors.red.shade400, 1.5),
      border: border(const Color(0xFFB9B1EA)),
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: showCurrency
          ? Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _uiSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  _uiCurrency,
                  style: TextStyle(
                    color: Color(0xFF3F3A66),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // Allows only digits and one '.', with at most _maxDecimalInput digits
  // after the point (e.g. 58.000, never 58.0000000).
  List<TextInputFormatter> get _amountFormatters => [
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d*\.?\d{0,' + _maxDecimalInput.toString() + r'}'),
        ),
      ];

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _uiPrimaryDark,
            onPrimary: Colors.white,
            onSurface: _uiText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateHelper.displayFromDateTime(picked);
      });
    }
  }

  Widget _fieldCard({
    required IconData icon,
    required String label,
    bool required = false,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _uiBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: _uiSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _uiPrimaryDark, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      color: _uiLabel,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    children: required
                        ? const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fileSizeLabel(File file) {
    try {
      final kb = file.lengthSync() / 1024;
      if (kb >= 1024) return '${(kb / 1024).toStringAsFixed(1)} MB';
      return '${kb.toStringAsFixed(0)} KB';
    } catch (_) {
      return '';
    }
  }

  Widget _attachmentCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _uiBorder),
      ),
      child: Column(
        children: [
          Container(
            color: _uiSoft.withOpacity(0.7),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: _uiPrimaryDark, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Attachment',
                    style: TextStyle(
                      color: _uiLabel,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D2FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_attachedImages.length} File(s)',
                    style: const TextStyle(
                      color: _uiLabel,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._attachedImages.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                border: index == 0
                    ? null
                    : const Border(top: BorderSide(color: _uiBorder)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      file,
                      width: 52,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 52,
                        height: 60,
                        color: _uiSoft,
                        child: const Icon(Icons.broken_image,
                            color: _uiHint, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.path.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _uiText,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fileSizeLabel(file),
                          style:
                              const TextStyle(color: _uiHint, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      setState(() {
                        _attachedImages.removeAt(index);
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: _uiSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: _uiPrimaryDark, size: 22),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _bottomButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _uiPrimaryDark,
                    side: const BorderSide(color: _uiPrimary, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: const Color(0xFFF7F5FF),
                  ),
                  onPressed: _attachDocuments,
                  icon: const Icon(Icons.attach_file, size: 22),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Attach Documents',
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _uiPrimaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      postData();
                    }
                  },
                  icon: const Icon(Icons.send, size: 22),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Send for Approval',
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Clears the form fields only (UI action for the trash icon in the header).
  void _clearForm() {
    _amountController.clear();
    _vatAmountController.clear();
    _totalAmountController.clear();
    remark.clear();
    setState(() {
      selectedexpense = null;
      _attachedImages.clear();
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Keeps the layout stable on phones with very large / small system font.
    return MediaQuery(
      data: mq.copyWith(
        textScaler: mq.textScaler
            .clamp(minScaleFactor: 0.85, maxScaleFactor: 1.15),
      ),
      child: Scaffold(
      backgroundColor: const Color(0xFFF8F7FD),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: _uiPrimary,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_uiHeaderStart, _uiHeaderEnd],
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Expense',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _clearForm,
            icon: const Icon(Icons.delete, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: FutureBuilder(
        future: futureExpenseReason,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Shimmer.fromColors(
              baseColor: AppConfig.buttonDeactiveColor.withOpacity(0.1),
              highlightColor: AppConfig.backButtonColor,
              child: Center(
                child: Column(
                  children: List.generate(
                    6,
                    (index) => CommonWidgets.loadingContainers(
                      height: SizeConfig.blockSizeVertical * 10,
                      width: SizeConfig.blockSizeHorizontal * 90,
                    ),
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'),
            );
          } else if (snapshot.hasData) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date bar
                          GestureDetector(
                            onTap: _pickDate,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                            height: 64,
                            margin: const EdgeInsets.only(bottom: 14),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: _uiSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month,
                                    color: _uiPrimaryDark, size: 30),
                                Expanded(
                                  child: Text(
                                    _selectedDate == null
                                        ? 'Select Date'
                                        : DateHelper.displayFromDateTime(
                                            _selectedDate!),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _uiText,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: _uiPrimaryDark, size: 28),
                              ],
                            ),
                            ),
                          ),

                          // Amount
                          _fieldCard(
                            icon: Icons.account_balance_wallet,
                            label: 'Amount',
                            required: true,
                            child: TextFormField(
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: _amountFormatters,
                              controller: _amountController,
                              style: const TextStyle(
                                  color: _uiText, fontSize: 18),
                              decoration:
                                  _inputDecoration(showCurrency: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an amount';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Vat Amount
                          _fieldCard(
                            icon: Icons.percent,
                            label: 'Vat Amount',
                            child: TextFormField(
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: _amountFormatters,
                              controller: _vatAmountController,
                              style: const TextStyle(
                                  color: _uiText, fontSize: 18),
                              decoration:
                                  _inputDecoration(showCurrency: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter vat amount';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Total Amount (read only)
                          _fieldCard(
                            icon: Icons.functions,
                            label: 'Total Amount',
                            child: TextFormField(
                              readOnly: true,
                              keyboardType: TextInputType.number,
                              controller: _totalAmountController,
                              style: const TextStyle(
                                  color: Color(0xFF55527A), fontSize: 18),
                              decoration: _inputDecoration(
                                  showCurrency: true, filled: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Total amount cannot be empty';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Category
                          _fieldCard(
                            icon: Icons.format_list_bulleted,
                            label: 'Category',
                            required: true,
                            child: DropdownButtonFormField<Expense>(
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: _uiPrimaryDark),
                              decoration: _inputDecoration(),
                              style: const TextStyle(
                                  color: _uiText, fontSize: 17),
                              hint: const Text(
                                'Select from list',
                                style: TextStyle(
                                  color: _uiHint,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              value: selectedexpense,
                              onChanged: (Expense? newValue) {
                                setState(() {
                                  selectedexpense = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select an expense';
                                }
                                return null;
                              },
                              items: snapshot.data!.data
                                  .map((Expense expense) {
                                return DropdownMenuItem<Expense>(
                                  value: expense,
                                  child: Text(
                                    expense.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          // Remarks
                          _fieldCard(
                            icon: Icons.chat,
                            label: 'Remarks',
                            child: TextFormField(
                              controller: remark,
                              maxLines: 3,
                              style: const TextStyle(
                                  color: _uiText, fontSize: 16),
                              decoration: _inputDecoration(
                                  hint: 'Enter Remarks here...'),
                            ),
                          ),

                          // Attachments
                          if (_attachedImages.isNotEmpty) _attachmentCard(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Hidden while the keyboard is open so the form never gets
                // squeezed (that squeeze caused the yellow/black overflow bar).
                if (MediaQuery.of(context).viewInsets.bottom == 0)
                  _bottomButtons(),
              ],
            );
          } else {
            return Center(child: Text('No Data Available'));
          }
        },
      ),
      ),
    );
  }

  void _attachDocuments() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Library'),
                onTap: () async {
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (pickedFile != null) {
                    final compressedImage =
                        await _compressImage(File(pickedFile.path));
                    setState(() {
                      _attachedImages.add(compressedImage);
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () async {
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (pickedFile != null) {
                    final compressedImage =
                        await _compressImage(File(pickedFile.path));
                    setState(() {
                      _attachedImages.add(compressedImage);
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<File> _compressImage(File file) async {
    final image = img.decodeImage(file.readAsBytesSync())!;
    final compressedImage = img.copyResize(image, width: 800);
    final compressedBytes =
        img.encodeJpg(compressedImage, quality: 75); // Compress the image

    final tempDir = await getTemporaryDirectory();
    final compressedFile =
        File('${tempDir.path}/compressed_${file.path.split('/').last}');
    await compressedFile.writeAsBytes(compressedBytes);

    print(
        'Compressed image size: ${compressedFile.lengthSync()} bytes'); // Debug statement

    // Check file size and further compress if necessary
    if (compressedFile.lengthSync() > 200 * 1024) {
      final furtherCompressedBytes =
          img.encodeJpg(compressedImage, quality: 65);
      await compressedFile.writeAsBytes(furtherCompressedBytes);
      print(
          'Further compressed image size: ${compressedFile.lengthSync()} bytes'); // Debug statement
    }

    return compressedFile;
  }

  void _calculateTotalAmount() {
    setState(() {
      String amountText = _amountController.text;
      String vatAmountText = _vatAmountController.text;

      if (amountText.isNotEmpty && vatAmountText.isNotEmpty) {
        double? amount = double.tryParse(amountText);
        double? vatAmount = double.tryParse(vatAmountText);

        if (amount != null && vatAmount != null) {
          double totalAmount = amount + vatAmount;
          _totalAmountController.text =
              totalAmount.toStringAsFixed(AppState().noOfDecimals ?? 2); // Format to 2 decimal places
        } else {
          _totalAmountController.clear();
        }
      } else {
        _totalAmountController.clear();
      }
    });
  }

  void postData() async {
    var url = Uri.parse('${RestDatasource().BASE_URL}/api/expense.store');
    var request = http.MultipartRequest('POST', url);

    request.fields['van_id'] = AppState().vanId.toString();
    request.fields['store_id'] = AppState().storeId.toString();
    request.fields['expense_id'] = selectedexpense!.id.toString();
    request.fields['description'] = remark.text;
    request.fields['amount'] = _amountController.text;
    request.fields['in_date'] = DateHelper.apiDate(_selectedDate!);
    request.fields['user_id'] = AppState().userId.toString();
    request.fields['vat_amount'] = _vatAmountController.text;
    request.fields['total_amount'] = _totalAmountController.text;

    for (var file in _attachedImages) {
      request.files.add(await http.MultipartFile.fromPath(
        'document_name[]', // API expects an array of files, adjust as per API documentation
        file.path,
      ));
    }

    // Send the request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    print("FIELDS:");
    request.fields.forEach((key, value) {
      print("$key : $value");
    });

    print("\nFILES:");
    for (var file in _attachedImages) {
      print("upload_document[] : ${file.path}");
    }
    print(response.body);
    print("response.body");
    if (response.statusCode == 200) {
      print(response.body);
      if (mounted) {
        CommonWidgets.showDialogueBox(
          context: context,
          title: "",
          msg: "Data Inserted Successfully",
        ).then((value) {
          if (AppState().rolId == 4) {
            Navigator.pushNamed(context, HomepageDriver.routeName);
          } else {
            Navigator.pushNamed(context, HomeScreen.routeName);
          }
        });
      }
      print('Request successful');
      print('Response: ${response.body}');
    }
    else {
      print('Request failed with status: ${response.statusCode} ${response.body}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to insert data. Please try again. ${response.statusCode} ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String url =
      '${RestDatasource().BASE_URL}/api/get_expense_master?store_id=${AppState().storeId}';

  static Future<VisitReasonResponse> fetchExpenses() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return VisitReasonResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load data');
    }
  }
}