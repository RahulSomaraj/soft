import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:softmind_admin/features/users/bloc/user_bloc.dart';
import 'package:softmind_admin/models/user_model.dart';
import 'package:go_router/go_router.dart';

class AddUser extends StatefulWidget {
  const AddUser({super.key});

  @override
  State<AddUser> createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  final GlobalKey<FormState> _userFormKey = GlobalKey<FormState>();

  String _name = '';
  String _email = '';
  String _phone = '';
  String _userType = "Normal User";

  /// Short form to full form mapping
  final Map<String, String> _userTypeMap = {
    'SA': "Super Admin",
    'AD': "Admin",
    'NU': "Normal User",
    'SR': "Showroom",
  };

  /// Convert full form to short code for API request
  String _getShortForm(String fullType) {
    return _userTypeMap.entries
        .firstWhere(
          (entry) => entry.value == fullType,
          orElse: () => const MapEntry('NU', "Normal User"),
        )
        .key;
  }

  void _addUser() {
    if (_userFormKey.currentState!.validate()) {
      _userFormKey.currentState!.save();

      final newUser = UserModel(
        id: '', // ID will be generated by backend
        name: _name,
        email: _email,
        phoneNumber: _phone,
        type: _getShortForm(_userType),
      );

      context.read<UserBloc>().add(UserEvent.addUser(userData: newUser));

      Future.delayed(const Duration(milliseconds: 500), () {
        _showSuccessPopup(context, "User has been added successfully.");
      });
    }
  }

  void _showSuccessPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 30),
              _buildUserForm(state),
            ],
          ),
        );
      },
    );
  }

  /// ✅ Header Section with Back Button
  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () {
                context.pop();
                context.read<UserBloc>().add(FetchAllUsers());
              },
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Add User",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Center _buildUserForm(UserState state) {
    return Center(
      child: SizedBox(
        width: 500,
        child: Card(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _userFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormField("Name", "", (value) => _name = value!),
                  const SizedBox(height: 15),
                  _buildFormField("Email", "", (value) => _email = value!,
                      isEmail: true),
                  const SizedBox(height: 15),
                  _buildFormField(
                      "Phone Number", "", (value) => _phone = value!,
                      isPhone: true),
                  const SizedBox(height: 15),
                  _buildDropdownField("User Type", _userType),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: state is UserLoading ? null : _addUser,
                      child: state is UserLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Add User",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
      String label, String initialValue, Function(String?) onSaved,
      {bool isEmail = false, bool isPhone = false}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: isEmail
          ? TextInputType.emailAddress
          : (isPhone ? TextInputType.phone : TextInputType.text),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$label is required";
        }
        if (isEmail &&
            !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                .hasMatch(value)) {
          return "Enter a valid email address";
        }
        if (isPhone && !RegExp(r"^[0-9]{10,}$").hasMatch(value)) {
          return "Enter a valid phone number (10+ digits)";
        }
        return null;
      },
      onSaved: onSaved,
    );
  }

  Widget _buildDropdownField(String label, String selectedValue) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: _userTypeMap.values
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: (value) => setState(() => _userType = value!),
    );
  }
}
