import 'package:flutter/material.dart';
import 'package:mobizapp/Pages/van_transfer.dart';

import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'VanTransferReceive.dart';
import 'VanTransfetConfirm.dart';

class VantransferOption extends StatefulWidget {
  static const routeName = "/VantransferOption";
  const VantransferOption({super.key});

  @override
  State<VantransferOption> createState() => _VantransferOptionState();
}

class _VantransferOptionState extends State<VantransferOption> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // toolbarHeight: 40,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
          backgroundColor: AppConfig.colorPrimary,
          titleSpacing: 0,
          title: Text(
            'Van Transfer Option',
          style: AppConfig.pageTitleStyle,
          )),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(VanTransfer.routeName);
                  },
                  child: _iconButtons(
                      icon: AssetImage(
                          'Assets/Images/request-new-icon-2048x2048-vv3yx1iz.png'),
                      title: 'Request')),
              GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed(VanTransferConfirm.routeName);
                  },
                  child: _iconButtons(
                      icon: AssetImage(
                          'Assets/Images/207-2078379_computer-icons-brand-check-mark-true-icon-png.png'),
                      title: 'Confirm')),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _iconButtons({AssetImage? icon, required String title, String? image}) {
  return Container(
    width: SizeConfig.blockSizeHorizontal * 25,
    height: SizeConfig.blockSizeVertical * 12.5,
    decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: AppConfig.colorPrimary),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null)
          Image(
            image: icon,
            fit: BoxFit.cover,
            color: Colors.white,
            width: 50,
          )
        else if (image != null)
          Image.asset(
            image,
            width: 50,
            height: 40,
            fit: BoxFit.cover,
          ),
        SizedBox(
          width: SizeConfig.blockSizeHorizontal * 18,
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppConfig.backgroundColor,
                  fontSize: AppConfig.textCaption3Size),
            ),
          ),
        )
      ],
    ),
  );
}
