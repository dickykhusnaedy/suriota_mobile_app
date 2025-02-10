import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';

import '../../constant/app_color.dart';
import '../../constant/font_setup.dart';
import '../../constant/image_asset.dart';
import '../../global/widgets/custom_button.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 38,
                child: Image.asset(ImageAsset.logoSuriota),
              ),
              const SizedBox(
                height: 32,
              ),
              Text(
                "Let's Get Started!",
                style: FontFamily.titleLarge,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                'Create an account',
                style: FontFamily.normal
                    .copyWith(fontSize: 18, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 16),
              const CustomTextFormField(
                labelTxt: 'Full Name',
                hintTxt: 'Enter your full name',
                prefixIcon: Icon(
                  Icons.account_circle,
                  color: AppColor.primaryColor,
                ),
              ),
              const CustomTextFormField(
                  labelTxt: 'Email',
                  hintTxt: 'Enter your email',
                  prefixIcon: Icon(
                    Icons.email,
                    color: AppColor.primaryColor,
                  )),
              const CustomTextFormField(
                  labelTxt: 'Phone Number',
                  hintTxt: 'Enter your phone number',
                  prefixIcon: Icon(
                    Icons.phone_android_rounded,
                    color: AppColor.primaryColor,
                  )),
              const CustomTextFormField(
                  labelTxt: 'Create Password',
                  hintTxt: 'Enter your password',
                  prefixIcon: Icon(
                    Icons.key,
                    color: AppColor.primaryColor,
                  )),
              const CustomTextFormField(
                  labelTxt: 'Confirm Password',
                  hintTxt: 'Confirm your password',
                  prefixIcon: Icon(
                    Icons.lock,
                    color: AppColor.primaryColor,
                  )),
              const SizedBox(
                height: 24,
              ),
              CustomButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                titleButton: 'REGISTER',
              ),
              const SizedBox(
                height: 16,
              ),
              Center(
                child: Text(
                  'OR',
                  style:
                      FontFamily.headlineMedium.copyWith(color: AppColor.grey),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
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
                        'REGISTER WITH GOOGLE',
                        style: FontFamily.headlineMedium
                            .copyWith(color: AppColor.primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: FontFamily.normal.copyWith(
                        fontSize: 16,
                        color: AppColor.grey,
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      "Sign In Here",
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
    );
  }
}
