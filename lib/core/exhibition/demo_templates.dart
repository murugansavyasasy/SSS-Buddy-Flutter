import '../../auth/model/ExhibitionModel.dart';

/// Pre-recorded demo voices offered on the Give Demo screen.
///
/// TEMPORARY sample audio: free public-domain speech clips from the Open Speech
/// Repository (WAV, 8 kHz, mono — the dialer format), so preview and send can
/// be tested end to end. They are not product recordings.
/// For now these hardcoded templates are always shown; any templates the
/// backend returns (GET exhibitions/templates) are added after them.
/// TODO: replace with the real hosted template WAVs before release.
const List<DemoTemplate> exhibitionDemoTemplates = [
  DemoTemplate(
    id: 'product_intro_en',
    title: 'Product Intro (English)',
    description: 'Short overview of the school platform for principals',
    duration: Duration(seconds: 34),
    audioUrl: 'https://www.voiptroubleshooter.com/open_speech/american/OSR_us_000_0010_8k.wav',
  ),
  DemoTemplate(
    id: 'product_intro_ta',
    title: 'Product Intro (Tamil)',
    description: 'The same overview, narrated in Tamil',
    duration: Duration(seconds: 40),
    // Sample only (British English); no free Tamil clip in this format.
    audioUrl: 'https://www.voiptroubleshooter.com/open_speech/british/OSR_uk_000_0020_8k.wav',
  ),
  DemoTemplate(
    id: 'school_erp_overview',
    title: 'School ERP Overview',
    description: 'Admissions, fees, attendance and exams in one place',
    duration: Duration(seconds: 33),
    audioUrl: 'https://www.voiptroubleshooter.com/open_speech/american/OSR_us_000_0011_8k.wav',
  ),
  DemoTemplate(
    id: 'mobile_app_features',
    title: 'Mobile App Features',
    description: 'Parent and teacher app walkthrough',
    duration: Duration(seconds: 33),
    audioUrl: 'https://www.voiptroubleshooter.com/open_speech/american/OSR_us_000_0012_8k.wav',
  ),
];
