import '../../auth/model/ExhibitionModel.dart';

/// Pre-recorded demo voices offered on the Give Demo screen.
///
/// TODO: put the real hosted WAV links (8 kHz, mono) in [audioUrl]. A template
/// with an empty URL is shown as "Audio not set up yet" and cannot be sent.
/// When the backend exposes a templates endpoint, load this list from there.
const List<DemoTemplate> exhibitionDemoTemplates = [
  DemoTemplate(
    id: 'product_intro_en',
    title: 'Product Intro (English)',
    description: 'Short overview of the school platform for principals',
    duration: Duration(minutes: 1, seconds: 45),
    audioUrl: '',
  ),
  DemoTemplate(
    id: 'product_intro_ta',
    title: 'Product Intro (Tamil)',
    description: 'The same overview, narrated in Tamil',
    duration: Duration(minutes: 1, seconds: 50),
    audioUrl: '',
  ),
  DemoTemplate(
    id: 'school_erp_overview',
    title: 'School ERP Overview',
    description: 'Admissions, fees, attendance and exams in one place',
    duration: Duration(minutes: 2, seconds: 30),
    audioUrl: '',
  ),
  DemoTemplate(
    id: 'mobile_app_features',
    title: 'Mobile App Features',
    description: 'Parent and teacher app walkthrough',
    duration: Duration(minutes: 1, seconds: 20),
    audioUrl: '',
  ),
];
