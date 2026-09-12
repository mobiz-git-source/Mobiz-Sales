import 'package:flutter/material.dart';
import './sizeconfig.dart';

class AppConfig {
  AppConfig._();

  static const appVersion = "0.1.1";
  static const Map<int, Color> colorTheme = {
    50: Color.fromRGBO(116, 66, 134, .1),
    100: Color.fromRGBO(116, 66, 134, .2),
    200: Color.fromRGBO(116, 66, 134, .3),
    300: Color.fromRGBO(116, 66, 134, .4),
    400: Color.fromRGBO(116, 66, 134, .5),
    500: Color.fromRGBO(116, 66, 134, .6),
    600: Color.fromRGBO(116, 66, 134, .7),
    700: Color.fromRGBO(116, 66, 134, .8),
    800: Color.fromRGBO(116, 66, 134, .9),
    900: Color.fromRGBO(116, 66, 134, 1),
  };

  static const Color colorPrimary = Color(0xFF4B49AC); //Color(0xFF24685B); //

  static const Color colorSuccess = Color(0xFF63BD99);

  static const Color colorWarning = Color(0xFFF9B700);

  // static const Color backgroundColor = Color(0xFFF8F8FF);
  //static const Color backgroundColor = Color(0xFFEDF1F7);
  static const Color backgroundColor = Colors.white;

  //static const Color backgroundColor = Color(0xFFFFFacc);
  static const Color backArrowLightBackground = Colors.black54;

  ///TextColors
  static const Color headingColor = Colors.black;
  static const Color buttonTextColor = Colors.white;

  static const Color buttonDeactiveColor = Colors.grey;
  static const Color textHeadingColor1 = Colors.blueGrey;

  static const Color containerBackground = Color(0xFFffffff);

  static const Color backButtonColor = Colors.white;
  
 static const TextStyle pageTitleStyle = TextStyle(
  color: backgroundColor,
  fontSize: 20,
  fontWeight: FontWeight.w400,
);

  ///Fonts
  ///New definitions

  static var headLineSize = 20.0;
  static var headLineWeight = FontWeight.bold;
  static var subTitleSize = 18.0;
  static var subTitleWeight = FontWeight.bold;
  static var subTitle2Size = 15.0;
  static var subTitle2Weight = FontWeight.w500;
  static var paragraphSize = 15.0;
  static var paragraphWeight = FontWeight.normal;
  static var paragraph2Size = 15.0;
  static var paragraph2Weight = FontWeight.normal;
  static var captionSize = 14.0;
  static var captionWeight = FontWeight.normal;
  static var labelSize = 14.0;
  static var textSize = 12.0;
  static var labelWeight = FontWeight.bold;

  /// New definitions end
  static var textHeadlineSizeBig = SizeConfig.safeBlockVertical! * 7;
  static var textHeadlineSize = SizeConfig.safeBlockVertical! * 5;
  static var textSubTitleSize = SizeConfig.safeBlockVertical! * 4;
  static var textSubtitle2Size = SizeConfig.safeBlockVertical! * 3;
  static var textSubtitle3Size = SizeConfig.safeBlockVertical! * 2.2;
  static var textParagraphSize = SizeConfig.safeBlockVertical! * 4;
  static var textParagraph2Size = SizeConfig.safeBlockVertical! * 3;
  static var textCaptionSize = SizeConfig.safeBlockVertical! * 2;
  static var textCaption2Size = SizeConfig.safeBlockVertical! * 1.8;
  static var textCaption3Size = SizeConfig.safeBlockVertical! * 1.5;
  static var textCaption3Sizepre = SizeConfig.safeBlockVertical! * 1.3;
  static var text3Sizepre = SizeConfig.safeBlockVertical! * 1.4;

  static var textLabelSize = SizeConfig.safeBlockVertical! * 2;
  static var textHeadlineWeight = FontWeight.bold;
  static var textSubTitleWeight = FontWeight.w500;
  static var textSubtitle2Weight = FontWeight.w500;
  static var textParagraphWeight = FontWeight.w300;
  static var textParagraph2Weight = FontWeight.w300;
  static var textCaptionWeight = FontWeight.w300;
  static var textLabelWeight = FontWeight.w600;
  static var textFontFamily = "opensans";

  static Color textColorPrimary = Color(0xFF744286);
  static Color textColorBasic = Color(0xFF222B45);
  static Color textColorHint = Color(0xFF8F9BB3);
  static Color textColorDisabled = textColorHint;
  static Color dashboardIconsColor = Color(0xFF815492);

  //// Icons
  var iconSizeSmall = SizeConfig.safeBlockVertical! * 3;
  var iconSizeMedium = SizeConfig.safeBlockVertical! * 3;
  var iconSizelarge = SizeConfig.safeBlockVertical! * 6;
  var iconSizeExtralarge = SizeConfig.safeBlockVertical! * 8;
////
  ///
  ///

  //text colors
  static const Color textBlack = Colors.black;

//schedule Colors
}
