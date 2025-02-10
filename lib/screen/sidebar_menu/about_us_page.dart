import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          'About Us',
          style: FontFamily.tittleSmall.copyWith(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset(ImageAsset.companyImage),
            const SizedBox(
              height: 16,
            ),
            Text(
              'PT Surya Inovasi Prioritas Teknologi (Suriota)',
              style: FontFamily.titleMedium,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              'PT Surya Inovasi Prioritas atau Suriota merupakan sebuah perusahaan yang bergerak di Technology Engineering Service berlokasi di Batam, Kepulauan Riau, Indonesia. Berdiri pada Januari 2023 yang menyediakan layanan atau jasa engineering terkait dengan teknologi.\n',
              textAlign: TextAlign.justify,
              style: FontFamily.normal,
            ),
            Text(
              "Kami berkomitmen untuk menyediakan layanan berkualitas tinggi bagi client dan bertujuan menjadi mitra terpercaya dalam meningkatkan efisiensi dan produktivitas bisnis client kami.",
              textAlign: TextAlign.justify,
              style: FontFamily.normal,
            ),
          ],
        ),
      ),
    );
  }
}
