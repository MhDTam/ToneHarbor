// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ToneHarbor';

  @override
  String get home => 'الرئيسية';

  @override
  String get library => 'المكتبة';

  @override
  String get convertVideo => 'المحوّل';

  @override
  String get playlists => 'قوائم التشغيل';

  @override
  String get settings => 'الإعدادات';

  @override
  String get nowPlaying => 'قيد التشغيل';

  @override
  String get quickPlaylists => 'قوائم سريعة';

  @override
  String get recentConversions => 'تحويلات حديثة';

  @override
  String get quickVideoConvert => 'تحويل فيديو سريع';

  @override
  String get selectVideo => 'اختيار فيديو';

  @override
  String get converting => 'جارٍ التحويل';

  @override
  String get conversionComplete => 'اكتمل التحويل';

  @override
  String get conversionFailed => 'فشل التحويل';

  @override
  String get sleepTimer => 'مؤقّت النوم';

  @override
  String sleepTimerRemaining(int minutes) {
    return 'متبقي $minutes دقيقة';
  }

  @override
  String get singleTrackMode => 'وضع المسار الواحد';

  @override
  String get play => 'تشغيل';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get next => 'التالي';

  @override
  String get previous => 'السابق';

  @override
  String get shuffle => 'خلط عشوائي';

  @override
  String get repeat => 'تكرار';

  @override
  String get addToPlaylist => 'إضافة إلى قائمة تشغيل';

  @override
  String get createPlaylist => 'إنشاء قائمة تشغيل';

  @override
  String get editPlaylist => 'تعديل قائمة التشغيل';

  @override
  String get deletePlaylist => 'حذف قائمة التشغيل';

  @override
  String get renamePlaylist => 'إعادة تسمية القائمة';

  @override
  String get playlistName => 'اسم القائمة';

  @override
  String get noSongsFound => 'لم يتم العثور على أي مقطع';

  @override
  String get noPlaylists => 'لا توجد قوائم تشغيل بعد';

  @override
  String get createFirstPlaylist => 'أنشئ قائمة التشغيل الأولى';

  @override
  String songCount(int count) {
    return '$count مقطع';
  }

  @override
  String get timerOptionTimeAndLock => 'المؤقت + قفل الشاشة';

  @override
  String get timerOptionTrackEnd => 'التوقف عند نهاية المقطع';

  @override
  String get timerOptionTimeOnly => 'المؤقت فقط';

  @override
  String get timerDuration => 'مدة المؤقت';

  @override
  String get minutes => 'دقائق';

  @override
  String get setTimer => 'ضبط المؤقت';

  @override
  String get cancelTimer => 'إلغاء المؤقت';

  @override
  String timerSet(int minutes) {
    return 'تم ضبط مؤقت النوم لمدة $minutes دقيقة';
  }

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get selectLanguagePrompt => 'اختر لغتك المفضّلة للبدء';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get persian => 'الفارسية';

  @override
  String get continueBtn => 'متابعة';

  @override
  String get theme => 'المظهر';

  @override
  String get darkOcean => 'المحيط المظلم';

  @override
  String get desertSand => 'رمال الصحراء';

  @override
  String get aurora => 'الشفق القطبي';

  @override
  String get midnight => 'منتصف الليل';

  @override
  String get lightBreeze => 'نسيم خفيف';

  @override
  String get goldBlack => 'الذهب والأسود';

  @override
  String get language => 'اللغة';

  @override
  String get appearance => 'المظهر';

  @override
  String get about => 'حول التطبيق';

  @override
  String get version => 'الإصدار';

  @override
  String get allSongs => 'جميع المقاطع';

  @override
  String get albums => 'الألبومات';

  @override
  String get artists => 'الفنانون';

  @override
  String get searchSongs => 'البحث عن مقاطع...';

  @override
  String get permissionRequired => 'يتطلب إذن الوصول';

  @override
  String get permissionMessage =>
      'يحتاج التطبيق إلى إذن الوصول للتخزين للوصول إلى ملفات الموسيقى.';

  @override
  String get grantPermission => 'منح الإذن';

  @override
  String get noConversions => 'لا توجد تحويلات بعد';

  @override
  String get convertFirst => 'قم بتحويل فيديو للبدء';

  @override
  String get outputAudio => 'المخرج الصوتي';

  @override
  String get sourceVideo => 'الفيديو المصدر';

  @override
  String get fileSize => 'حجم الملف';

  @override
  String get setAsRingtone => 'تعيين كنغمة رنين';

  @override
  String get ringtoneSetSuccess => 'تم تعيين نغمة الرنين بنجاح';

  @override
  String get share => 'مشاركة';

  @override
  String get themeGoldBlack => 'ذهبي أسود';

  @override
  String get themeGreenGrey => 'رمادي أخضر';

  @override
  String get themeWarmBrown => 'بني دافئ';

  @override
  String get themeQuran => 'قرآني';

  @override
  String get themeAshura => 'عاشورائي';

  @override
  String get themeMuharram => 'محرم';

  @override
  String get themeHussaini => 'حسيني';

  @override
  String get themeRamadan => 'رمضاني';

  @override
  String get themeBlueSky => 'سماء زرقاء';

  @override
  String get themeRoyalRed => 'محرم';

  @override
  String get themeEmeraldGold => 'زمرد وذهب';

  @override
  String get themeLavender => 'خزامى هادئ';

  @override
  String get themeCrescentTeal => 'فيروزي هلالي';

  @override
  String get themeRoyalCrimson => 'أحمر ملكي';

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get deleteConfirmTitle => 'حذف قائمة التشغيل';

  @override
  String deleteConfirmMessage(String name) {
    return 'هل أنت متأكد أنك تريد حذف \"$name\"؟';
  }

  @override
  String get addSongs => 'إضافة مقاطع';

  @override
  String get removeSong => 'إزالة المقطع';

  @override
  String get playAll => 'تشغيل الكل';

  @override
  String get shuffleAll => 'خلط الكل';

  @override
  String get like => 'إعجاب';

  @override
  String get unlike => 'إلغاء الإعجاب';

  @override
  String get unknown => 'غير معروف';

  @override
  String get unknownArtist => 'فنان مجهول';

  @override
  String get unknownAlbum => 'ألبوم مجهول';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get title => 'العنوان';

  @override
  String get artist => 'الفنان';

  @override
  String get duration => 'المدة';

  @override
  String get dateAdded => 'تاريخ الإضافة';

  @override
  String get renameFile => 'إعادة تسمية الملف';

  @override
  String get enterNewName => 'أدخل الاسم الجديد...';

  @override
  String get trimAudio => 'قص الصوت';

  @override
  String get loadingWaveform => 'جارٍ تحميل الموجة الصوتية...';

  @override
  String get volume => 'مستوى الصوت';

  @override
  String get highVolumeWarning => 'مستوى الصوت المرتفع قد يسبب تشويشاً';

  @override
  String get fadeEffects => 'تأثيرات التلاشي';

  @override
  String get fadeIn => 'ظهور تدريجي';

  @override
  String get fadeOut => 'تلاشي تدريجي';

  @override
  String get eightDAudio => 'تأثير الصوت ثماني الأبعاد';

  @override
  String get eightDDescription => 'يُنشئ صوتاً مكانياً يدور حولك';

  @override
  String get rotationSpeed => 'سرعة الدوران';

  @override
  String get speedSlow => 'بطيء';

  @override
  String get speedNormal => 'عادي';

  @override
  String get speedFast => 'سريع';

  @override
  String get effectIntensity => 'شدة التأثير';

  @override
  String get reverbDepth => 'أجواء المكان (صدى)';

  @override
  String get reverbSmall => 'استوديو صغير';

  @override
  String get reverbMedium => 'قاعة حفلات';

  @override
  String get reverbLarge => 'مسرح كبير';

  @override
  String get previewEffect => 'معاينة التأثير';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get generatingPreview => 'جارٍ إنشاء معاينة عالية الجودة...';

  @override
  String get processing => 'جارٍ المعالجة...';

  @override
  String get savingAudio => 'جارٍ حفظ الصوت...';

  @override
  String get audioSavedSuccess => 'تم حفظ الصوت بنجاح';

  @override
  String get audioSavedError => 'حدث خطأ أثناء حفظ الصوت';

  @override
  String get extractingVideoInfo => 'جارٍ استخراج معلومات الفيديو...';

  @override
  String get conversionCancelled => 'تم إلغاء التحويل';

  @override
  String get startingConversion => 'جارٍ بدء التحويل...';

  @override
  String get allFilesPermissionContent =>
      'لحفظ الملفات المحوّلة في مجلد الموسيقى العام، يحتاج التطبيق إلى صلاحية \"الوصول إلى جميع الملفات\".\n\nهل تريد فتح الإعدادات لمنح هذا الإذن؟';

  @override
  String get later => 'لاحقاً';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get selectFormat => 'اختيار الصيغة';

  @override
  String get conversionDone => 'اكتمل التحويل!';

  @override
  String savedAs(String filename) {
    return 'تم الحفظ باسم: $filename';
  }

  @override
  String get editMetadata => 'تعديل البيانات الوصفية';

  @override
  String get trackTitle => 'عنوان المقطع';

  @override
  String get artistName => 'اسم الفنان';

  @override
  String get albumTitle => 'اسم الألبوم';

  @override
  String get saveMetadata => 'حفظ البيانات الوصفية';

  @override
  String get outputName => 'اسم الملف الناتج';

  @override
  String get enterOutputFilename => 'أدخل اسم الملف الناتج...';

  @override
  String get format => 'الصيغة';

  @override
  String get pleaseWaitMoment => 'يرجى الانتظار، قد يستغرق هذا لحظة';

  @override
  String get permissionExplanation =>
      'لحفظ الملفات المحوّلة في مجلد الموسيقى العام، يحتاج التطبيق إلى صلاحية \"الوصول إلى جميع الملفات\".\n\nهل تريد فتح الإعدادات لمنح هذا الإذن؟';

  @override
  String get processed => 'تمت المعالجة';

  @override
  String get failedToSave => 'تم التحويل ولكن فشل الحفظ في مجلد الموسيقى.';

  @override
  String get selectDifferentVideo => 'اختيار فيديو آخر';

  @override
  String get convertToAudio => 'تحويل إلى صوت';

  @override
  String get editInfo => 'تعديل المعلومات';

  @override
  String get save => 'حفظ';

  @override
  String get changeCover => 'تغيير الغلاف';

  @override
  String get savingChanges => 'جارٍ حفظ التغييرات...';

  @override
  String get failedPickImage => 'فشل اختيار الصورة';

  @override
  String get titleEmptyError => 'لا يمكن ترك العنوان فارغاً';

  @override
  String get editAudio => 'تعديل الصوت';

  @override
  String get previewGenerationFailed => 'فشل إنشاء المعاينة.';

  @override
  String get processingFailed => 'فشلت المعالجة.';

  @override
  String get failed => 'فشل';

  @override
  String get error => 'خطأ';

  @override
  String get editing => 'محرر الصوت';

  @override
  String get history => 'السجل';

  @override
  String get tools => 'الأدوات';

  @override
  String get convertVideoToAudio => 'تحويل الفيديو إلى صوت';

  @override
  String get noHistoryYet => 'لا يوجد سجل بعد';

  @override
  String get extractionComplete => 'اكتمل استخراج الصوت';

  @override
  String get savedTo => 'تم الحفظ في';

  @override
  String get convertAnother => 'تحويل آخر';

  @override
  String get chooseVideoToStart => 'اختر فيديو للبدء';

  @override
  String get toggleFavorite => 'تبديل المفضّلة';

  @override
  String get favorites => 'المفضّلة';

  @override
  String get addAudioToEdit => 'إضافة مقطع صوتي للتعديل';

  @override
  String get selectFromLibrary => 'اختيار من المكتبة';

  @override
  String get removeFromLibrary => 'إزالة من المكتبة';

  @override
  String get deletePermanently => 'حذف نهائي';

  @override
  String get showInFolder => 'عرض في المجلد';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get clear => 'مسح التحديد';

  @override
  String selected(int count) {
    return '$count محدد';
  }

  @override
  String get addMusicFolder => 'إضافة مجلد موسيقى';

  @override
  String get addAudioFile => 'إضافة ملف صوتي';

  @override
  String get mediaAdded => 'تمت إضافة الوسائط! جارٍ الفحص...';

  @override
  String get filesAdded => 'تمت إضافة الملفات!';

  @override
  String get renameSong => 'إعادة تسمية المقطع';

  @override
  String get editInfoTitleArt => 'تعديل المعلومات (العنوان، الغلاف...)';

  @override
  String get editAudioTrim8D => 'تعديل الصوت (قص، 8D)';

  @override
  String get noResults => 'لم يتم العثور على نتائج';

  @override
  String get placeMusicFolder => 'ضع ملفات الصوت في مجلد الموسيقى';

  @override
  String get songRenamed => 'تمت إعادة تسمية المقطع بنجاح';

  @override
  String get renameFailed => 'فشلت إعادة التسمية';

  @override
  String get songDeleted => 'تم حذف المقطع بنجاح';

  @override
  String get deleteFailed => 'فشل الحذف';

  @override
  String get songRemoved => 'تمت إزالة المقطع من المكتبة';

  @override
  String removedItems(int count) {
    return 'تمت إزالة $count عنصر من المكتبة';
  }

  @override
  String deletedItems(int count) {
    return 'تم حذف $count عنصر نهائياً';
  }

  @override
  String addedToPlaylist(String name) {
    return 'تمت الإضافة إلى $name';
  }

  @override
  String get alreadyInPlaylist => 'موجود بالفعل في القائمة';

  @override
  String get noPlaylistsCreate => 'لا توجد قوائم تشغيل. أنشئ واحدة أولاً!';

  @override
  String get removeFromLibraryTitle => 'إزالة من المكتبة؟';

  @override
  String get removeFromLibraryMsg =>
      'إخفاء هذا المقطع من مكتبتك؟ سيبقى الملف الأصلي على جهازك.';

  @override
  String get deleteTitle => 'حذف نهائي؟';

  @override
  String get deleteMsg =>
      'هل أنت متأكد أنك تريد حذف هذا نهائياً من جهازك؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get remove => 'إزالة';

  @override
  String get fileType => 'نوع الملف';

  @override
  String get defaultPlayer => 'المشغّل الافتراضي';

  @override
  String get defaultPlayerMsg => 'هل تريد تعيين ToneHarbor كمشغّل صوت افتراضي؟';

  @override
  String get noThanks => 'لا، شكراً';

  @override
  String get yesOpenSettings => 'نعم، فتح الإعدادات';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get convertVideoBtn => 'تحويل فيديو إلى صوت';

  @override
  String get moreActions => 'مزيد من الإجراءات';

  @override
  String secondsVideo(String seconds) {
    return 'فيديو مدته $seconds ثانية';
  }

  @override
  String get chooseSource => 'اختر المصدر';

  @override
  String get gallery => 'الاستوديو (فيديوهات)';

  @override
  String get files => 'الملفات (فيديو)';

  @override
  String get selectVideoOnly => 'الرجاء اختيار ملف فيديو';

  @override
  String get addToFavorites => 'إضافة إلى المفضلة';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get noSongPlaying => 'لا يوجد مقطع قيد التشغيل';

  @override
  String get back => 'رجوع';

  @override
  String get timer => 'المؤقت';

  @override
  String get single => 'فردي';

  @override
  String get playbackSpeed => 'سرعة التشغيل';

  @override
  String get stopAtTimerEnd => 'التوقف عند نهاية المؤقت';

  @override
  String get stopAtTimerEndSub => 'إيقاف التشغيل بعد X دقيقة';

  @override
  String get stopAtTrackEnd => 'التوقف عند نهاية المقطع';

  @override
  String get stopAtTrackEndSub => 'إيقاف التشغيل عند انتهاء المقطع';

  @override
  String get stopAtPlaylistEnd => 'التوقف عند نهاية القائمة';

  @override
  String get stopAtPlaylistEndSub => 'إيقاف التشغيل عند انتهاء قائمة التشغيل';

  @override
  String get closeAppWhenStopped => 'إغلاق التطبيق عند التوقف';

  @override
  String get slidePicker => 'اسحب لضبط الوقت';

  @override
  String setTimerWithMin(int minutes) {
    return 'ضبط المؤقت ($minutes دقيقة)';
  }

  @override
  String get cancelTimerBtn => 'إلغاء المؤقت';

  @override
  String get startSleepTimer => 'بدء مؤقت النوم';

  @override
  String get track => 'مقطع';

  @override
  String get list => 'قائمة';

  @override
  String get saveAsNewFile => 'حفظ كملف جديد';

  @override
  String get replaceOriginal => 'استبدال الملف الأصلي';

  @override
  String savingProgress(int percent) {
    return 'جارٍ الحفظ: $percent%';
  }

  @override
  String get audioSettings => 'إعدادات الصوت';

  @override
  String get automaticHeadset => 'تلقائي (تفضيل سماعة الرأس)';

  @override
  String get forceSpeaker => 'فرض مكبر الصوت الداخلي';

  @override
  String get forceHeadset => 'فرض سماعة الرأس / البلوتوث';

  @override
  String get dark => 'داكن';

  @override
  String get light => 'فاتح';

  @override
  String get appSlogan => 'مشغّل موسيقى عصري مع محوّل فيديو';

  @override
  String get recentlyPlayed => 'تم تشغيلها مؤخراً';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get songUnavailable => 'الأغنية غير متوفرة';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get noFavoritesYet => 'لا توجد مفضلات بعد';

  @override
  String get closeApp => 'إغلاق التطبيق';

  @override
  String get expandToFullApp => 'فتح التطبيق كاملاً';

  @override
  String get overlaySettings => 'إعدادات النافذة العائمة';

  @override
  String get backgroundBlur => 'تمييع الخلفية';

  @override
  String get resetToDefault => 'إعادة الضبط الافتراصي';

  @override
  String addedSongsToPlaylist(int count, String name) {
    return 'تمت إضافة $count مقطع إلى $name';
  }

  @override
  String get notSupportedPlatform => 'غير مدعوم على هذه المنصة';

  @override
  String get permissionWriteSettings => 'مطلوب إذن لتعديل إعدادات النظام';

  @override
  String get ringtoneFailed => 'فشل تعيين نغمة الرنين';

  @override
  String get pressBackAgainToExit => 'اضغط رجوع مرة أخرى للخروج';

  @override
  String get refreshLibrary => 'تحديث المكتبة';

  @override
  String get storageAndCache => 'التخزين والذاكرة المؤقتة';

  @override
  String get cacheSize => 'حجم الذاكرة المؤقتة';

  @override
  String get clearCache => 'مسح الذاكرة المؤقتة';

  @override
  String get clearCacheSuccess => 'تم مسح الذاكرة المؤقتة بنجاح';

  @override
  String get clearCacheDesc =>
      'حذف الفيديوهات المؤقتة والملفات المخزنة لتحرير المساحة';

  @override
  String get cacheClean => 'الذاكرة المؤقتة نظيفة (0 B)';

  @override
  String get restoreExcludedTitle => 'إضافة مقاطع إلى المكتبة';

  @override
  String get restoreExcludedPromptSingle =>
      'تم العثور على هذا المقطع الذي تمت إزالته من المكتبة سابقاً. هل تريد إضافته مجدداً إلى المكتبة؟';

  @override
  String get restoreExcludedPromptMultiple =>
      'تم العثور على مقاطع تمت إزالتها من المكتبة سابقاً. هل تريد إضافتها مجدداً؟';

  @override
  String get restoreExcludedAction => 'إضافة إلى المكتبة';

  @override
  String get restoreExcludedKeepHidden => 'إبقاء مخفياً';

  @override
  String get deselectAll => 'إلغاء تحديد الكل';

  @override
  String restoredSongsCount(int count) {
    return 'تمت إضافة $count مقطع إلى المكتبة';
  }
}
