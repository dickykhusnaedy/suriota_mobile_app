import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FontSizeTheme {
  static double h1 = 32.sp.clamp(32, 34);
  static double h2 = 24.sp.clamp(24, 26);
  static double h3 = 20.sp.clamp(20, 22);
  static double h4 = 18.sp.clamp(18, 20);
  static double h5 = 16.sp.clamp(16, 18);
  static double h6 = 14.sp.clamp(14, 16);
  static double body = 14.sp.clamp(14, 16);
  static double bodySmall = 12.sp.clamp(12, 14);
  static double bodySmallest = 10.sp.clamp(10, 12);
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

  static const Color color = AppColor.blackColor;

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
    color: color,
  );
  static TextStyle normal = GoogleFonts.poppins(
    fontSize: 14,
    color: color,
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
