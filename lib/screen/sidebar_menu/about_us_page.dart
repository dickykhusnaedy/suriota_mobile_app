import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About Us',
          style: context.h5.copyWith(color: AppColor.whiteColor),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: AppColor.primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: Column(
            children: [
              AppSpacing.md,
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  ImageAsset.companyImage,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              AppSpacing.md,
              Text(
                'PT Surya Inovasi Prioritas Teknologi (Suriota)',
                style: context.h3,
              ),
              AppSpacing.md,
              Text(
                'PT Surya Inovasi Prioritas atau Suriota merupakan sebuah perusahaan yang bergerak di Technology Engineering Service berlokasi di Batam, Kepulauan Riau, Indonesia. Berdiri pada Januari 2023 yang menyediakan layanan atau jasa engineering terkait dengan teknologi.\n',
                textAlign: TextAlign.justify,
                style: context.body,
              ),
              Text(
                "Kami berkomitmen untuk menyediakan layanan berkualitas tinggi bagi client dan bertujuan menjadi mitra terpercaya dalam meningkatkan efisiensi dan produktivitas bisnis client kami.",
                textAlign: TextAlign.justify,
                style: context.body,
              ),
              AppSpacing.lg,
            ],
          ),
        ),
      ),
    );
  }
}
