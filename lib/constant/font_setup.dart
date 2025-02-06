import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';

class FontSizeTheme {
  static double h1 = 32.sp;
  static double h2 = 24.sp;
  static double h3 = 20.sp;
  static double h4 = 18.sp;
  static double h5 = 16.sp;
  static double h6 = 14.sp;
  static double body = 14.sp;
  static double bodySmall = 12.sp;
}

class FontWeightTheme {
  static FontWeight light = FontWeight.w300;
  static FontWeight regular = FontWeight.w400;
  static FontWeight medium = FontWeight.w500;
  static FontWeight semiBold = FontWeight.w600;
  static FontWeight bold = FontWeight.w700;
  static FontWeight extraBold = FontWeight.w900;
}

class FontFamily {
  FontFamily._();

  static const Color color = AppColor.primaryColor;

  static TextStyle titleLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: color,
  );
  static TextStyle titleMedium = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: color,
  );
  static TextStyle tittleSmall = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: color,
  );

  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: color,
  );
  static TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColor.primaryColor,
  );
  static TextStyle normal = GoogleFonts.poppins(
    fontSize: 14,
    color: AppColor.primaryColor,
  );
  static TextStyle labelText = GoogleFonts.poppins(
    fontSize: 14,
    color: AppColor.grey,
  );
  static TextStyle normalText = GoogleFonts.poppins(
    fontSize: 14,
    color: AppColor.darkGrey,
  );
}
