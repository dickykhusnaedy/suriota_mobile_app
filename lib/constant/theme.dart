import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';

import 'font_setup.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          titleLarge: GoogleFonts.poppins(
              fontSize: FontSizeTheme.h1,
              fontWeight: FontWeightTheme.extraBold,
              color: AppColor.primaryColor),
          titleMedium: GoogleFonts.poppins(
              fontSize: FontSizeTheme.h2,
              fontWeight: FontWeightTheme.bold,
              color: AppColor.primaryColor),
          titleSmall: GoogleFonts.poppins(
              fontSize: FontSizeTheme.h3,
              fontWeight: FontWeightTheme.bold,
              color: AppColor.primaryColor),
          headlineLarge: GoogleFonts.poppins(
              fontSize: FontSizeTheme.h4,
              fontWeight: FontWeightTheme.semiBold,
              color: AppColor.primaryColor),
          headlineMedium: GoogleFonts.poppins(
              fontSize: FontSizeTheme.h5,
              fontWeight: FontWeightTheme.semiBold,
              color: AppColor.primaryColor),
          headlineSmall: GoogleFonts.poppins(
              fontSize: FontSizeTheme.h6,
              fontWeight: FontWeightTheme.semiBold,
              color: AppColor.primaryColor),
          bodyMedium: GoogleFonts.poppins(
              fontSize: FontSizeTheme.body,
              fontWeight: FontWeightTheme.regular,
              color: AppColor.primaryColor),
          bodySmall: GoogleFonts.poppins(
              fontSize: FontSizeTheme.bodySmall,
              fontWeight: FontWeightTheme.regular,
              color: AppColor.primaryColor),
          labelMedium: GoogleFonts.poppins(
              fontSize: FontSizeTheme.body,
              fontWeight: FontWeightTheme.medium,
              color: AppColor.whiteColor),
          labelSmall: GoogleFonts.poppins(
              fontSize: FontSizeTheme.bodySmall,
              fontWeight: FontWeightTheme.medium,
              color: AppColor.whiteColor)),
      useMaterial3: true);
}

ThemeData themeData() {
  return ThemeData(
    // drawerTheme: DrawerThemeData(backgroundColor: AppColor.cardColor),
    appBarTheme: AppBarTheme(
        backgroundColor: AppColor.primaryColor,
        // centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        toolbarTextStyle: GoogleFonts.poppins(
          color: AppColor.primaryColor,
          fontSize: 16,
        ),
        iconTheme: const IconThemeData(
          color: AppColor.primaryColor,
        )),
    textTheme: TextTheme(
      titleLarge: GoogleFonts.poppins(
          fontSize: 32,
          color: AppColor.primaryColor,
          fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.poppins(
          color: AppColor.primaryColor, fontWeight: FontWeight.bold),
      titleSmall: GoogleFonts.poppins(color: AppColor.primaryColor),
      headlineLarge: GoogleFonts.poppins(
          color: AppColor.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w800),
      headlineMedium: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColor.primaryColor,
          fontWeight: FontWeight.w800),
      labelSmall: GoogleFonts.poppins(color: AppColor.primaryColor),
      labelMedium: GoogleFonts.poppins(color: AppColor.primaryColor),
    ),
    // colorScheme: ColorScheme.fromSeed(seedColor: AppColor.primaryColor),
    useMaterial3: true,
  );
}

//VIEW DATA KOSONG
Center dataEmptyView(BuildContext context, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
            height: 169, width: 203, child: Image.asset('assets/error.png')),
        Text(
          message.toUpperCase(),
          // 'Sorry, the data is not found!'.toUpperCase(),
          style: Theme.of(context).textTheme.headlineLarge,
        )
      ],
    ),
  );
}

Future<dynamic> dialogSuccess(BuildContext context) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          alignment: Alignment.center,
          title: const Icon(
            size: 65,
            Icons.check_circle,
            color: AppColor.primaryColor,
          ),
          content: Text(
            'Data Saved Successed',
            style: FontFamily.headlineMedium,
            textAlign: TextAlign.center,
          ),
        );
      });
}
