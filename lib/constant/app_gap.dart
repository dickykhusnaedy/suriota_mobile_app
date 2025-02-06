import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class AppSpacing {
  static final xs = Gap(4.sp);
  static final sm = Gap(8.sp);
  static final md = Gap(16.sp);
  static final lg = Gap(24.sp);
  static final xl = Gap(32.sp);
  static final xxl = Gap(48.sp);
  static final xxxl = Gap(55.sp);
  static final xxxxl = Gap(80.sp);
}

class AppPadding {
  static EdgeInsets small = EdgeInsets.all(8.w);
  static EdgeInsets medium = EdgeInsets.all(16.w);
  static EdgeInsets large = EdgeInsets.all(24.w);

  static EdgeInsets horizontalSmall = EdgeInsets.symmetric(horizontal: 8.w);
  static EdgeInsets horizontalMedium = EdgeInsets.symmetric(horizontal: 16.w);
  static EdgeInsets horizontalLarge = EdgeInsets.symmetric(horizontal: 24.w);

  static EdgeInsets verticalSmall = EdgeInsets.symmetric(vertical: 8.h);
  static EdgeInsets verticalMedium = EdgeInsets.symmetric(vertical: 16.h);
  static EdgeInsets verticalLarge = EdgeInsets.symmetric(vertical: 24.h);

  static EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h);

  static EdgeInsets screenPadding = EdgeInsets.all(16.w);
}

class AppGap {
  AppGap._();
  static const Gap gap2 = Gap(2);
  static const Gap gap4 = Gap(4);
  static const Gap gap6 = Gap(6);
  static const Gap gap8 = Gap(8);
  static const Gap gap10 = Gap(10);
  static const Gap gap12 = Gap(12);
  static const Gap gap14 = Gap(14);
  static const Gap gap16 = Gap(16);
  static const Gap gap18 = Gap(18);
  static const Gap gap20 = Gap(10);
  static const Gap gap22 = Gap(22);
  static const Gap gap24 = Gap(24);
  static const Gap gap26 = Gap(26);
  static const Gap gap28 = Gap(28);
  static const Gap gap30 = Gap(30);
  static const Gap gap32 = Gap(32);
  static const Gap gap34 = Gap(34);
  static const Gap gap36 = Gap(36);
  static const Gap gap38 = Gap(38);
  static const Gap gap40 = Gap(40);
  static const Gap gap42 = Gap(42);
  static const Gap gap44 = Gap(44);
  static const Gap gap46 = Gap(46);
  static const Gap gap48 = Gap(48);
  static const Gap gap50 = Gap(50);
}
