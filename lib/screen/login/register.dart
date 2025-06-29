import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/constants/app_gap.dart';
import 'package:suriota_mobile_gateway/core/constants/app_image_assets.dart';
import 'package:suriota_mobile_gateway/core/utils/extensions.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';
import 'package:suriota_mobile_gateway/screen/login/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
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
                "Let's Get Started!",
                style: context.h2,
              ),
              AppSpacing.xs,
              Text(
                'Create an account',
                style: context.h6,
              ),
              AppSpacing.lg,
              const CustomTextFormField(
                labelTxt: 'Full Name',
                hintTxt: 'Enter your full name',
                prefixIcon: Icon(
                  Icons.account_circle,
                  size: 20,
                  color: AppColor.primaryColor,
                ),
              ),
              AppSpacing.md,
              const CustomTextFormField(
                  labelTxt: 'Email',
                  hintTxt: 'Enter your email',
                  prefixIcon: Icon(
                    Icons.email,
                    size: 20,
                    color: AppColor.primaryColor,
                  )),
              AppSpacing.md,
              const CustomTextFormField(
                  labelTxt: 'Phone Number',
                  hintTxt: 'Enter your phone number',
                  prefixIcon: Icon(
                    Icons.phone_android_rounded,
                    size: 20,
                    color: AppColor.primaryColor,
                  )),
              AppSpacing.md,
              const CustomTextFormField(
                  labelTxt: 'Create Password',
                  hintTxt: 'Enter your password',
                  prefixIcon: Icon(
                    Icons.key,
                    size: 20,
                    color: AppColor.primaryColor,
                  )),
              AppSpacing.md,
              const CustomTextFormField(
                  labelTxt: 'Confirm Password',
                  hintTxt: 'Confirm your password',
                  prefixIcon: Icon(
                    Icons.lock,
                    size: 20,
                    color: AppColor.primaryColor,
                  )),
              AppSpacing.lg,
              Button(
                width: MediaQuery.of(context).size.width,
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                text: 'Sign Up with Email',
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
                onPressed: () {},
                imagePath: ImageAsset.iconGoogle,
                text: 'Sign Up with Google',
              ),
              AppSpacing.lg,
              InkWell(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have account? ",
                      style: context.bodySmall.copyWith(color: AppColor.grey),
                    ),
                    Text(
                      "Sign In Here",
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
    );
  }
}
