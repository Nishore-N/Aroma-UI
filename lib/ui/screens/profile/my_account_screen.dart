import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  String fullName = 'Guest9994080963';
  String email = '';
  String gender = '';
  String dob = '';
  String mobile = '+919994080963';

  // 🔥 COMMON BOTTOM SHEET WRAPPER (same spacing everywhere)
  void _openBottomSheet({required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFB0B0B0)),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              'My Account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),

          _item(
            title: fullName,
            subtitle: 'Full Name',
            onTap: _editName,
          ),

          _item(
            title: mobile,
            subtitle: 'Mobile number',
            onTap: _editMobile,
          ),

          _item(
            title: email.isEmpty ? 'Add your e-mail id' : email,
            subtitle: 'E-mail Id',
            isAdd: email.isEmpty,
            onTap: _editEmail,
          ),

          _item(
            title: gender.isEmpty ? 'Select your gender' : gender,
            subtitle: 'Gender',
            isAdd: gender.isEmpty,
            onTap: _editGender,
          ),

          _item(
            title: dob.isEmpty ? 'Add your date of birth' : dob,
            subtitle: 'Date of birth',
            isAdd: dob.isEmpty,
            onTap: _editDOB,
          ),
        ],
      ),
    );
  }

  // ================== FULL NAME ==================
  void _editName() {
    final controller = TextEditingController(text: fullName);

    _openBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account Name',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Full Name', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 28),
          _button(
            text: 'Update',
            onTap: () {
              setState(() => fullName = controller.text.trim());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ================== MOBILE ==================
  void _editMobile() {
  final TextEditingController controller = TextEditingController();
  String countryCode = '+91';

  _openBottomSheet(
    child: StatefulBuilder(
      builder: (context, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mobile number',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text(
              'Mobile number',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 8),

            // ✅ Country picker + number field
            Row(
              children: [
                // Country code picker
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CountryCodePicker(
                    onChanged: (code) {
                      setSheetState(() {
                        countryCode = code.dialCode!;
                      });
                    },
                    initialSelection: 'IN',
                    showCountryOnly: false,
                    showOnlyCountryWhenClosed: false,
                    alignLeft: false,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(width: 12),

                // Phone number field
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter mobile number',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            _button(
              text: 'Get OTP',
              onTap: () {
                String fullNumber = '$countryCode${controller.text.trim()}';
                debugPrint('Mobile: $fullNumber');
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    ),
  );
}


  // ================== EMAIL ==================
  void _editEmail() {
    final controller = TextEditingController(text: email);

    _openBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('E-mail Id',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('your e-mail id', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 28),
          _button(
            text: 'Update',
            onTap: () {
              setState(() => email = controller.text.trim());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ================== GENDER ==================
  void _editGender() {
    _openBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gender',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _genderTile('Male'),
          _divider(),
          _genderTile('Female'),
          _divider(),
          _genderTile('Prefer not to say'),
          const SizedBox(height: 24),
          _button(
            text: 'Update',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _genderTile(String value) {
    return ListTile(
      title: Text(value),
      trailing: gender == value
          ? const Icon(Icons.check_circle, color: Color(0xFFFF7043))
          : null,
      onTap: () => setState(() => gender = value),
    );
  }

  // ================== DOB ==================
  void _editDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        dob = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  // ================== UI HELPERS ==================
  InputDecoration _inputDecoration({String? prefix}) {
    return InputDecoration(
      prefixText: prefix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _button({required String text, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7043),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1);
  }

  Widget _item({
    required String title,
    required String subtitle,
    bool isAdd = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(title,
          style: TextStyle(
              color: isAdd ? Colors.red : Colors.black, fontSize: 16)),
      subtitle:
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: isAdd
          ? const Icon(Icons.add_circle_outline, color: Colors.red)
          : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
