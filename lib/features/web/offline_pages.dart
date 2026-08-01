import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_icons.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_typography.dart';
import 'legal_content.dart';
import 'web_page_screen.dart';

/// Rendered when the hosted page cannot be reached. Same content, same
/// contract: black text on white.
class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key, required this.kind});

  final WebPageKind kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      WebPageKind.privacy => const _PrivacyDocument(),
      WebPageKind.support => const _SupportForm(),
    };
  }
}

class _PrivacyDocument extends StatelessWidget {
  const _PrivacyDocument();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      itemCount: LegalContent.privacy.length,
      itemBuilder: (BuildContext context, int i) =>
          _block(LegalContent.privacy[i]),
    );
  }

  Widget _block(LegalBlock block) {
    switch (block.kind) {
      case LegalBlockKind.heading:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            block.text,
            style: AppType.displayM(color: Colors.black),
          ),
        );
      case LegalBlockKind.meta:
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text(
            block.text,
            style: AppType.bodyS(color: const Color(0xFF555560)),
          ),
        );
      case LegalBlockKind.section:
        return Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 8),
          child: Text(
            block.text,
            style: AppType.titleM(color: Colors.black),
          ),
        );
      case LegalBlockKind.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            block.text,
            style: AppType.bodyM(color: Colors.black).copyWith(height: 1.62),
          ),
        );
      case LegalBlockKind.bullet:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 10),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  block.text,
                  style: AppType.bodyM(color: Colors.black).copyWith(height: 1.55),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _SupportForm extends StatefulWidget {
  const _SupportForm();

  @override
  State<_SupportForm> createState() => _SupportFormState();
}

class _SupportFormState extends State<_SupportForm> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _question = TextEditingController();
  bool _copied = false;

  @override
  void dispose() {
    _email.dispose();
    _question.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final String body = 'To: ${AppConfig.supportEmail}\n'
        'Subject: ${AppConfig.appName} support request\n\n'
        'From: ${_email.text.trim().isEmpty ? '(no email provided)' : _email.text.trim()}\n'
        'App version: ${AppConfig.version}\n'
        'App ID: ${AppConfig.appId}\n\n'
        '${_question.text.trim()}';
    await Clipboard.setData(ClipboardData(text: body));
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B1B22),
          content: Text(
            'Request copied — paste it into an email to ${AppConfig.supportEmail}',
            style: AppType.bodyM(color: Colors.white),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    const Color ink = Colors.black;
    const Color line = Color(0xFFD7D7DE);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: <Widget>[
        Text('Support for ${AppConfig.appName}',
            style: AppType.displayM(color: ink)),
        const SizedBox(height: 10),
        Text(
          'You are offline right now, so the web form cannot be submitted. '
          'Fill it in below and copy it — the text is ready to be pasted into '
          'an email whenever you reconnect.',
          style: AppType.bodyM(color: const Color(0xFF4A4A55)).copyWith(height: 1.6),
        ),
        const SizedBox(height: 24),
        Text('Email', style: AppType.label(color: ink)),
        const SizedBox(height: 8),
        _field(_email, 'you@example.com', line, TextInputType.emailAddress, 1),
        const SizedBox(height: 18),
        Text('Question', style: AppType.label(color: ink)),
        const SizedBox(height: 8),
        _field(_question, 'Describe the problem or your question…', line,
            TextInputType.multiline, 6),
        const SizedBox(height: 22),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _question.text.trim().isEmpty ? _copy : _copy,
            icon: Icon(
              _copied ? AppIcons.check : AppIcons.copy,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              _copied ? 'Copied' : 'Copy request',
              style: AppType.titleS(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(AppIcons.envelope, size: 17, color: ink),
                  const SizedBox(width: 10),
                  Text('Direct contact', style: AppType.titleS(color: ink)),
                ],
              ),
              const SizedBox(height: 10),
              SelectableText(
                AppConfig.supportEmail,
                style: AppType.bodyM(color: ink),
              ),
              const SizedBox(height: 14),
              Text(
                'App ID ${AppConfig.appId} · Version ${AppConfig.version}',
                style: AppType.bodyS(color: const Color(0xFF6A6A75)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            const Icon(AppIcons.refresh,
                size: 15, color: Color(0xFF6A6A75)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'The online form loads automatically as soon as a connection '
                'comes back.',
                style: AppType.bodyS(color: const Color(0xFF6A6A75)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint,
    Color line,
    TextInputType type,
    int lines,
  ) {
    return TextField(
      controller: controller,
      keyboardType: type,
      minLines: lines,
      maxLines: lines,
      onChanged: (_) {
        if (_copied) setState(() => _copied = false);
      },
      style: AppType.bodyM(color: Colors.black),
      cursorColor: const Color(0xFF6C5CE7),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppType.bodyM(color: const Color(0xFF9A9AA5)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.4),
        ),
      ),
    );
  }
}
