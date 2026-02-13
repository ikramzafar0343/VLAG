import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// VLag button styles - green/teal rounded style as per design
class VLagButtonStyle {
  /// Primary VLag green color
  static const Color primaryGreen = Color(0xFF1DB877);
  
  /// Primary button style - green rounded
  static ButtonStyle get primary => ElevatedButton.styleFrom(
        minimumSize: const Size(100, 55),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
      );

  /// Secondary button style - same green style (no grey)
  static ButtonStyle get secondary => ElevatedButton.styleFrom(
        minimumSize: const Size(100, 50),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
      );

  /// Outlined button style - green border
  static ButtonStyle get outlined => OutlinedButton.styleFrom(
        minimumSize: const Size(100, 50),
        foregroundColor: primaryGreen,
        side: const BorderSide(color: primaryGreen, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
      );

  /// Text style for VLag buttons
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}

class HorizontalOrLine extends StatelessWidget {
  /// In auth page
  /// https://stackoverflow.com/a/61304861/13617136
  const HorizontalOrLine({
    super.key,
    this.label,
    this.height,
  });

  final String? label;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(children: [
        Expanded(
          child: Container(
              margin: const EdgeInsets.only(left: 10.0, right: 15.0),
              child: Divider(
                color: Colors.black,
                height: height,
              )),
        ),
        Text(label!),
        Expanded(
          child: Container(
              margin: const EdgeInsets.only(left: 15.0, right: 10.0),
              child: Divider(
                color: Colors.black,
                height: height,
              )),
        ),
      ]),
    );
  }
}

Container buildChangeDpIcon() {
  return Container(
    padding: const EdgeInsets.all(5.0),
    decoration: const BoxDecoration(
      color: VLagButtonStyle.primaryGreen,
      shape: BoxShape.circle,
    ),
    child: const FaIcon(
      FontAwesomeIcons.camera,
      color: Colors.white,
      size: 12,
    ),
  );
}

TextStyle linkTextStyle =
    const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold);

TextStyle dottedUnderlinedStyle({Color? color}) => TextStyle(
    color: color,
    decorationStyle: TextDecorationStyle.dotted,
    decoration: TextDecoration.underline);

class ReportTextField extends StatelessWidget {
  const ReportTextField(
      {super.key,
      required TextEditingController reportController,
      this.showAnonymousMessage})
      : _reportController = reportController;

  final TextEditingController _reportController;
  final bool? showAnonymousMessage;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: 4,
      controller: _reportController,
      decoration: InputDecoration(
        labelText: 'Report a bug or problem',
        helperText: showAnonymousMessage! ? 'Your message is anonymous' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      keyboardType: TextInputType.multiline,
    );
  }
}

class NameTextField extends StatelessWidget {
  const NameTextField(
      {super.key,
      required TextEditingController nameController,
      TextInputAction keyboardAction = TextInputAction.next})
      : _nameController = nameController,
        _keyboardAction = keyboardAction;

  final TextEditingController _nameController;
  final TextInputAction _keyboardAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
      controller: _nameController,
      decoration: InputDecoration(
        helperText: 'Nickname must not be empty',
        isDense: true,
        labelText: 'Nickname',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      textInputAction: _keyboardAction,
      autofillHints: const [AutofillHints.name],
      keyboardType: TextInputType.name,
    );
  }
}

class SubtitleTextField extends StatelessWidget {
  const SubtitleTextField({
    super.key,
    required TextEditingController subsController,
  })  : _subsController = subsController;

  final TextEditingController _subsController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _subsController,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Enter your address, bio, etc.',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.text,
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 10,
      height: 10,
      child: CircularProgressIndicator(
        backgroundColor: Colors.white,
      ),
    );
  }
}

class LinkContainer extends StatelessWidget {
  const LinkContainer({super.key, this.child});
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.0),
            color: isDark 
                ? Colors.white.withAlpha(30)  // Light color for dark mode
                : VLagButtonStyle.primaryGreen.withValues(alpha: 0.2)),  // Greenish for light mode
        child: DefaultTextStyle(
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,  // White text in dark mode, black in light mode
          ),
          child: child ?? const SizedBox(),
        ));
  }
}
