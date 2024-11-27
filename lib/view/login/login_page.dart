import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_dialog.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';
import 'package:suriota_mobile_gateway/view/home/home_page.dart';
import 'package:suriota_mobile_gateway/view/login/register.dart';
import '../../global/widgets/custom_button.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formField,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 38,
                  child: Image.asset(ImageAsset.logoSuriota),
                ),
                AppGap.gap32,
                Text(
                  'Welcome to Suriota Mobile Gateway!',
                  style: FontFamily.titleLarge,
                ),
                AppGap.gap8,
                Text(
                  'Sign in to continue',
                  style: FontFamily.normal
                      .copyWith(fontSize: 18, fontWeight: FontWeight.normal),
                ),
                AppGap.gap32,
                CustomTextFormField(
                  keyboardType: TextInputType.emailAddress,
                  onTap: () {},
                  controller: emailController,
                  validator: validateEmail,
                  labelTxt: 'Email',
                  hintTxt: 'Enter your email',
                  prefixIcon: const Icon(
                    Icons.email,
                    color: AppColor.primaryColor,
                  ),
                ),
                CustomTextFormField(
                  obscureText: !passToggle,
                  validator: validatePassword,
                  controller: passwordController,
                  labelTxt: 'Password',
                  hintTxt: 'Enter your password',
                  prefixIcon: const Icon(
                    Icons.key,
                    color: AppColor.primaryColor,
                  ),
                  suffixIcon: InkWell(
                    onTap: () {
                      setState(() {
                        passToggle = !passToggle;
                      });
                    },
                    child: Icon(
                      passToggle ? Icons.visibility : Icons.visibility_off,
                      color: AppColor.primaryColor,
                    ),
                  ),
                ),
                AppGap.gap24,
                CustomButton(
                  onPressed: () {
                    if (_formField.currentState!.validate()) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomePage(
                                // title: 'Main Menu',
                                )),
                        (Route<dynamic> route) => false,
                      );
                    } else {
                      showDialog(
                          context: context,
                          builder: (context) => const CustomDialog());
                    }
                  },
                  titleButton: 'SIGN IN',
                ),
                AppGap.gap16,
                Center(
                  child: Text(
                    'OR',
                    style: FontFamily.headlineMedium
                        .copyWith(color: AppColor.grey),
                  ),
                ),
                AppGap.gap16,
                SizedBox(
                  height: 57,
                  width: MediaQuery.of(context).size.width * 1,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.white),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            side: BorderSide(
                              color: AppColor.primaryColor,
                              width: 2,
                            ))),
                        fixedSize: WidgetStatePropertyAll(Size.infinite)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon(Icons.g_mobiledata),
                        SizedBox(
                            height: 25,
                            child: Image.asset(
                              ImageAsset.iconGoogle,
                            )),
                        const SizedBox(width: 30),
                        Text(
                          'SIGN IN WITH GOOGLE',
                          style: FontFamily.headlineMedium
                              .copyWith(color: AppColor.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
                AppGap.gap24,
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
                        style: FontFamily.headlineMedium.copyWith(
                            color: AppColor.grey, fontWeight: FontWeight.w300),
                      ),
                      Text(
                        "Register Here",
                        style: FontFamily.headlineMedium.copyWith(
                          color: AppColor.primaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
