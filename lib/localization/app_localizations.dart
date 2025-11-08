import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';

class AppLocalizations {
  final String locale;

  AppLocalizations(this.locale);

  // Helper method to get localizations from context
  static AppLocalizations of(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    return AppLocalizations(languageProvider.currentLanguage);
  }

  // Add translations for common UI elements
  static final Map<String, Map<String, String>> _localizedValues = {
    'English': {
      // Transaction ID dialog
      'confirmYourPayment': 'Confirm Your Payment',
      'pleaseEnterTheFinancialTransactionId':
          'Please enter the Financial Transaction ID from your MTN payment confirmation message',
      'pleaseWaitForOurTeamToConfirmYourTransaction':
          'Please wait for our team to confirm your transaction. This usually takes less than 10 minutes during business hours.',
      'confirmAndSubmit': 'Confirm & Submit',
      'transactionIdSubmittedSuccessfully':
          'Transaction ID submitted successfully. Our team will verify and activate your account shortly.',
      'pleaseEnterTransactionId': 'Please enter a valid Transaction ID',

      // Settings
      'settings': 'Settings',
      'darkMode': 'Dark Mode',
      'language': 'Language',
      'selectLanguage': 'Select Language',
      'cancel': 'Cancel',
      'searchSettings': 'Search Settings',
      'selectFontFamily': 'Select Font Family',
      'selectFontSize': 'Select Font Size',
      'languageAudio': 'Language Audio',
      'dataPerformance': 'Data Performance',
      'dailyAffirmations': 'Daily Affirmations',
      'chooseLanguageDescription': 'Choose your preferred language',
      'chooseFontFamilyDescription':
          'Choose a font that feels comfortable to read',
      'fontSizeFollowsSystem':
          'Font size follows your device accessibility setting.',
      'database': 'Database',
      'contentPolicyReporting': 'Content Policy Reporting',
      'adminControls': 'Admin Controls',
      'lowDataMode': 'Low Data Mode',
      'imageLazyLoading': 'Image Lazy Loading',
      'offlineMode': 'Offline Mode',

      // Navigation
      'home': 'Home',
      'forum': 'Forum',
      'mahoro': 'Mahoro',
      'muganga': 'Muganga',

      // Accessibility
      'accessibility': 'Accessibility',
      'fontFamily': 'Font Family',
      'fontSize': 'Font Size',
      'highContrastMode': 'High Contrast Mode',
      'reduceMotion': 'Reduce Motion',
      'textToSpeech': 'Text-to-Speech',
      'voiceToText': 'Voice-to-Text',

      // Appearance
      'appearance': 'Appearance',

      // Notifications
      'notifications': 'Notifications',
      'forumReplies': 'Forum Replies',
      'weeklyCheckIns': 'Weekly Check-Ins',
      'systemUpdates': 'System Updates',

      // Privacy & Security
      'privacySecurity': 'Privacy Policy',
      'emergencyContacts': 'Emergency Contacts',
      'logout': 'Logout',
      'signIn': 'Sign In',
      'editProfile': 'Edit Profile',

      // Forum
      'safeSpaceToShare': 'Safe space to share',
      'noPostsYet': 'No posts yet',
      'beTheFirstToStartConversation': 'Be the first to start a conversation',
      'createPost': 'Create Post',
      'joinTheConvo': 'Join The Convo',
      'search': 'Search',
      'searchPosts': 'Search posts...',
      'likes': 'Likes',
      'replies': 'Replies',
      'reply': 'Reply',
      'anonymous': 'Anonymous',
      'postTitle': 'Post Title',
      'postContent': 'Post Content',
      'post': 'Post',

      // Mahoro
      'yourSupportCompanion': 'Your 24/7 support companion',
      'typeMessage': 'Type a message...',
      'send': 'Send',
      'talkToMahoro': 'Talk to Mahoro',

      // Muganga
      'mugangaTherapy': 'Muganga Therapy',
      'professionalMentalHealthSupport': 'Professional mental health support',
      'monthlySubscription': 'Monthly Subscription',
      '2000RWF': '2,000 RWF',
      'unlimitedTherapySessionsWithCertifiedProfessionals':
          'Unlimited therapy sessions with certified professionals',
      'subscribeNow': 'Subscribe Now',
      'mtnMobileMoneyPayment': 'MTN Mobile Money Payment',
      'payWithMtnMobileMoney': 'Pay with MTN Mobile Money',
      'dialTheFollowingUssdCodeOnYourMtnPhone':
          'Dial the following USSD code on your MTN phone:',
      'ussdCode': '*182*1*1*0780332779*2000#',
      'afterPaymentYouWillReceive': 'After payment, you will receive:',
      'immediateConfirmationMessage': 'Immediate confirmation message',
      'paymentReceiptFromOurTeam': 'Payment receipt from our team',
      'accessToTherapyBooking': 'Access to therapy booking',
      'note': 'Note:',
      'paymentGoesDirectlyToOurTeamAt250780332779TheNumberIsRegisteredToAlineIRADUKUNDAOurChiefOperationsOfficerSheWillBeContactingYouAsSoonAsThePaymentIsReceivedForAccountActivation':
          'Payment goes directly to our team at +250780332779. The number is registered to Aline IRADUKUNDA, our Chief Operations Officer. She will be contacting you as soon as the payment is received for account activation.',
      'iveMadeThePayment': 'I\'ve Made the Payment',
      'payEasilyWithMtnMobileMoneyAndGetInstantAccessToProfessionalTherapy':
          'Pay easily with MTN Mobile Money and get instant access to professional therapy',
      'certifiedTherapists': 'Certified Therapists',
      'licensedMentalHealthProfessionals':
          'Licensed mental health professionals',
      'flexibleScheduling': 'Flexible Scheduling',
      'bookSessionsAtYourConvenience': 'Book sessions at your convenience',
      'oneOnOneSessions': '1-on-1 Sessions',
      'privateConfidentialTherapySessions':
          'Private, confidential therapy sessions',

      // Home
      'welcomeBack': 'Welcome back,',
      'yourSafeSpaceForHealing': 'Your safe space for healing',
      'emergencyHelp': 'SOS - Emergency Help',
      'getImmediateSupport': 'Get immediate support',
      'emergencyCall': 'Emergency Call',
      'wouldYouLikeToCallEmergencyServicesNow':
          'Would you like to call emergency services now?',
      'callNow': 'Call Now',
      'exploreServices': 'Explore Services',
      'recentPosts': 'Recent Posts',
      'viewAll': 'View All',
      'quickActions': 'Quick Actions',

      // Home - Mood tracking
      'howAreYouFeelingToday': 'How are you feeling today?',
      'great': 'Great',
      'good': 'Good',
      'okay': 'Okay',
      'sad': 'Sad',
      'bad': 'Bad',

      // Home - Resources
      'resources': 'Resources',
      'selfCareTips': 'Self-Care Tips',
      'dailyWellnessPractices': 'Daily wellness practices',
      'safetyPlanning': 'Safety Planning',
      'personalSafetyResources': 'Personal safety resources',
      'crisisSupport': 'Crisis Support',
      'helplineNumbers': '24/7 helpline numbers',
      'educationalContent': 'Educational Content',
      'learnAboutHealing': 'Learn about healing',
    },
    'French': {
      // Transaction ID dialog
      'confirmYourPayment': 'Confirmez Votre Paiement',
      'pleaseEnterTheFinancialTransactionId':
          'Veuillez saisir l\'ID de transaction financière de votre message de confirmation de paiement MTN',
      'pleaseWaitForOurTeamToConfirmYourTransaction':
          'Veuillez patienter pendant que notre équipe confirme votre transaction. Cela prend généralement moins de 10 minutes pendant les heures de bureau.',
      'confirmAndSubmit': 'Confirmer et Soumettre',
      'transactionIdSubmittedSuccessfully':
          'ID de transaction soumis avec succès. Notre équipe vérifiera et activera votre compte sous peu.',
      'pleaseEnterTransactionId': 'Veuillez saisir un ID de transaction valide',

      // Settings
      'settings': 'Paramètres',
      'darkMode': 'Mode Sombre',
      'language': 'Langue',
      'selectLanguage': 'Choisir la Langue',
      'cancel': 'Annuler',
      'searchSettings': 'Rechercher dans les Paramètres',
      'selectFontFamily': 'Sélectionner la Police',
      'selectFontSize': 'Sélectionner la Taille de Police',
      'languageAudio': 'Langue & Audio',
      'chooseLanguageDescription': 'Choisissez votre langue préférée',
      'chooseFontFamilyDescription': 'Choisissez une police confortable à lire',
      'fontSizeFollowsSystem':
          'La taille du texte suit les réglages d\'accessibilité de votre appareil.',
      'database': 'Base de Données',
      'contentPolicyReporting': 'Politique de Contenu & Signalement',
      'adminControls': 'Contrôles Administrateur',
      'lowDataMode': 'Mode Données Réduites',
      'imageLazyLoading': 'Chargement Différé des Images',
      'offlineMode': 'Mode Hors Ligne',

      // Navigation
      'home': 'Accueil',
      'forum': 'Forum',
      'mahoro': 'Mahoro',
      'muganga': 'Muganga',

      // Accessibility
      'accessibility': 'Accessibilité',
      'fontFamily': 'Police d\'écriture',
      'fontSize': 'Taille de Police',
      'highContrastMode': 'Mode Contraste Élevé',
      'reduceMotion': 'Réduire les Animations',
      'textToSpeech': 'Synthèse Vocale',
      'voiceToText': 'Reconnaissance Vocale',

      // Appearance
      'appearance': 'Apparence',

      // Notifications
      'notifications': 'Notifications',
      'forumReplies': 'Réponses du Forum',
      'weeklyCheckIns': 'Vérifications Hebdomadaires',
      'systemUpdates': 'Mises à Jour Système',

      // Privacy & Security
      'privacySecurity': 'Confidentialité & Sécurité',
      'emergencyContacts': 'Contacts d\'Urgence',
      'logout': 'Déconnexion',
      'signIn': 'Connexion',
      'editProfile': 'Modifier le Profil',

      // Forum
      'safeSpaceToShare': 'Espace sûr pour partager',
      'noPostsYet': 'Pas encore de publications',
      'beTheFirstToStartConversation':
          'Soyez le premier à démarrer une conversation',
      'createPost': 'Créer une Publication',
      'joinTheConvo': 'Rejoindre la Conversation',
      'search': 'Rechercher',
      'searchPosts': 'Rechercher des publications...',
      'likes': 'J\'aime',
      'replies': 'Réponses',
      'reply': 'Répondre',
      'anonymous': 'Anonyme',
      'postTitle': 'Titre de la Publication',
      'postContent': 'Contenu de la Publication',
      'post': 'Publier',

      // Mahoro
      'yourSupportCompanion': 'Votre compagnon de soutien 24/7',
      'typeMessage': 'Tapez un message...',
      'send': 'Envoyer',
      'talkToMahoro': 'Parler à Mahoro',

      // Muganga
      'mugangaTherapy': 'Thérapie Muganga',
      'professionalMentalHealthSupport':
          'Soutien professionnel en santé mentale',
      'monthlySubscription': 'Abonnement Mensuel',
      '2000RWF': '2 000 RWF',
      'unlimitedTherapySessionsWithCertifiedProfessionals':
          'Sessions de thérapie illimitées avec des professionnels certifiés',
      'subscribeNow': 'S\'abonner Maintenant',
      'mtnMobileMoneyPayment': 'Paiement par MTN Mobile Money',
      'payWithMtnMobileMoney': 'Payez avec MTN Mobile Money',
      'dialTheFollowingUssdCodeOnYourMtnPhone':
          'Composez le code USSD suivant sur votre téléphone MTN:',
      'ussdCode': '*182*1*1*0780332779*2000#',
      'afterPaymentYouWillReceive': 'Après le paiement, vous recevrez:',
      'immediateConfirmationMessage': 'Message de confirmation immédiat',
      'paymentReceiptFromOurTeam': 'Reçu de paiement de notre équipe',
      'accessToTherapyBooking': 'Accès à la réservation de thérapie',
      'note': 'Note:',
      'paymentGoesDirectlyToOurTeamAt250780332779TheNumberIsRegisteredToAlineIRADUKUNDAOurChiefOperationsOfficerSheWillBeContactingYouAsSoonAsThePaymentIsReceivedForAccountActivation':
          'Le paiement va directement à notre équipe au +250780332779. Le numéro est enregistré au nom d\'Aline IRADUKUNDA, notre directrice des opérations. Elle vous contactera dès que le paiement sera reçu pour l\'activation du compte.',
      'iveMadeThePayment': 'J\'ai Effectué le Paiement',
      'payEasilyWithMtnMobileMoneyAndGetInstantAccessToProfessionalTherapy':
          'Payez facilement avec MTN Mobile Money et obtenez un accès instantané à une thérapie professionnelle',
      'certifiedTherapists': 'Thérapeutes Certifiés',
      'licensedMentalHealthProfessionals':
          'Professionnels de la santé mentale agréés',
      'flexibleScheduling': 'Horaires Flexibles',
      'bookSessionsAtYourConvenience':
          'Réservez des séances à votre convenance',
      'oneOnOneSessions': 'Sessions Individuelles',
      'privateConfidentialTherapySessions':
          'Sessions de thérapie privées et confidentielles',

      // Home
      'welcomeBack': 'Bienvenue,',
      'yourSafeSpaceForHealing': 'Votre espace sécurisé pour guérir',
      'emergencyHelp': 'SOS - Aide d\'Urgence',
      'getImmediateSupport': 'Obtenir une aide immédiate',
      'emergencyCall': 'Appel d\'Urgence',
      'wouldYouLikeToCallEmergencyServicesNow':
          'Voulez-vous appeler les services d\'urgence maintenant?',
      'callNow': 'Appeler Maintenant',
      'exploreServices': 'Explorer les Services',
      'recentPosts': 'Publications Récentes',
      'viewAll': 'Voir Tout',
      'quickActions': 'Actions Rapides',

      // Home - Mood tracking
      'howAreYouFeelingToday': 'Comment vous sentez-vous aujourd\'hui?',
      'great': 'Excellent',
      'good': 'Bien',
      'okay': 'Correct',
      'sad': 'Triste',
      'bad': 'Mal',

      // Home - Resources
      'resources': 'Ressources',
      'selfCareTips': 'Conseils d\'Auto-Soins',
      'dailyWellnessPractices': 'Pratiques quotidiennes de bien-être',
      'safetyPlanning': 'Planification de Sécurité',
      'personalSafetyResources': 'Ressources de sécurité personnelle',
      'crisisSupport': 'Soutien en Crise',
      'helplineNumbers': 'Numéros d\'assistance 24/7',
      'educationalContent': 'Contenu Éducatif',
      'learnAboutHealing': 'Apprendre sur la guérison',
    },
    'Swahili': {
      // Transaction ID dialog
      'confirmYourPayment': 'Thibitisha Malipo Yako',
      'pleaseEnterTheFinancialTransactionId':
          'Tafadhali ingiza Kitambulisho cha Shughuli ya Fedha kutoka ujumbe wako wa uthibitisho wa malipo wa MTN',
      'pleaseWaitForOurTeamToConfirmYourTransaction':
          'Tafadhali subiri timu yetu ithibitishe muamala wako. Hii kwa kawaida huchukua chini ya dakika 10 wakati wa saa za kazi.',
      'confirmAndSubmit': 'Thibitisha na Wasilisha',
      'transactionIdSubmittedSuccessfully':
          'Kitambulisho cha muamala kimewasilishwa kwa mafanikio. Timu yetu itathibitisha na kuamilisha akaunti yako hivi karibuni.',
      'pleaseEnterTransactionId':
          'Tafadhali ingiza Kitambulisho cha Muamala halali',

      // Settings
      'settings': 'Mipangilio',
      'darkMode': 'Hali ya Giza',
      'language': 'Lugha',
      'selectLanguage': 'Chagua Lugha',
      'cancel': 'Ghairi',
      'searchSettings': 'Tafuta Mipangilio',
      'selectFontFamily': 'Chagua Aina ya Fonti',
      'selectFontSize': 'Chagua Ukubwa wa Fonti',
      'languageAudio': 'Lugha na Sauti',
      'chooseLanguageDescription': 'Chagua lugha unayoipendelea',
      'chooseFontFamilyDescription':
          'Chagua aina ya maandishi inayosomeka vizuri',
      'fontSizeFollowsSystem':
          'Ukubwa wa maandishi unafuata mpangilio wa kifaa chako.',
      'database': 'Hifadhidata',
      'contentPolicyReporting': 'Sera ya Maudhui na Kuripoti',
      'adminControls': 'Vifaa vya Msimamizi',
      'lowDataMode': 'Hali ya Data Ndogo',
      'imageLazyLoading': 'Upakiaji wa Polepole wa Picha',
      'offlineMode': 'Hali ya Nje ya Mtandao',

      // Navigation
      'home': 'Nyumbani',
      'forum': 'Jukwaa',
      'mahoro': 'Mahoro',
      'muganga': 'Muganga',

      // Accessibility
      'accessibility': 'Ufikiaji',
      'fontFamily': 'Familia ya Fonti',
      'fontSize': 'Ukubwa wa Fonti',
      'highContrastMode': 'Hali ya Tofauti ya Juu',
      'reduceMotion': 'Punguza Mwendo',
      'textToSpeech': 'Maandishi hadi Usemi',
      'voiceToText': 'Sauti hadi Maandishi',

      // Appearance
      'appearance': 'Mwonekano',

      // Notifications
      'notifications': 'Arifa',
      'forumReplies': 'Majibu ya Jukwaa',
      'weeklyCheckIns': 'Ukaguzi wa Kila Wiki',
      'systemUpdates': 'Masasisho ya Mfumo',

      // Privacy & Security
      'privacySecurity': 'Faragha na Usalama',
      'emergencyContacts': 'Anwani za Dharura',
      'logout': 'Toka',
      'signIn': 'Ingia',
      'editProfile': 'Hariri Wasifu',

      // Forum
      'safeSpaceToShare': 'Nafasi salama ya kushiriki',
      'noPostsYet': 'Hakuna machapisho bado',
      'beTheFirstToStartConversation': 'Kuwa wa kwanza kuanza mazungumzo',
      'createPost': 'Unda Chapisho',
      'joinTheConvo': 'Jiunge na Mazungumzo',
      'search': 'Tafuta',
      'searchPosts': 'Tafuta machapisho...',
      'likes': 'Penda',
      'replies': 'Majibu',
      'reply': 'Jibu',
      'anonymous': 'Bila jina',
      'postTitle': 'Kichwa cha Chapisho',
      'postContent': 'Maudhui ya Chapisho',
      'post': 'Chapisha',

      // Mahoro
      'yourSupportCompanion': 'Msaidizi wako wa kila wakati',
      'typeMessage': 'Andika ujumbe...',
      'send': 'Tuma',
      'talkToMahoro': 'Ongea na Mahoro',

      // Muganga
      'mugangaTherapy': 'Tiba ya Muganga',
      'professionalMentalHealthSupport': 'Msaada wa kitaalamu wa afya ya akili',
      'monthlySubscription': 'Usajili wa Kila Mwezi',
      '2000RWF': 'RWF 2,000',
      'unlimitedTherapySessionsWithCertifiedProfessionals':
          'Vikao vya tiba visivyo na kikomo na wataalamu wenye vyeti',
      'subscribeNow': 'Jiandikishe Sasa',
      'mtnMobileMoneyPayment': 'Malipo ya MTN Mobile Money',
      'payWithMtnMobileMoney': 'Ishyura na MTN Mobile Money',
      'dialTheFollowingUssdCodeOnYourMtnPhone':
          'Piga namba ifuatayo ya USSD kwenye simu yako ya MTN:',
      'ussdCode': '*182*1*1*0780332779*2000#',
      'afterPaymentYouWillReceive': 'Baada ya malipo, utapokea:',
      'immediateConfirmationMessage': 'Ujumbe wa uthibitisho wa haraka',
      'paymentReceiptFromOurTeam': 'Risiti ya malipo kutoka kwa timu yetu',
      'accessToTherapyBooking': 'Ufikiaji wa kuhifadhi tiba',
      'note': 'Kumbuka:',
      'paymentGoesDirectlyToOurTeamAt250780332779TheNumberIsRegisteredToAlineIRADUKUNDAOurChiefOperationsOfficerSheWillBeContactingYouAsSoonAsThePaymentIsReceivedForAccountActivation':
          'Malipo huenda moja kwa moja kwa timu yetu kwenye +250780332779. Namba imesajiliwa kwa Aline IRADUKUNDA, Afisa Mkuu wa Uendeshaji. Atakuwa akiwasiliana nawe mara tu malipo yatakapopokelewa kwa uanzishaji wa akaunti.',
      'iveMadeThePayment': 'Nimefanya Malipo',
      'payEasilyWithMtnMobileMoneyAndGetInstantAccessToProfessionalTherapy':
          'Ishyura byoroshye na MTN Mobile Money kandi ubone ubufasha bw\'inzobere ako kanya',
      'certifiedTherapists': 'Wataalamu Wenye Vyeti',
      'licensedMentalHealthProfessionals':
          'Wataalamu wa afya ya akili wenye leseni',
      'flexibleScheduling': 'Ratiba Rahisi',
      'bookSessionsAtYourConvenience': 'Weka vikao kwa urahisi wako',
      'oneOnOneSessions': 'Vikao vya Mtu kwa Mtu',
      'privateConfidentialTherapySessions':
          'Vikao vya tiba vya faragha na siri',

      // Home
      'welcomeBack': 'Karibu tena,',
      'yourSafeSpaceForHealing': 'Nafasi yako salama ya kupona',
      'emergencyHelp': 'SOS - Msaada wa Dharura',
      'getImmediateSupport': 'Pata msaada wa haraka',
      'emergencyCall': 'Simu ya Dharura',
      'wouldYouLikeToCallEmergencyServicesNow':
          'Ungependa kupiga simu kwa huduma za dharura sasa?',
      'callNow': 'Piga Simu Sasa',
      'exploreServices': 'Chunguza Huduma',
      'recentPosts': 'Machapisho ya Hivi Karibuni',
      'viewAll': 'Ona Yote',
      'quickActions': 'Vitendo vya Haraka',

      // Home - Mood tracking
      'howAreYouFeelingToday': 'Unajisikiaje leo?',
      'great': 'Vizuri Sana',
      'good': 'Vizuri',
      'okay': 'Kawaida',
      'sad': 'Huzuni',
      'bad': 'Vibaya',

      // Home - Resources
      'resources': 'Rasilimali',
      'selfCareTips': 'Vidokezo vya Kujitunza',
      'dailyWellnessPractices': 'Mazoezi ya kila siku ya afya',
      'safetyPlanning': 'Mpango wa Usalama',
      'personalSafetyResources': 'Rasilimali za usalama binafsi',
      'crisisSupport': 'Msaada wa Dharura',
      'helplineNumbers': 'Nambari za simu za msaada 24/7',
      'educationalContent': 'Maudhui ya Elimu',
      'learnAboutHealing': 'Jifunze kuhusu uponyaji',
    },
    'Kinyarwanda': {
      // Transaction ID dialog
      'confirmYourPayment': 'Emeza Ubwishyu Bwawe',
      'pleaseEnterTheFinancialTransactionId':
          'Nyamuneka andika Nomero y\'Ubwishyu (Transaction ID) ivuye mu butumwa bwo kwemeza ubwishyu bwa MTN',
      'pleaseWaitForOurTeamToConfirmYourTransaction':
          'Nyamuneka tegereza ikipe yacu kugira ngo yemeze ubwishyu bwawe. Ibi bisanzwe bifata munsi y\'iminota 10 mu masaha y\'akazi.',
      'confirmAndSubmit': 'Emeza & Ohereza',
      'transactionIdSubmittedSuccessfully':
          'Nomero y\'Ubwishyu yoherejwe neza. Ikipe yacu izabyemeza kandi ikore konti yawe vuba.',
      'pleaseEnterTransactionId':
          'Nyamuneka andika Nomero y\'Ubwishyu ifite agaciro',

      // Settings
      'settings': 'Igenamiterere',
      'darkMode': 'Ibara y\'Umukara',
      'language': 'Ururimi',
      'selectLanguage': 'Hitamo Ururimi',
      'cancel': 'Kureka',
      'searchSettings': 'Shakisha Igenamiterere',
      'selectFontFamily': 'Hitamo Ubwoko bw\'Imyandikire',
      'selectFontSize': 'Hitamo Ingano y\'Imyandikire',
      'languageAudio': 'Ururimi & Ijwi',
      'chooseLanguageDescription': 'Hitamo ururimi wumva neza',
      'chooseFontFamilyDescription':
          'Hitamo imisusire y\'inyuguti yoroshye gusoma',
      'fontSizeFollowsSystem':
          'Ingano y\'inyuguti ikurikira igenamiterere rya telefone yawe.',
      'database': 'Ububiko bw\'Itangazamakuru',
      'contentPolicyReporting': 'Politiki y\'Ibikubiyemo n\'Itangazwa',
      'adminControls': 'Igenzura ry\'Abayobozi',
      'lowDataMode': 'Uburyo bwa Data Nkeya',
      'imageLazyLoading': 'Gutangiza Amashusho Buhoro',
      'offlineMode': 'Uburyo bwo Hanze y\'Umurongo',

      // Navigation
      'home': 'Ahabanza',
      'forum': 'Ihuriro',
      'mahoro': 'Mahoro',
      'muganga': 'Muganga',

      // Accessibility
      'accessibility': 'Ubushobozi bwo Kugera',
      'fontFamily': 'Umuryango w\'Imyandikire',
      'fontSize': 'Ingano y\'Imyandikire',
      'highContrastMode': 'Uburyo bw\'Itandukaniro Rikomeye',
      'reduceMotion': 'Kugabanya Imyitozo',
      'textToSpeech': 'Umwandiko ujya mu Mvugo',
      'voiceToText': 'Ijwi rijya mu Mwandiko',

      // Appearance
      'appearance': 'Imiterere',

      // Notifications
      'notifications': 'Imenyesha',
      'forumReplies': 'Ibisubizo by\'Ihuriro',
      'weeklyCheckIns': 'Isuzuma rya buri Cyumweru',
      'systemUpdates': 'Ivugururwa rya Sisitemu',

      // Privacy & Security
      'privacySecurity': 'Ubuzima Bwite n\'Umutekano',
      'emergencyContacts': 'Aho Wahamagara mu Bihe Bikomeye',
      'logout': 'Gusohoka',
      'signIn': 'Kwinjira',
      'editProfile': 'Guhindura Umwirondoro',

      // Forum
      'safeSpaceToShare': 'Umwanya utekanye wo gusangira',
      'noPostsYet': 'Nta nyandiko ziriho',
      'beTheFirstToStartConversation': 'Ba uwambere utangiza ikiganiro',
      'createPost': 'Kora Inyandiko',
      'joinTheConvo': 'Injira mu Ntungane',
      'search': 'Gushakisha',
      'searchPosts': 'Shakisha inyandiko...',
      'likes': 'Bikunda',
      'replies': 'Ibisubizo',
      'reply': 'Subiza',
      'anonymous': 'Ntamwirondoro',
      'postTitle': 'Umutwe w\'Inyandiko',
      'postContent': 'Ibikubiye mu Nyandiko',
      'post': 'Ohereza',

      // Mahoro
      'yourSupportCompanion': 'Umufasha wawe w\'igihe cyose',
      'typeMessage': 'Andika ubutumwa...',
      'send': 'Ohereza',
      'talkToMahoro': 'Vugana na Mahoro',

      // Muganga
      'mugangaTherapy': 'Ubuvuzi bwa Muganga',
      'professionalMentalHealthSupport':
          'Ubufasha bw\'inzobere mu buzima bwo mu mutwe',
      'monthlySubscription': 'Kwiyandikisha kwa Buri Kwezi',
      '2000RWF': 'RWF 2,000',
      'unlimitedTherapySessionsWithCertifiedProfessionals':
          'Amasaha y\'ubuvuzi adafite umupaka n\'impuguke zemewe',
      'subscribeNow': 'Iyandikishe Nonaha',
      'mtnMobileMoneyPayment': 'Kwishyura na MTN Mobile Money',
      'payWithMtnMobileMoney': 'Ishyura na MTN Mobile Money',
      'dialTheFollowingUssdCodeOnYourMtnPhone':
          'Kanda kode ya USSD ikurikira kuri telefoni yawe ya MTN:',
      'ussdCode': '*182*1*1*0780332779*2000#',
      'afterPaymentYouWillReceive': 'Nyuma yo kwishyura, uzakira:',
      'immediateConfirmationMessage': 'Ubutumwa bwo kwemeza ako kanya',
      'paymentReceiptFromOurTeam':
          'Inyemezabuguzi yo kwishyura ivuye mu ikipe yacu',
      'accessToTherapyBooking': 'Uburenganzira bwo kwiyandikisha ku buvuzi',
      'note': 'Icyitonderwa:',
      'paymentGoesDirectlyToOurTeamAt250780332779TheNumberIsRegisteredToAlineIRADUKUNDAOurChiefOperationsOfficerSheWillBeContactingYouAsSoonAsThePaymentIsReceivedForAccountActivation':
          'Amafaranga ajya ku ikipe yacu kuri +250780332779. Nimero yanditswe kuri Aline IRADUKUNDA, Umuyobozi w\'Ibikorwa. Azakuvugisha vuba nyuma y\'uko amafaranga yakiriwe kugira ngo akore konti yawe.',
      'iveMadeThePayment': 'Nakoze Ubwishyu',
      'payEasilyWithMtnMobileMoneyAndGetInstantAccessToProfessionalTherapy':
          'Ishyura byoroshye na MTN Mobile Money kandi ubone ubufasha bw\'inzobere ako kanya',
      'certifiedTherapists': 'Abavuzi Bemewe',
      'licensedMentalHealthProfessionals':
          'Inzobere mu buzima bwo mu mutwe zifite impushya',
      'flexibleScheduling': 'Gahunda Yoroshye',
      'bookSessionsAtYourConvenience': 'Iyandikishe ku masaha bikugoye',
      'oneOnOneSessions': 'Amasaha y\'Umuntu ku Muntu',
      'privateConfidentialTherapySessions':
          'Amasaha y\'ubuvuzi yihariye kandi afite ibanga',

      // Home
      'welcomeBack': 'Murakaza neza,',
      'yourSafeSpaceForHealing': 'Umwanya wawe utekanye wo gukira',
      'emergencyHelp': 'SOS - Ubufasha Bwihutirwa',
      'getImmediateSupport': 'Bona ubufasha bwihuse',
      'emergencyCall': 'Guhamagara Byihutirwa',
      'wouldYouLikeToCallEmergencyServicesNow':
          'Urifuza guhamagara serivisi z\'ubutabazi ubu?',
      'callNow': 'Hamagara Ubu',
      'exploreServices': 'Reba Serivisi',
      'recentPosts': 'Inyandiko za Vuba',
      'viewAll': 'Reba Byose',
      'quickActions': 'Ibikorwa Byihuse',

      // Home - Mood tracking
      'howAreYouFeelingToday': 'Umerewe ute uyu munsi?',
      'great': 'Neza Cyane',
      'good': 'Neza',
      'okay': 'Biraringaniye',
      'sad': 'Mbi',
      'bad': 'Bibi Cyane',

      // Home - Resources
      'resources': 'Ibikoresho',
      'selfCareTips': 'Inama zo Kwita ku Buzima',
      'dailyWellnessPractices': 'Imyitozo ya buri munsi yo kwita ku buzima',
      'safetyPlanning': 'Gahunda yo Kurinda Umutekano',
      'personalSafetyResources': 'Ibikoresho by\'umutekano bwite',
      'crisisSupport': 'Gufasha mu Bihe Bikomeye',
      'helplineNumbers': 'Nimero za telefoni z\'ubufasha 24/7',
      'educationalContent': 'Ibigisha',
      'learnAboutHealing': 'Kwiga ku bijyanye no gukira',
    },
  };

  String translate(String key) {
    // Return translation if available, otherwise return the key itself
    return _localizedValues[locale]?[key] ??
        _localizedValues['English']?[key] ??
        key;
  }
}
