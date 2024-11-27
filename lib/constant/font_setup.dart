import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';

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
    fontSize: 16,
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
