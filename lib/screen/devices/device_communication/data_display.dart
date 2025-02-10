import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_appbar.dart';

import '../../../constant/app_color.dart';
import '../../../constant/font_setup.dart';

// class DisplayDataPage extends StatelessWidget {
//   const DisplayDataPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBar(title: 'Display Data'),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Text(
//               'Temperature Control 16B',
//               style: FontFamily.headlineMedium,
//             ),
//             const SizedBox(
//               height: 14,
//             ),
//             ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: 5,
//                 itemBuilder: (BuildContext context, int index) {
//                   return InkWell(
//                       onTap: () {
//                         // Navigator.push(
//                         //     context,
//                         //     MaterialPageRoute(
//                         //         builder: (context) => const DisplayDataPage()));
//                       },
//                       child: Stack(
//                           alignment: AlignmentDirectional.topEnd,
//                           children: [
//                             SizedBox(
//                               width: MediaQuery.of(context).size.width * 1,
//                               child: Card(
//                                 color: AppColor.cardColor,
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(16.0),
//                                   child:
//                                       // Stack(children: [
//                                       Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Temperature Control 16B',
//                                         style: FontFamily.headlineMedium
//                                             .copyWith(fontSize: 14),
//                                         overflow: TextOverflow.clip,
//                                       ),
//                                       const SizedBox(
//                                         height: 5,
//                                       ),
//                                       Text(
//                                         'Device RTU',
//                                         style: FontFamily.normal,
//                                       )
//                                     ],
//                                   ),
//                                   //
//                                   // ]),
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.all(4.0),
//                               child: Container(
//                                 height: 30,
//                                 width: 130,
//                                 decoration: const BoxDecoration(
//                                     color: AppColor.labelColor,
//                                     borderRadius: BorderRadius.only(
//                                       topRight: Radius.circular(10.0),
//                                       bottomLeft: Radius.circular(10.0),
//                                     )),
//                                 child: Center(
//                                   child: Text(
//                                     '25 Aug 2024 13.00.00',
//                                     textAlign: TextAlign.center,
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .labelMedium!
//                                         .copyWith(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 10,
//                                             color: Colors.white),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ]));
//                 }),
//           ],
//         ),
//       ),
//     );
//   }
// }

class DisplayDataPage extends StatelessWidget {
  final String title; // Parameter untuk nama perangkat
  final String modbusType; // Parameter untuk tipe Modbus

  const DisplayDataPage({
    super.key,
    required this.title, // Required parameter
    required this.modbusType, // Required parameter
  });

  @override
  Widget build(BuildContext context) {
    List<String> addressData = [
      "0x3042",
      "0x2042",
      "0x8219",
      "0x8163",
      "0x6661",
      "0x6763"
    ];
    List<String> valueData = ["142", "920", "821", "710", "180", "170"];
    return Scaffold(
      appBar: const CustomAppBar(title: 'Display Data'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Menggunakan data yang diterima dari halaman sebelumnya
            Text(
              title, // Tampilkan nama perangkat
              style: FontFamily.headlineMedium,
            ),
            const SizedBox(
              height: 14,
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (BuildContext context, int index) {
                return Stack(
                  alignment: AlignmentDirectional.topEnd,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 1,
                      child: Card(
                        color: AppColor.cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Address ${addressData[index]}', // Tampilkan nama perangkat
                                style: FontFamily.headlineMedium
                                    .copyWith(fontSize: 14),
                                overflow: TextOverflow.clip,
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                'Value : ${valueData[index]}', // Tampilkan tipe Modbus
                                style: FontFamily.normal,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        height: 30,
                        width: 130,
                        decoration: const BoxDecoration(
                            color: AppColor.labelColor,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10.0),
                              bottomLeft: Radius.circular(10.0),
                            )),
                        child: Center(
                          child: Text(
                            '25 Aug 2024 13.00.00', // Data statis contoh
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
