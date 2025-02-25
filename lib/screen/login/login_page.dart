import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';
import 'package:suriota_mobile_gateway/screen/home/home_screen.dart';
import 'package:suriota_mobile_gateway/screen/login/register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formField = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool passToggle = false;

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!value.contains('@')) {
      return 'Email yang anda masukkan tidak benar';
    }
    if (value != 'rudisoru@dah.com') {
      return 'Email tidak terdaftar';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value != '123456') {
      return 'Password anda salah';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: Form(
            key: _formField,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.md,
                SizedBox(
                  width: screenWidth * (screenWidth <= 600 ? 0.4 : 0.2),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      ImageAsset.logoSuriota,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                AppSpacing.sm,
                Text(
                  'Welcome to Suriota Mobile Gateway!',
                  style: context.h2,
                ),
                AppSpacing.xs,
                Text(
                  'Sign in to continue',
                  style: context.h6,
                ),
                AppSpacing.lg,
                CustomTextFormField(
                  keyboardType: TextInputType.emailAddress,
                  onTap: () {},
                  controller: emailController,
                  validator: validateEmail,
                  labelTxt: 'Email',
                  hintTxt: 'Enter your email',
                  prefixIcon: const Icon(
                    Icons.email,
                    size: 20,
                    color: AppColor.primaryColor,
                  ),
                ),
                AppSpacing.md,
                CustomTextFormField(
                  obscureText: !passToggle,
                  validator: validatePassword,
                  controller: passwordController,
                  labelTxt: 'Password',
                  hintTxt: 'Enter your password',
                  prefixIcon: const Icon(
                    Icons.key,
                    size: 20,
                    color: AppColor.primaryColor,
                  ),
                  suffixIcon: InkWell(
                    onTap: () {
                      setState(() {
                        passToggle = !passToggle;
                      });
                    },
                    child: Icon(
                      size: 20,
                      passToggle ? Icons.visibility : Icons.visibility_off,
                      color: AppColor.primaryColor,
                    ),
                  ),
                ),
                AppSpacing.lg,
                Button(
                  width: MediaQuery.of(context).size.width,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  text: 'Sign In',
                ),
                AppSpacing.sm,
                Center(
                  child: Text(
                    'OR',
                    style: context.bodySmall.copyWith(color: AppColor.grey),
                  ),
                ),
                AppSpacing.sm,
                ButtonOutline(
                  width: MediaQuery.of(context).size.width,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  imagePath: ImageAsset.iconGoogle,
                  text: 'Sign In with Google',
                ),
                AppSpacing.lg,
                InkWell(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterPage()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have any account? ",
                        style: context.bodySmall.copyWith(color: AppColor.grey),
                      ),
                      Text(
                        "Register Here",
                        style: context.bodySmall.copyWith(
                            color: AppColor.primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                AppSpacing.md,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
