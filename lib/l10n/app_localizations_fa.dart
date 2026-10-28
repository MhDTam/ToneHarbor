// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appName => 'ToneHarbor';

  @override
  String get home => 'خانه';

  @override
  String get library => 'کتابخانه';

  @override
  String get convertVideo => 'مبدل';

  @override
  String get playlists => 'لیست‌های پخش';

  @override
  String get settings => 'تنظیمات';

  @override
  String get nowPlaying => 'در حال پخش';

  @override
  String get quickPlaylists => 'لیست‌های سریع';

  @override
  String get recentConversions => 'تبدیل‌های اخیر';

  @override
  String get quickVideoConvert => 'تبدیل سریع ویدیو';

  @override
  String get selectVideo => 'انتخاب ویدیو';

  @override
  String get converting => 'در حال تبدیل';

  @override
  String get conversionComplete => 'تبدیل کامل شد';

  @override
  String get conversionFailed => 'تبدیل ناموفق بود';

  @override
  String get sleepTimer => 'تایمر خواب';

  @override
  String sleepTimerRemaining(int minutes) {
    return '$minutes دقیقه باقی‌مانده';
  }

  @override
  String get singleTrackMode => 'حالت تک آهنگ';

  @override
  String get play => 'پخش';

  @override
  String get pause => 'توقف';

  @override
  String get next => 'بعدی';

  @override
  String get previous => 'قبلی';

  @override
  String get shuffle => 'پخش تصادفی';

  @override
  String get repeat => 'تکرار';

  @override
  String get addToPlaylist => 'افزودن به لیست پخش';

  @override
  String get createPlaylist => 'ایجاد لیست پخش';

  @override
  String get editPlaylist => 'ویرایش لیست پخش';

  @override
  String get deletePlaylist => 'حذف لیست پخش';

  @override
  String get renamePlaylist => 'تغییر نام لیست';

  @override
  String get playlistName => 'نام لیست پخش';

  @override
  String get noSongsFound => 'هیچ آهنگی یافت نشد';

  @override
  String get noPlaylists => 'هنوز لیست پخشی وجود ندارد';

  @override
  String get createFirstPlaylist => 'اولین لیست پخش خود را بسازید';

  @override
  String songCount(int count) {
    return '$count آهنگ';
  }

  @override
  String get timerOptionTimeAndLock => 'تایمر + قفل صفحه';

  @override
  String get timerOptionTrackEnd => 'توقف در پایان آهنگ';

  @override
  String get timerOptionTimeOnly => 'فقط تایمر';

  @override
  String get timerDuration => 'مدت تایمر';

  @override
  String get minutes => 'دقیقه';

  @override
  String get setTimer => 'تنظیم تایمر';

  @override
  String get cancelTimer => 'لغو تایمر';

  @override
  String timerSet(int minutes) {
    return 'تایمر خواب برای $minutes دقیقه تنظیم شد';
  }

  @override
  String get chooseLanguage => 'انتخاب زبان';

  @override
  String get selectLanguagePrompt =>
      'زبان مورد نظر خود را برای شروع انتخاب کنید';

  @override
  String get english => 'انگلیسی';

  @override
  String get arabic => 'عربی';

  @override
  String get persian => 'فارسی';

  @override
  String get continueBtn => 'ادامه';

  @override
  String get theme => 'قالب';

  @override
  String get darkOcean => 'اقیانوس تاریک';

  @override
  String get desertSand => 'شن‌های بیابان';

  @override
  String get aurora => 'شفق قطبی';

  @override
  String get midnight => 'نیمه‌شب';

  @override
  String get lightBreeze => 'نسیم ملایم';

  @override
  String get goldBlack => 'طلایی و مشکی';

  @override
  String get language => 'زبان';

  @override
  String get appearance => 'ظاهر';

  @override
  String get about => 'درباره';

  @override
  String get version => 'نسخه';

  @override
  String get allSongs => 'همه آهنگ‌ها';

  @override
  String get albums => 'آلبوم‌ها';

  @override
  String get artists => 'هنرمندان';

  @override
  String get searchSongs => 'جستجوی آهنگ...';

  @override
  String get permissionRequired => 'مجوز لازم است';

  @override
  String get permissionMessage =>
      'برای دسترسی به فایل‌های موسیقی، مجوز ذخیره‌سازی مورد نیاز است.';

  @override
  String get grantPermission => 'اعطای مجوز';

  @override
  String get noConversions => 'هنوز تبدیلی انجام نشده';

  @override
  String get convertFirst => 'یک ویدیو تبدیل کنید تا شروع کنید';

  @override
  String get outputAudio => 'خروجی صوتی';

  @override
  String get sourceVideo => 'ویدیوی مبدأ';

  @override
  String get fileSize => 'حجم فایل';

  @override
  String get setAsRingtone => 'تنظیم به عنوان آهنگ زنگ';

  @override
  String get ringtoneSetSuccess => 'آهنگ زنگ با موفقیت تنظیم شد';

  @override
  String get share => 'اشتراک‌گذاری';

  @override
  String get themeGoldBlack => 'طلایی مشکی';

  @override
  String get themeGreenGrey => 'سبز خاکستری';

  @override
  String get themeWarmBrown => 'قهوه‌ای گرم';

  @override
  String get themeQuran => 'قرآنی';

  @override
  String get themeAshura => 'عاشورایی';

  @override
  String get themeMuharram => 'محرم';

  @override
  String get themeHussaini => 'حسینی';

  @override
  String get themeRamadan => 'رمضانی';

  @override
  String get themeBlueSky => 'آسمان آبی';

  @override
  String get themeRoyalRed => 'محرم';

  @override
  String get themeEmeraldGold => 'زمرد و طلا';

  @override
  String get themeLavender => 'اسطوخودوس روشن';

  @override
  String get themeCrescentTeal => 'فیروزه هلالی';

  @override
  String get themeRoyalCrimson => 'زرشکی سلطنتی';

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'لغو';

  @override
  String get confirm => 'تأیید';

  @override
  String get deleteConfirmTitle => 'حذف لیست پخش';

  @override
  String deleteConfirmMessage(String name) {
    return 'آیا مطمئن هستید که می‌خواهید \"$name\" را حذف کنید؟';
  }

  @override
  String get addSongs => 'افزودن آهنگ';

  @override
  String get removeSong => 'حذف آهنگ';

  @override
  String get playAll => 'پخش همه';

  @override
  String get shuffleAll => 'پخش تصادفی همه';

  @override
  String get like => 'پسندیدم';

  @override
  String get unlike => 'برداشتن پسند';

  @override
  String get unknown => 'نامشخص';

  @override
  String get unknownArtist => 'هنرمند ناشناس';

  @override
  String get unknownAlbum => 'آلبوم ناشناس';

  @override
  String get sortBy => 'مرتب‌سازی بر اساس';

  @override
  String get title => 'عنوان';

  @override
  String get artist => 'هنرمند';

  @override
  String get duration => 'مدت زمان';

  @override
  String get dateAdded => 'تاریخ افزودن';

  @override
  String get renameFile => 'تغییر نام فایل';

  @override
  String get enterNewName => 'نام جدید را وارد کنید...';

  @override
  String get trimAudio => 'برش صدا';

  @override
  String get loadingWaveform => 'در حال بارگذاری شکل موج...';

  @override
  String get volume => 'حجم صدا';

  @override
  String get highVolumeWarning => 'حجم بالا ممکن است باعث اختلال شود';

  @override
  String get fadeEffects => 'جلوه‌های محو شدن';

  @override
  String get fadeIn => 'ظاهر شدن تدریجی';

  @override
  String get fadeOut => 'محو شدن تدریجی';

  @override
  String get eightDAudio => 'جلوه صدای هشت‌بُعدی';

  @override
  String get eightDDescription => 'صدای فضایی چرخشی ایجاد می‌کند';

  @override
  String get rotationSpeed => 'سرعت چرخش';

  @override
  String get speedSlow => 'آهسته';

  @override
  String get speedNormal => 'عادی';

  @override
  String get speedFast => 'سریع';

  @override
  String get effectIntensity => 'شدت جلوه';

  @override
  String get reverbDepth => 'فضای محیط (بازتاب)';

  @override
  String get reverbSmall => 'استودیوی کوچک';

  @override
  String get reverbMedium => 'سالن کنسرت';

  @override
  String get reverbLarge => 'تئاتر بزرگ';

  @override
  String get previewEffect => 'پیش‌نمایش جلوه';

  @override
  String get saveChanges => 'ذخیره تغییرات';

  @override
  String get generatingPreview => 'در حال ساخت پیش‌نمایش باکیفیت...';

  @override
  String get processing => 'در حال پردازش...';

  @override
  String get savingAudio => 'در حال ذخیره صدا...';

  @override
  String get audioSavedSuccess => 'صدا با موفقیت ذخیره شد';

  @override
  String get audioSavedError => 'خطا در ذخیره صدا';

  @override
  String get extractingVideoInfo => 'در حال استخراج اطلاعات ویدیو...';

  @override
  String get conversionCancelled => 'تبدیل لغو شد';

  @override
  String get startingConversion => 'شروع تبدیل...';

  @override
  String get allFilesPermissionContent =>
      'برای ذخیره فایل‌های تبدیل‌شده در پوشه عمومی موسیقی، برنامه به مجوز «دسترسی به همه فایل‌ها» نیاز دارد.\n\nآیا می‌خواهید تنظیمات را باز کنید؟';

  @override
  String get later => 'بعداً';

  @override
  String get openSettings => 'باز کردن تنظیمات';

  @override
  String get selectFormat => 'انتخاب فرمت';

  @override
  String get conversionDone => 'تبدیل انجام شد!';

  @override
  String savedAs(String filename) {
    return 'ذخیره شده به نام: $filename';
  }

  @override
  String get editMetadata => 'ویرایش اطلاعات';

  @override
  String get trackTitle => 'عنوان آهنگ';

  @override
  String get artistName => 'نام هنرمند';

  @override
  String get albumTitle => 'نام آلبوم';

  @override
  String get saveMetadata => 'ذخیره اطلاعات';

  @override
  String get outputName => 'نام فایل خروجی';

  @override
  String get enterOutputFilename => 'نام فایل خروجی را وارد کنید...';

  @override
  String get format => 'فرمت';

  @override
  String get pleaseWaitMoment => 'لطفاً صبر کنید، ممکن است کمی طول بکشد';

  @override
  String get permissionExplanation =>
      'برای ذخیره فایل‌های تبدیل‌شده در پوشه عمومی موسیقی، برنامه به مجوز «دسترسی به همه فایل‌ها» نیاز دارد.\n\nآیا می‌خواهید تنظیمات را باز کنید؟';

  @override
  String get processed => 'پردازش شده';

  @override
  String get failedToSave => 'تبدیل شد اما ذخیره در پوشه موسیقی ناموفق بود.';

  @override
  String get selectDifferentVideo => 'انتخاب ویدیوی دیگر';

  @override
  String get convertToAudio => 'تبدیل به صوت';

  @override
  String get editInfo => 'ویرایش اطلاعات';

  @override
  String get save => 'ذخیره';

  @override
  String get changeCover => 'تغییر کاور';

  @override
  String get savingChanges => 'در حال ذخیره تغییرات...';

  @override
  String get failedPickImage => 'انتخاب تصویر ناموفق بود';

  @override
  String get titleEmptyError => 'عنوان نمی‌تواند خالی باشد';

  @override
  String get editAudio => 'ویرایش صدا';

  @override
  String get previewGenerationFailed => 'ساخت پیش‌نمایش ناموفق بود.';

  @override
  String get processingFailed => 'پردازش ناموفق بود.';

  @override
  String get failed => 'ناموفق';

  @override
  String get error => 'خطا';

  @override
  String get editing => 'ویرایشگر صدا';

  @override
  String get history => 'تاریخچه';

  @override
  String get tools => 'ابزارها';

  @override
  String get convertVideoToAudio => 'تبدیل ویدیو به صوت';

  @override
  String get noHistoryYet => 'هنوز تاریخچه‌ای وجود ندارد';

  @override
  String get extractionComplete => 'استخراج صدا تکمیل شد';

  @override
  String get savedTo => 'ذخیره شد در';

  @override
  String get convertAnother => 'تبدیل دیگر';

  @override
  String get chooseVideoToStart => 'یک ویدیو برای شروع انتخاب کنید';

  @override
  String get toggleFavorite => 'تغییر وضعیت علاقه‌مندی';

  @override
  String get favorites => 'علاقه‌مندی‌ها';

  @override
  String get addAudioToEdit => 'افزودن فایل صوتی برای ویرایش';

  @override
  String get selectFromLibrary => 'انتخاب از کتابخانه';

  @override
  String get removeFromLibrary => 'حذف از کتابخانه';

  @override
  String get deletePermanently => 'حذف دائمی';

  @override
  String get showInFolder => 'نمایش در پوشه';

  @override
  String get selectAll => 'انتخاب همه';

  @override
  String get clear => 'پاک کردن';

  @override
  String selected(int count) {
    return '$count انتخاب شده';
  }

  @override
  String get addMusicFolder => 'افزودن پوشه موسیقی';

  @override
  String get addAudioFile => 'افزودن فایل صوتی';

  @override
  String get mediaAdded => 'رسانه اضافه شد! در حال اسکن...';

  @override
  String get filesAdded => 'فایل‌ها اضافه شدند!';

  @override
  String get renameSong => 'تغییر نام آهنگ';

  @override
  String get editInfoTitleArt => 'ویرایش اطلاعات (عنوان، کاور...)';

  @override
  String get editAudioTrim8D => 'ویرایش صدا (برش، 8D)';

  @override
  String get noResults => 'نتیجه‌ای یافت نشد';

  @override
  String get placeMusicFolder => 'فایل‌های صوتی را در پوشه موسیقی قرار دهید';

  @override
  String get songRenamed => 'نام آهنگ با موفقیت تغییر کرد';

  @override
  String get renameFailed => 'تغییر نام ناموفق بود';

  @override
  String get songDeleted => 'آهنگ با موفقیت حذف شد';

  @override
  String get deleteFailed => 'حذف ناموفق بود';

  @override
  String get songRemoved => 'آهنگ از کتابخانه حذف شد';

  @override
  String removedItems(int count) {
    return '$count مورد از کتابخانه حذف شد';
  }

  @override
  String deletedItems(int count) {
    return '$count مورد برای همیشه حذف شد';
  }

  @override
  String addedToPlaylist(String name) {
    return 'به $name اضافه شد';
  }

  @override
  String get alreadyInPlaylist => 'از قبل در لیست پخش وجود دارد';

  @override
  String get noPlaylistsCreate => 'لیست پخشی وجود ندارد. ابتدا یکی بسازید!';

  @override
  String get removeFromLibraryTitle => 'حذف از کتابخانه؟';

  @override
  String get removeFromLibraryMsg =>
      'این آهنگ از کتابخانه پنهان شود؟ فایل اصلی روی دستگاه شما باقی می‌ماند.';

  @override
  String get deleteTitle => 'حذف دائمی؟';

  @override
  String get deleteMsg =>
      'آیا مطمئن هستید که می‌خواهید این مورد را برای همیشه از دستگاه حذف کنید؟ این عمل قابل بازگشت نیست.';

  @override
  String get remove => 'حذف';

  @override
  String get fileType => 'نوع فایل';

  @override
  String get defaultPlayer => 'پخش‌کننده پیش‌فرض';

  @override
  String get defaultPlayerMsg =>
      'آیا می‌خواهید ToneHarbor را به عنوان پخش‌کننده پیش‌فرض تنظیم کنید؟';

  @override
  String get noThanks => 'نه، ممنون';

  @override
  String get yesOpenSettings => 'بله، باز کردن تنظیمات';

  @override
  String get welcomeBack => 'خوش آمدید';

  @override
  String get convertVideoBtn => 'تبدیل ویدیو به صوت';

  @override
  String get moreActions => 'اقدامات بیشتر';

  @override
  String secondsVideo(String seconds) {
    return 'ویدیوی $seconds ثانیه‌ای';
  }

  @override
  String get chooseSource => 'انتخاب منبع';

  @override
  String get gallery => 'گالری (ویدیوها)';

  @override
  String get files => 'فایل‌ها (ویدیو)';

  @override
  String get selectVideoOnly => 'لطفاً یک فایل ویدیویی انتخاب کنید';

  @override
  String get addToFavorites => 'افزودن به علاقه‌مندی‌ها';

  @override
  String get removeFromFavorites => 'حذف از علاقه‌مندی‌ها';

  @override
  String get noSongPlaying => 'هیچ آهنگی در حال پخش نیست';

  @override
  String get back => 'بازگشت';

  @override
  String get timer => 'تایمر';

  @override
  String get single => 'تکی';

  @override
  String get playbackSpeed => 'سرعت پخش';

  @override
  String get stopAtTimerEnd => 'توقف در پایان تایمر';

  @override
  String get stopAtTimerEndSub => 'توقف پخش بعد از X دقیقه';

  @override
  String get stopAtTrackEnd => 'توقف در پایان آهنگ';

  @override
  String get stopAtTrackEndSub => 'توقف پخش پس از اتمام آهنگ';

  @override
  String get stopAtPlaylistEnd => 'توقف در پایان لیست پخش';

  @override
  String get stopAtPlaylistEndSub => 'توقف پخش پس از اتمام لیست پخش';

  @override
  String get closeAppWhenStopped => 'بستن برنامه هنگام توقف';

  @override
  String get slidePicker => 'برای تنظیم زمان بکشید';

  @override
  String setTimerWithMin(int minutes) {
    return 'تنظیم تایمر ($minutes دقیقه)';
  }

  @override
  String get cancelTimerBtn => 'لغو تایمر';

  @override
  String get startSleepTimer => 'شروع تایمر خواب';

  @override
  String get track => 'آهنگ';

  @override
  String get list => 'لیست';

  @override
  String get saveAsNewFile => 'ذخیره به عنوان فایل جدید';

  @override
  String get replaceOriginal => 'جایگزینی فایل اصلی';

  @override
  String savingProgress(int percent) {
    return 'در حال ذخیره: $percent%';
  }

  @override
  String get audioSettings => 'تنظیمات صدا';

  @override
  String get automaticHeadset => 'خودکار (ترجیح هدست)';

  @override
  String get forceSpeaker => 'اجبار بلندگوی داخلی';

  @override
  String get forceHeadset => 'اجبار هدست / بلوتوث';

  @override
  String get dark => 'تاریک';

  @override
  String get light => 'روشن';

  @override
  String get appSlogan => 'پخش‌کننده موسیقی مدرن با مبدل ویدیو';

  @override
  String get recentlyPlayed => 'اخیرا پخش شده';

  @override
  String get pageNotFound => 'صفحه یافت نشد';

  @override
  String get songUnavailable => 'آهنگ در دسترس نیست';

  @override
  String get rename => 'تغییر نام';

  @override
  String get noFavoritesYet => 'هنوز علاقه‌مندی‌ای وجود ندارد';

  @override
  String get closeApp => 'بستن برنامه';

  @override
  String get expandToFullApp => 'باز کردن برنامه';

  @override
  String get overlaySettings => 'تنظیمات نوار شناور';

  @override
  String get backgroundBlur => 'محو شدن پس‌زمینه';

  @override
  String get resetToDefault => 'بازنشانی به پیش‌فرض';

  @override
  String addedSongsToPlaylist(int count, String name) {
    return '$count آهنگ به $name اضافه شد';
  }

  @override
  String get notSupportedPlatform => 'در این پلتفرم پشتیبانی نمی‌شود';

  @override
  String get permissionWriteSettings =>
      'برای تغییر تنظیمات سیستم به مجوز نیاز است';

  @override
  String get ringtoneFailed => 'تنظیم آهنگ زنگ ناموفق بود';

  @override
  String get pressBackAgainToExit => 'برای خروج دوباره دکمه بازگشت را بزنید';

  @override
  String get refreshLibrary => 'بازخوانی کتابخانه';

  @override
  String get storageAndCache => 'فضای ذخیره‌سازی و حافظه پنهان';

  @override
  String get cacheSize => 'حجم حافظه پنهان';

  @override
  String get clearCache => 'پاک کردن حافظه پنهان';

  @override
  String get clearCacheSuccess => 'حافظه پنهان با موفقیت پاک شد';

  @override
  String get clearCacheDesc => 'حذف ویدیوها و فایل‌های موقت برای آزادسازی فضا';

  @override
  String get cacheClean => 'حافظه پنهان پاک است (0 B)';

  @override
  String get restoreExcludedTitle => 'افزودن آهنگ‌ها به کتابخانه';

  @override
  String get restoreExcludedPromptSingle =>
      'این آهنگ قبلاً از کتابخانه حذف شده بود. آیا می‌خواهید دوباره آن را به کتابخانه اضافه کنید؟';

  @override
  String get restoreExcludedPromptMultiple =>
      'آهنگ‌هایی یافت شدند که قبلاً از کتابخانه حذف شده بودند. آیا می‌خواهید آنها را دوباره اضافه کنید؟';

  @override
  String get restoreExcludedAction => 'افزودن به کتابخانه';

  @override
  String get restoreExcludedKeepHidden => 'مخفی بماند';

  @override
  String get deselectAll => 'لغو انتخاب همه';

  @override
  String restoredSongsCount(int count) {
    return '$count آهنگ به کتابخانه اضافه شد';
  }
}
