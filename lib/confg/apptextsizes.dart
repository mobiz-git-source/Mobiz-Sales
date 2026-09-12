/// Centralized semantic font sizes for the Sale / Order / Return screens.
///
/// These values were reverse-engineered from the CURRENT SALE SCREEN
/// (CopyScreen), which is the reference/master design. Do NOT use
/// ScreenUtil's `.sp` extension anywhere these constants are used —
/// these are already the correct, final pixel sizes matching Sale.
class AppFontSizes {
  AppFontSizes._();

  // ---- Small / table-level text ----
  static const double badge = 6.5; // type/unit badges inside product rows
  static const double tableCellSmall = 7.8; // Rate / Amount table cell text
  static const double body = 8.0; // qty text, add-item text, vat toggle text
  static const double label = 8.5; // field labels, header column labels
  static const double value = 9.0; // '#' header, total/vat values, row values
  static const double caption = 9.5; // small captions
  static const double miniBadge = 10.0; // small badges/pills

  // ---- Dialog-level text (product details dialog) ----
  static const double dialogBody = 10.5;
  static const double dialogBodyEmphasis = 11.0;
  static const double dialogRow = 11.5;
  static const double dialogLabel = 12.0;
  static const double dialogSubtitle = 12.5;
  static const double dialogInput = 13.0;
  static const double dialogTitle = 13.5;
  static const double dialogHighlight = 14.0;

  // ---- Hero text ----
  static const double grandTotal = 15.0;

  // ---- Compact elements (kept for any legacy compact layouts) ----
  static const double compactButton = 7.5;
  static const double compactHeader = 8.0;
  static const double compactCell = 7.5;
  static const double compactBadge = 6.5;
  static const double compactSummary = 8.5;
}