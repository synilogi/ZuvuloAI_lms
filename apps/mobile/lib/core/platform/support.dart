/// Where a person writes for help, a privacy question or to have an account removed — the address
/// the academy's website, privacy policy and help centre give.
const String kSupportEmail = 'help@zuviloai.com';

/// A `mailto:` link to [kSupportEmail] with [subject] filled in.
Uri supportEmailLink({required String subject}) =>
    Uri(scheme: 'mailto', path: kSupportEmail, query: 'subject=${Uri.encodeComponent(subject)}');
