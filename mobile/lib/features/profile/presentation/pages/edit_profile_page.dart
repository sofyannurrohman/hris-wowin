import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_event.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_state.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:hris_app/core/utils/constants.dart';
import 'package:hris_app/core/utils/snackbar_utils.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressKtpController = TextEditingController();
  final _addressResidentialController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _identityNumberController = TextEditingController();
  final _npwpNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();

  String? _gender;
  String? _maritalStatus;

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Text('Apakah Anda yakin ingin keluar dari akun ini?', style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(LogoutRequested());
              },
              child: Text('Logout', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfileRequested());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _birthPlaceController.dispose();
    _phoneController.dispose();
    _addressKtpController.dispose();
    _addressResidentialController.dispose();
    _emergencyContactController.dispose();
    _identityNumberController.dispose();
    _npwpNumberController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF111827);
    const subtitleColor = Color(0xFF6B7280);
    const primaryBlue = Color(0xFF1B60F1);
    const borderColor = Color(0xFFE5E7EB);
    const disabledBgColor = Color(0xFFF3F4F6);

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          final profile = state.profile;
          _firstNameController.text = profile['FirstName'] ?? '';
          _lastNameController.text = profile['LastName'] ?? '';
          
          // Handle BirthDate (string format likely)
          if (profile['BirthDate'] != null) {
            final bd = profile['BirthDate'].toString();
            _birthDateController.text = bd.length >= 10 ? bd.substring(0, 10) : bd;
          }
          
          _birthPlaceController.text = profile['BirthPlace'] ?? '';
          _gender = profile['Gender'];
          _maritalStatus = profile['MaritalStatus'];
          _phoneController.text = profile['PhoneNumber'] ?? '';
          _addressKtpController.text = profile['AddressKTP'] ?? '';
          _addressResidentialController.text = profile['AddressResidential'] ?? '';
          _emergencyContactController.text = profile['EmergencyContact'] ?? '';
          _identityNumberController.text = profile['IdentityNumber'] ?? '';
          _npwpNumberController.text = profile['NpwpNumber'] ?? '';
          _bankNameController.text = profile['BankName'] ?? '';
          _bankAccountNumberController.text = profile['BankAccountNumber'] ?? '';
          _accountHolderNameController.text = profile['AccountHolderName'] ?? '';
        }
        if (state is ProfileUpdateSuccess) {
          SnackBarUtils.showSuccess(context, 'Profile Updated Successfully');
          // Optionally reload profile
          context.read<ProfileBloc>().add(LoadProfileRequested());
        }
        if (state is ProfileFailure) {
          SnackBarUtils.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Edit Profile',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () => _showLogoutConfirmation(context),
            ),
          ],
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
        ),
        body: SafeArea(
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading && state is! ProfileLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final profile = (state is ProfileLoaded) ? state.profile : {};
              final nik = profile['EmployeeIDNumber'] ?? '-';
              final department = profile['Department']?['Name'] ?? '-';

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24)
                    .copyWith(bottom: 120), // Padding for the bottom docked button
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFFFFDCA8),
                                backgroundImage: (profile['FaceReferenceURL'] != null && profile['FaceReferenceURL'].toString().isNotEmpty)
                                    ? NetworkImage(profile['FaceReferenceURL'].toString().startsWith('http') 
                                        ? profile['FaceReferenceURL'] 
                                        : '${Uri.parse(AppConstants.baseUrl).origin}${profile['FaceReferenceURL'].toString().startsWith('/') ? profile['FaceReferenceURL'] : '/${profile['FaceReferenceURL']}'}')
                                    : NetworkImage('https://ui-avatars.com/api/?name=${profile['FirstName'] ?? 'User'}&background=FFDCA8&color=D97706&size=200'),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ubah Foto Profil',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryBlue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'EMPLOYMENT DETAILS',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: subtitleColor,
                          letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('NIKaryawan'),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(nik, Icons.lock_outline, disabledBgColor, borderColor),
                    const SizedBox(height: 20),

                    _buildLabel('Departemen'),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(department, Icons.lock_outline, disabledBgColor, borderColor),
                    const SizedBox(height: 20),

                    if (profile['Salary'] != null) ...[
                      _buildLabel('Gaji Pokok'),
                      const SizedBox(height: 8),
                      _buildReadOnlyField(
                        'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(profile['Salary'])}',
                        Icons.lock_outline,
                        disabledBgColor,
                        borderColor,
                      ),
                      const SizedBox(height: 20),
                    ],
                    const SizedBox(height: 12),

                    Text(
                      'PERSONAL INFORMATION',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: subtitleColor,
                          letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Nama Depan'),
                              const SizedBox(height: 8),
                              _buildEditableField(_firstNameController, Icons.person_outline, borderColor, primaryBlue),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Nama Belakang'),
                              const SizedBox(height: 8),
                              _buildEditableField(_lastNameController, Icons.person_outline, borderColor, primaryBlue),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Tempat Lahir'),
                              const SizedBox(height: 8),
                              _buildEditableField(_birthPlaceController, Icons.location_city_outlined, borderColor, primaryBlue),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Tanggal Lahir (YYYY-MM-DD)'),
                              const SizedBox(height: 8),
                              _buildEditableField(_birthDateController, Icons.calendar_month_outlined, borderColor, primaryBlue),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Jenis Kelamin'),
                              const SizedBox(height: 8),
                              _buildDropdownField(_gender, ['Laki-laki', 'Perempuan'], Icons.wc, borderColor, primaryBlue, (v) => setState(() => _gender = v)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Status Pernikahan'),
                              const SizedBox(height: 8),
                              _buildDropdownField(_maritalStatus, ['Lajang', 'Menikah', 'Cerai'], Icons.favorite_outline, borderColor, primaryBlue, (v) => setState(() => _maritalStatus = v)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Nomor Telepon'),
                    const SizedBox(height: 8),
                    _buildEditableField(_phoneController, Icons.phone_outlined, borderColor, primaryBlue),
                    const SizedBox(height: 32),

                    Text(
                      'IDENTIFICATION & TAX',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: subtitleColor,
                          letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Nomor KTP (NIK)'),
                    const SizedBox(height: 8),
                    _buildEditableField(_identityNumberController, Icons.badge_outlined, borderColor, primaryBlue),
                    const SizedBox(height: 20),

                    _buildLabel('Nomor NPWP'),
                    const SizedBox(height: 8),
                    _buildEditableField(_npwpNumberController, Icons.receipt_long_outlined, borderColor, primaryBlue),
                    const SizedBox(height: 32),

                    Text(
                      'ADDRESS INFORMATION',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: subtitleColor,
                          letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Alamat Sesuai KTP'),
                    const SizedBox(height: 8),
                    _buildEditableField(_addressKtpController, Icons.home_outlined, borderColor, primaryBlue, maxLines: 2),
                    const SizedBox(height: 20),

                    _buildLabel('Alamat Domisili'),
                    const SizedBox(height: 8),
                    _buildEditableField(_addressResidentialController, Icons.location_on_outlined, borderColor, primaryBlue, maxLines: 2),
                    const SizedBox(height: 20),

                    _buildLabel('Kontak Darurat'),
                    const SizedBox(height: 8),
                    _buildEditableField(_emergencyContactController, Icons.medical_services_outlined, borderColor, primaryBlue),
                    const SizedBox(height: 32),

                    Text(
                      'BANK INFORMATION',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: subtitleColor,
                          letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Nama Bank'),
                    const SizedBox(height: 8),
                    _buildEditableField(_bankNameController, Icons.account_balance_outlined, borderColor, primaryBlue),
                    const SizedBox(height: 20),

                    _buildLabel('Nomor Rekening'),
                    const SizedBox(height: 8),
                    _buildEditableField(_bankAccountNumberController, Icons.numbers, borderColor, primaryBlue),
                    const SizedBox(height: 20),

                    _buildEditableField(_accountHolderNameController, Icons.person_pin_outlined, borderColor, primaryBlue),
                    const SizedBox(height: 32),

                    Text(
                      'SECURITY SETTINGS',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: subtitleColor,
                          letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 16),

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        bool isSupported = false;
                        bool isEnabled = false;

                        if (state is Unauthenticated) {
                          isSupported = state.isBiometricSupported;
                          isEnabled = state.isBiometricEnabled;
                        }

                        // Re-check support if state doesn't have it (authenticated case)
                        // This is a simplification; in a real app we'd have a separate SettingsBloc
                        
                        return SwitchListTile(
                          title: Text('Login dengan Biometrik', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                          subtitle: Text('Gunakan Sidik Jari untuk masuk aplikasi', style: GoogleFonts.inter(fontSize: 13)),
                          value: isEnabled,
                          activeColor: primaryBlue,
                          onChanged: isSupported ? (val) {
                            context.read<AuthBloc>().add(ToggleBiometricRequested(val));
                          } : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: borderColor),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                return ElevatedButton.icon(
                  onPressed: state is ProfileUpdating
                      ? null
                      : () {
                          context.read<ProfileBloc>().add(
                                UpdateProfileRequested(
                                  firstName: _firstNameController.text,
                                  lastName: _lastNameController.text,
                                  birthDate: _birthDateController.text,
                                  birthPlace: _birthPlaceController.text,
                                  gender: _gender ?? '',
                                  maritalStatus: _maritalStatus ?? '',
                                  phoneNumber: _phoneController.text,
                                  addressKtp: _addressKtpController.text,
                                  addressResidential: _addressResidentialController.text,
                                  emergencyContact: _emergencyContactController.text,
                                  identityNumber: _identityNumberController.text,
                                  npwpNumber: _npwpNumberController.text,
                                  bankName: _bankNameController.text,
                                  bankAccountNumber: _bankAccountNumberController.text,
                                  accountHolderName: _accountHolderNameController.text,
                                ),
                              );
                        },
                  icon: state is ProfileUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                  label: Text(
                    state is ProfileUpdating ? 'Saving...' : 'Save Changes',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827)),
    );
  }

  Widget _buildReadOnlyField(String initialValue, IconData icon, Color bg, Color border) {
    return TextFormField(
      initialValue: initialValue,
      readOnly: true,
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF6B7280)),
      decoration: InputDecoration(
        filled: true,
        fillColor: bg,
        suffixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none), // Match mockup which has subtle border or none
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildEditableField(TextEditingController controller, IconData icon, Color border, Color focusBorder, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF111827)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        suffixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: focusBorder, width: 1.5)),
      ),
    );
  }

  Widget _buildDropdownField(String? value, List<String> items, IconData icon, Color border, Color focusBorder, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: (value != null && items.contains(value)) ? value : null,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF111827)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        suffixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: focusBorder, width: 1.5)),
      ),
    );
  }
}
