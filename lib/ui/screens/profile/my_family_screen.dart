import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';

class MyFamilyScreen extends StatefulWidget {
  const MyFamilyScreen({super.key});

  @override
  State<MyFamilyScreen> createState() => _MyFamilyScreenState();
}

class _MyFamilyScreenState extends State<MyFamilyScreen> {
  final List<Map<String, String>> familyMembers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Family',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage your family members',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // ✅ List or Empty state
          Expanded(
            child: familyMembers.isEmpty
                ? const Center(
                    child: Text(
                      'No family member\nor cook found',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: familyMembers.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = familyMembers[index];
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        title: Row(
                          children: [
                            Text(
                              member['phone']!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEEE0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Invited',
                                style: TextStyle(
                                  color: Color(0xFFFF7043),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(member['role']!),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
  _showRemoveConfirmation(
    memberPhone: member['phone']!,
    memberRole: member['role']!,
    index: index,
  );
},

                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ✅ Bottom Button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7043),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => _showAddFamilyBottomSheet(),
            child: const Text(
              'Add Family Member',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ADD FAMILY MEMBER BOTTOM SHEET
  void _showAddFamilyBottomSheet() {
    final phoneController = TextEditingController();
    String role = 'Member';
    String countryCode = '+91';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Family Member',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the details below to invite a new family member\nto join and collaborate on recipe generation',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  const Text('Mobile number',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),

                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CountryCodePicker(
                          initialSelection: 'IN',
                          onChanged: (c) =>
                              setSheetState(() => countryCode = c.dialCode!),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter mobile number',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text('Select a Role',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _role('Member', role == 'Member',
                          () => setSheetState(() => role = 'Member')),
                      const SizedBox(width: 10),
                      _role('Cook', role == 'Cook',
                          () => setSheetState(() => role = 'Cook')),
                    ],
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7043),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          familyMembers.add({
                            'phone':
                                '$countryCode${phoneController.text.trim()}',
                            'role': role,
                          });
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Send Invite',
                          style:
                              TextStyle(color: Colors.black, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRemoveConfirmation({
  required String memberPhone,
  required String memberRole,
  required int index,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Title
            const Text(
              'Remove Family Member',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Description
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                children: [
                  const TextSpan(text: 'Are you sure you want to remove '),
                  TextSpan(
                    text: memberPhone.replaceAll('+', ''),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const TextSpan(text: ' your family '),
                  TextSpan(
                    text: memberRole,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const TextSpan(
                    text:
                        '? he will no longer have access to recipe generation, cooking, and pantry management tasks.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Warning
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 18),
                SizedBox(width: 6),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ✅ Don't Remove Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF7043), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // ✅ Just close
                },
                child: const Text(
                  "Don't Remove",
                  style: TextStyle(
                    color: Color(0xFFFF7043),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Remove Member Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7043),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    familyMembers.removeAt(index); // ✅ DELETE
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'Remove Member',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}


  Widget _role(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF1EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: const Color(0xFFFF7043), width: 1.5)
                : Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color:
                    selected ? const Color(0xFFFF7043) : Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
