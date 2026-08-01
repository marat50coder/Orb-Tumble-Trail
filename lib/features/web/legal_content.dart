import '../../core/constants/app_config.dart';

/// Offline copies of the two web pages. They are bundled so the screens can
/// always render something correct, even with no connection at all.
class LegalContent {
  const LegalContent._();

  static const String privacyEffectiveDate = 'June 2026';

  static const List<LegalBlock> privacy = <LegalBlock>[
    LegalBlock.heading('Privacy Policy'),
    LegalBlock.meta('Effective date: $privacyEffectiveDate'),
    LegalBlock.paragraph(
      'Developer ("we", "us", or "our") operates the Orb Tumble Trail mobile '
      'application ("Service"). This Privacy Policy explains how information is '
      'collected, used, and protected when you use the Service.',
    ),
    LegalBlock.section('Information We Collect'),
    LegalBlock.paragraph(
      'The Service may collect limited technical information necessary for '
      'operation and improvement of the application, including:',
    ),
    LegalBlock.bullet('Device type and model'),
    LegalBlock.bullet('Operating system version'),
    LegalBlock.bullet('Anonymous usage statistics'),
    LegalBlock.bullet('Diagnostic and crash information'),
    LegalBlock.bullet('IP address (when required for security and analytics purposes)'),
    LegalBlock.paragraph(
      'We do not intentionally collect sensitive personal information such as '
      'financial account details, government-issued identification numbers, or '
      'biometric data.',
    ),
    LegalBlock.section('How We Use Information'),
    LegalBlock.bullet('Provide and maintain the Service'),
    LegalBlock.bullet('Improve app functionality and user experience'),
    LegalBlock.bullet('Monitor application performance and stability'),
    LegalBlock.bullet('Detect, prevent, and resolve technical issues'),
    LegalBlock.bullet('Comply with legal obligations'),
    LegalBlock.section('Data Storage and Security'),
    LegalBlock.paragraph(
      'We take reasonable measures to protect information from unauthorized '
      'access, alteration, disclosure, or destruction. However, no method of '
      'electronic transmission or storage is completely secure.',
    ),
    LegalBlock.section('Third-Party Services'),
    LegalBlock.paragraph(
      'The Service may use third-party providers for analytics, crash reporting, '
      'hosting, or other operational purposes. These providers may process '
      'information solely to provide services on our behalf.',
    ),
    LegalBlock.section('Data Retention'),
    LegalBlock.paragraph(
      'We retain information only for as long as necessary to provide the '
      'Service, comply with legal obligations, resolve disputes, and enforce '
      'agreements.',
    ),
    LegalBlock.section('Data Deletion'),
    LegalBlock.paragraph(
      'Users have the right to request deletion of their personal data. To '
      'request deletion of data associated with Orb Tumble Trail, please contact '
      'us at ${AppConfig.supportEmail}.',
    ),
    LegalBlock.paragraph(
      'When submitting a deletion request, please provide sufficient information '
      'to identify your account or device. Verified requests will be processed '
      'within a reasonable timeframe.',
    ),
    LegalBlock.paragraph(
      'If the application stores data only on the user\'s device, users may '
      'permanently delete all stored data by uninstalling the application and '
      'clearing the application\'s local storage.',
    ),
    LegalBlock.section('Your Rights'),
    LegalBlock.paragraph(
      'Depending on your location, you may have rights regarding access, '
      'correction, deletion, restriction, or portability of your personal data '
      'under applicable privacy laws, including the GDPR.',
    ),
    LegalBlock.section("Children's Privacy"),
    LegalBlock.paragraph(
      'The Service is not intended for children under the age of 18, and we do '
      'not knowingly collect personal information from children.',
    ),
    LegalBlock.section('Changes to This Privacy Policy'),
    LegalBlock.paragraph(
      'We may update this Privacy Policy from time to time. Changes become '
      'effective when posted on this page. Users are encouraged to review this '
      'policy periodically.',
    ),
    LegalBlock.section('Contact Us'),
    LegalBlock.paragraph(
      'If you have questions about this Privacy Policy or wish to exercise your '
      'privacy rights, please contact:',
    ),
    LegalBlock.paragraph('Developer: Orb Tumble Trail'),
    LegalBlock.paragraph('Email: ${AppConfig.supportEmail}'),
  ];
}

enum LegalBlockKind { heading, section, paragraph, bullet, meta }

class LegalBlock {
  const LegalBlock.heading(this.text) : kind = LegalBlockKind.heading;
  const LegalBlock.section(this.text) : kind = LegalBlockKind.section;
  const LegalBlock.paragraph(this.text) : kind = LegalBlockKind.paragraph;
  const LegalBlock.bullet(this.text) : kind = LegalBlockKind.bullet;
  const LegalBlock.meta(this.text) : kind = LegalBlockKind.meta;

  final LegalBlockKind kind;
  final String text;
}
