import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ToneHarbor'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @convertVideo.
  ///
  /// In en, this message translates to:
  /// **'Converter'**
  String get convertVideo;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlaying;

  /// No description provided for @quickPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Quick Playlists'**
  String get quickPlaylists;

  /// No description provided for @recentConversions.
  ///
  /// In en, this message translates to:
  /// **'Recent Conversions'**
  String get recentConversions;

  /// No description provided for @quickVideoConvert.
  ///
  /// In en, this message translates to:
  /// **'Quick Video Convert'**
  String get quickVideoConvert;

  /// No description provided for @selectVideo.
  ///
  /// In en, this message translates to:
  /// **'Select Video'**
  String get selectVideo;

  /// No description provided for @converting.
  ///
  /// In en, this message translates to:
  /// **'Converting'**
  String get converting;

  /// No description provided for @conversionComplete.
  ///
  /// In en, this message translates to:
  /// **'Conversion Complete'**
  String get conversionComplete;

  /// No description provided for @conversionFailed.
  ///
  /// In en, this message translates to:
  /// **'Conversion Failed'**
  String get conversionFailed;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @sleepTimerRemaining.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min remaining'**
  String sleepTimerRemaining(int minutes);

  /// No description provided for @singleTrackMode.
  ///
  /// In en, this message translates to:
  /// **'Single Track Mode'**
  String get singleTrackMode;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylist;

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create Playlist'**
  String get createPlaylist;

  /// No description provided for @editPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Edit Playlist'**
  String get editPlaylist;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// No description provided for @renamePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Rename Playlist'**
  String get renamePlaylist;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get playlistName;

  /// No description provided for @noSongsFound.
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get noSongsFound;

  /// No description provided for @noPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylists;

  /// No description provided for @createFirstPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create your first playlist'**
  String get createFirstPlaylist;

  /// No description provided for @songCount.
  ///
  /// In en, this message translates to:
  /// **'{count} songs'**
  String songCount(int count);

  /// No description provided for @timerOptionTimeAndLock.
  ///
  /// In en, this message translates to:
  /// **'Timer + Lock Screen'**
  String get timerOptionTimeAndLock;

  /// No description provided for @timerOptionTrackEnd.
  ///
  /// In en, this message translates to:
  /// **'Stop at Track End'**
  String get timerOptionTrackEnd;

  /// No description provided for @timerOptionTimeOnly.
  ///
  /// In en, this message translates to:
  /// **'Timer Only'**
  String get timerOptionTimeOnly;

  /// No description provided for @timerDuration.
  ///
  /// In en, this message translates to:
  /// **'Timer Duration'**
  String get timerDuration;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @setTimer.
  ///
  /// In en, this message translates to:
  /// **'Set Timer'**
  String get setTimer;

  /// No description provided for @cancelTimer.
  ///
  /// In en, this message translates to:
  /// **'Cancel Timer'**
  String get cancelTimer;

  /// No description provided for @timerSet.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer set for {minutes} minutes'**
  String timerSet(int minutes);

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @selectLanguagePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language to get started'**
  String get selectLanguagePrompt;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @persian.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get persian;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkOcean.
  ///
  /// In en, this message translates to:
  /// **'Dark Ocean'**
  String get darkOcean;

  /// No description provided for @desertSand.
  ///
  /// In en, this message translates to:
  /// **'Desert Sand'**
  String get desertSand;

  /// No description provided for @aurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get aurora;

  /// No description provided for @midnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get midnight;

  /// No description provided for @lightBreeze.
  ///
  /// In en, this message translates to:
  /// **'Light Breeze'**
  String get lightBreeze;

  /// No description provided for @goldBlack.
  ///
  /// In en, this message translates to:
  /// **'Gold Black'**
  String get goldBlack;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @allSongs.
  ///
  /// In en, this message translates to:
  /// **'All Songs'**
  String get allSongs;

  /// No description provided for @albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albums;

  /// No description provided for @artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artists;

  /// No description provided for @searchSongs.
  ///
  /// In en, this message translates to:
  /// **'Search songs...'**
  String get searchSongs;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @permissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is needed to access your music files.'**
  String get permissionMessage;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @noConversions.
  ///
  /// In en, this message translates to:
  /// **'No conversions yet'**
  String get noConversions;

  /// No description provided for @convertFirst.
  ///
  /// In en, this message translates to:
  /// **'Convert a video to get started'**
  String get convertFirst;

  /// No description provided for @outputAudio.
  ///
  /// In en, this message translates to:
  /// **'Output Audio'**
  String get outputAudio;

  /// No description provided for @sourceVideo.
  ///
  /// In en, this message translates to:
  /// **'Source Video'**
  String get sourceVideo;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// No description provided for @setAsRingtone.
  ///
  /// In en, this message translates to:
  /// **'Set as Ringtone'**
  String get setAsRingtone;

  /// No description provided for @ringtoneSetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ringtone set successfully'**
  String get ringtoneSetSuccess;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @themeGoldBlack.
  ///
  /// In en, this message translates to:
  /// **'Gold Black'**
  String get themeGoldBlack;

  /// No description provided for @themeGreenGrey.
  ///
  /// In en, this message translates to:
  /// **'Green Grey'**
  String get themeGreenGrey;

  /// No description provided for @themeWarmBrown.
  ///
  /// In en, this message translates to:
  /// **'Warm Brown'**
  String get themeWarmBrown;

  /// No description provided for @themeQuran.
  ///
  /// In en, this message translates to:
  /// **'Quranic'**
  String get themeQuran;

  /// No description provided for @themeAshura.
  ///
  /// In en, this message translates to:
  /// **'Ashura'**
  String get themeAshura;

  /// No description provided for @themeMuharram.
  ///
  /// In en, this message translates to:
  /// **'Muharram'**
  String get themeMuharram;

  /// No description provided for @themeHussaini.
  ///
  /// In en, this message translates to:
  /// **'Husseini'**
  String get themeHussaini;

  /// No description provided for @themeRamadan.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get themeRamadan;

  /// No description provided for @themeBlueSky.
  ///
  /// In en, this message translates to:
  /// **'Blue Sky'**
  String get themeBlueSky;

  /// No description provided for @themeRoyalRed.
  ///
  /// In en, this message translates to:
  /// **'Muharram'**
  String get themeRoyalRed;

  /// No description provided for @themeEmeraldGold.
  ///
  /// In en, this message translates to:
  /// **'Emerald & Gold'**
  String get themeEmeraldGold;

  /// No description provided for @themeLavender.
  ///
  /// In en, this message translates to:
  /// **'Lavender Light'**
  String get themeLavender;

  /// No description provided for @themeCrescentTeal.
  ///
  /// In en, this message translates to:
  /// **'Crescent Teal'**
  String get themeCrescentTeal;

  /// No description provided for @themeRoyalCrimson.
  ///
  /// In en, this message translates to:
  /// **'Royal Crimson'**
  String get themeRoyalCrimson;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteConfirmMessage(String name);

  /// No description provided for @addSongs.
  ///
  /// In en, this message translates to:
  /// **'Add Songs'**
  String get addSongs;

  /// No description provided for @removeSong.
  ///
  /// In en, this message translates to:
  /// **'Remove Song'**
  String get removeSong;

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAll;

  /// No description provided for @shuffleAll.
  ///
  /// In en, this message translates to:
  /// **'Shuffle All'**
  String get shuffleAll;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @unlike.
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get unlike;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown Artist'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown Album'**
  String get unknownAlbum;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @artist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artist;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @dateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get dateAdded;

  /// No description provided for @renameFile.
  ///
  /// In en, this message translates to:
  /// **'Rename File'**
  String get renameFile;

  /// No description provided for @enterNewName.
  ///
  /// In en, this message translates to:
  /// **'Enter new name...'**
  String get enterNewName;

  /// No description provided for @trimAudio.
  ///
  /// In en, this message translates to:
  /// **'Trim Audio'**
  String get trimAudio;

  /// No description provided for @loadingWaveform.
  ///
  /// In en, this message translates to:
  /// **'Loading waveform...'**
  String get loadingWaveform;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @highVolumeWarning.
  ///
  /// In en, this message translates to:
  /// **'High volume may cause distortion'**
  String get highVolumeWarning;

  /// No description provided for @fadeEffects.
  ///
  /// In en, this message translates to:
  /// **'Fade Effects'**
  String get fadeEffects;

  /// No description provided for @fadeIn.
  ///
  /// In en, this message translates to:
  /// **'Fade In'**
  String get fadeIn;

  /// No description provided for @fadeOut.
  ///
  /// In en, this message translates to:
  /// **'Fade Out'**
  String get fadeOut;

  /// No description provided for @eightDAudio.
  ///
  /// In en, this message translates to:
  /// **'8D Audio Effect'**
  String get eightDAudio;

  /// No description provided for @eightDDescription.
  ///
  /// In en, this message translates to:
  /// **'Creates a spatial panning sound'**
  String get eightDDescription;

  /// No description provided for @rotationSpeed.
  ///
  /// In en, this message translates to:
  /// **'Rotation Speed'**
  String get rotationSpeed;

  /// No description provided for @speedSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get speedSlow;

  /// No description provided for @speedNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get speedNormal;

  /// No description provided for @speedFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get speedFast;

  /// No description provided for @effectIntensity.
  ///
  /// In en, this message translates to:
  /// **'Effect Intensity'**
  String get effectIntensity;

  /// No description provided for @reverbDepth.
  ///
  /// In en, this message translates to:
  /// **'Room Ambience (Reverb)'**
  String get reverbDepth;

  /// No description provided for @reverbSmall.
  ///
  /// In en, this message translates to:
  /// **'Small Studio'**
  String get reverbSmall;

  /// No description provided for @reverbMedium.
  ///
  /// In en, this message translates to:
  /// **'Concert Hall'**
  String get reverbMedium;

  /// No description provided for @reverbLarge.
  ///
  /// In en, this message translates to:
  /// **'Grand Theatre'**
  String get reverbLarge;

  /// No description provided for @previewEffect.
  ///
  /// In en, this message translates to:
  /// **'Preview Effect'**
  String get previewEffect;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @generatingPreview.
  ///
  /// In en, this message translates to:
  /// **'Generating high-quality preview...'**
  String get generatingPreview;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @savingAudio.
  ///
  /// In en, this message translates to:
  /// **'Saving audio...'**
  String get savingAudio;

  /// No description provided for @audioSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Audio saved successfully'**
  String get audioSavedSuccess;

  /// No description provided for @audioSavedError.
  ///
  /// In en, this message translates to:
  /// **'Error saving audio'**
  String get audioSavedError;

  /// No description provided for @extractingVideoInfo.
  ///
  /// In en, this message translates to:
  /// **'Extracting video info...'**
  String get extractingVideoInfo;

  /// No description provided for @conversionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Conversion cancelled.'**
  String get conversionCancelled;

  /// No description provided for @startingConversion.
  ///
  /// In en, this message translates to:
  /// **'Starting conversion...'**
  String get startingConversion;

  /// No description provided for @allFilesPermissionContent.
  ///
  /// In en, this message translates to:
  /// **'To save converted files to the public Music folder, the app needs \"All files access\". \n\nWould you like to open settings to grant this permission?'**
  String get allFilesPermissionContent;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @selectFormat.
  ///
  /// In en, this message translates to:
  /// **'Select Format'**
  String get selectFormat;

  /// No description provided for @conversionDone.
  ///
  /// In en, this message translates to:
  /// **'Conversion Done!'**
  String get conversionDone;

  /// No description provided for @savedAs.
  ///
  /// In en, this message translates to:
  /// **'Saved as: {filename}'**
  String savedAs(String filename);

  /// No description provided for @editMetadata.
  ///
  /// In en, this message translates to:
  /// **'Edit Metadata'**
  String get editMetadata;

  /// No description provided for @trackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Title'**
  String get trackTitle;

  /// No description provided for @artistName.
  ///
  /// In en, this message translates to:
  /// **'Artist Name'**
  String get artistName;

  /// No description provided for @albumTitle.
  ///
  /// In en, this message translates to:
  /// **'Album Title'**
  String get albumTitle;

  /// No description provided for @saveMetadata.
  ///
  /// In en, this message translates to:
  /// **'Save Metadata'**
  String get saveMetadata;

  /// No description provided for @outputName.
  ///
  /// In en, this message translates to:
  /// **'Output Name'**
  String get outputName;

  /// No description provided for @enterOutputFilename.
  ///
  /// In en, this message translates to:
  /// **'Enter output filename...'**
  String get enterOutputFilename;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @pleaseWaitMoment.
  ///
  /// In en, this message translates to:
  /// **'Please wait, this may take a moment'**
  String get pleaseWaitMoment;

  /// No description provided for @permissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'To save converted files to the public Music folder, the app needs \"All files access\". \n\nWould you like to open settings to grant this permission?'**
  String get permissionExplanation;

  /// No description provided for @processed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get processed;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Converted but failed to save to Music folder.'**
  String get failedToSave;

  /// No description provided for @selectDifferentVideo.
  ///
  /// In en, this message translates to:
  /// **'Select Different Video'**
  String get selectDifferentVideo;

  /// No description provided for @convertToAudio.
  ///
  /// In en, this message translates to:
  /// **'Convert to Audio'**
  String get convertToAudio;

  /// No description provided for @editInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Info'**
  String get editInfo;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @changeCover.
  ///
  /// In en, this message translates to:
  /// **'Change Cover'**
  String get changeCover;

  /// No description provided for @savingChanges.
  ///
  /// In en, this message translates to:
  /// **'Saving changes...'**
  String get savingChanges;

  /// No description provided for @failedPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get failedPickImage;

  /// No description provided for @titleEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Title cannot be empty'**
  String get titleEmptyError;

  /// No description provided for @editAudio.
  ///
  /// In en, this message translates to:
  /// **'Edit Audio'**
  String get editAudio;

  /// No description provided for @previewGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Preview generation failed.'**
  String get previewGenerationFailed;

  /// No description provided for @processingFailed.
  ///
  /// In en, this message translates to:
  /// **'Processing failed.'**
  String get processingFailed;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @editing.
  ///
  /// In en, this message translates to:
  /// **'Audio Editor'**
  String get editing;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @convertVideoToAudio.
  ///
  /// In en, this message translates to:
  /// **'Video to Audio'**
  String get convertVideoToAudio;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @extractionComplete.
  ///
  /// In en, this message translates to:
  /// **'Audio Extraction Complete'**
  String get extractionComplete;

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to'**
  String get savedTo;

  /// No description provided for @convertAnother.
  ///
  /// In en, this message translates to:
  /// **'Convert Another'**
  String get convertAnother;

  /// No description provided for @chooseVideoToStart.
  ///
  /// In en, this message translates to:
  /// **'Choose a video to start'**
  String get chooseVideoToStart;

  /// No description provided for @toggleFavorite.
  ///
  /// In en, this message translates to:
  /// **'Toggle Favorite'**
  String get toggleFavorite;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @addAudioToEdit.
  ///
  /// In en, this message translates to:
  /// **'Add Audio to Edit'**
  String get addAudioToEdit;

  /// No description provided for @selectFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Select from Library'**
  String get selectFromLibrary;

  /// No description provided for @removeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from Library'**
  String get removeFromLibrary;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @showInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in Folder'**
  String get showInFolder;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String selected(int count);

  /// No description provided for @addMusicFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Music Folder'**
  String get addMusicFolder;

  /// No description provided for @addAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Add Audio File'**
  String get addAudioFile;

  /// No description provided for @mediaAdded.
  ///
  /// In en, this message translates to:
  /// **'Media added! Scanning...'**
  String get mediaAdded;

  /// No description provided for @filesAdded.
  ///
  /// In en, this message translates to:
  /// **'Files added!'**
  String get filesAdded;

  /// No description provided for @renameSong.
  ///
  /// In en, this message translates to:
  /// **'Rename Song'**
  String get renameSong;

  /// No description provided for @editInfoTitleArt.
  ///
  /// In en, this message translates to:
  /// **'Edit Info (Title, Art, ...)'**
  String get editInfoTitleArt;

  /// No description provided for @editAudioTrim8D.
  ///
  /// In en, this message translates to:
  /// **'Edit Audio (Trim, 8D)'**
  String get editAudioTrim8D;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @placeMusicFolder.
  ///
  /// In en, this message translates to:
  /// **'Place audio files in your Music folder'**
  String get placeMusicFolder;

  /// No description provided for @songRenamed.
  ///
  /// In en, this message translates to:
  /// **'Song renamed successfully'**
  String get songRenamed;

  /// No description provided for @renameFailed.
  ///
  /// In en, this message translates to:
  /// **'Rename failed'**
  String get renameFailed;

  /// No description provided for @songDeleted.
  ///
  /// In en, this message translates to:
  /// **'Song deleted successfully'**
  String get songDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @songRemoved.
  ///
  /// In en, this message translates to:
  /// **'Song removed from library'**
  String get songRemoved;

  /// No description provided for @removedItems.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} items from library'**
  String removedItems(int count);

  /// No description provided for @deletedItems.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} items permanently'**
  String deletedItems(int count);

  /// No description provided for @addedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added to {name}'**
  String addedToPlaylist(String name);

  /// No description provided for @alreadyInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Already in playlist'**
  String get alreadyInPlaylist;

  /// No description provided for @noPlaylistsCreate.
  ///
  /// In en, this message translates to:
  /// **'No playlists available. Create one first!'**
  String get noPlaylistsCreate;

  /// No description provided for @removeFromLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from Library?'**
  String get removeFromLibraryTitle;

  /// No description provided for @removeFromLibraryMsg.
  ///
  /// In en, this message translates to:
  /// **'Hide this song from your library? The original file will remain on your device.'**
  String get removeFromLibraryMsg;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently?'**
  String get deleteTitle;

  /// No description provided for @deleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this from your device? This action cannot be undone.'**
  String get deleteMsg;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @fileType.
  ///
  /// In en, this message translates to:
  /// **'File Type'**
  String get fileType;

  /// No description provided for @defaultPlayer.
  ///
  /// In en, this message translates to:
  /// **'Default Audio Player'**
  String get defaultPlayer;

  /// No description provided for @defaultPlayerMsg.
  ///
  /// In en, this message translates to:
  /// **'Would you like to set ToneHarbor as your default audio player?'**
  String get defaultPlayerMsg;

  /// No description provided for @noThanks.
  ///
  /// In en, this message translates to:
  /// **'No, thanks'**
  String get noThanks;

  /// No description provided for @yesOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Yes, open settings'**
  String get yesOpenSettings;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @convertVideoBtn.
  ///
  /// In en, this message translates to:
  /// **'Convert Video to Audio'**
  String get convertVideoBtn;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More Actions'**
  String get moreActions;

  /// No description provided for @secondsVideo.
  ///
  /// In en, this message translates to:
  /// **'{seconds} Seconds Video'**
  String secondsVideo(String seconds);

  /// No description provided for @chooseSource.
  ///
  /// In en, this message translates to:
  /// **'Choose Source'**
  String get chooseSource;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery (Videos)'**
  String get gallery;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files (Videos)'**
  String get files;

  /// No description provided for @selectVideoOnly.
  ///
  /// In en, this message translates to:
  /// **'Please select a video file'**
  String get selectVideoOnly;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @noSongPlaying.
  ///
  /// In en, this message translates to:
  /// **'No song playing'**
  String get noSongPlaying;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @timer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timer;

  /// No description provided for @single.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get single;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// No description provided for @stopAtTimerEnd.
  ///
  /// In en, this message translates to:
  /// **'Stop at Timer End'**
  String get stopAtTimerEnd;

  /// No description provided for @stopAtTimerEndSub.
  ///
  /// In en, this message translates to:
  /// **'Stop playback after X minutes'**
  String get stopAtTimerEndSub;

  /// No description provided for @stopAtTrackEnd.
  ///
  /// In en, this message translates to:
  /// **'Stop at Track End'**
  String get stopAtTrackEnd;

  /// No description provided for @stopAtTrackEndSub.
  ///
  /// In en, this message translates to:
  /// **'Stop playback when song finishes'**
  String get stopAtTrackEndSub;

  /// No description provided for @stopAtPlaylistEnd.
  ///
  /// In en, this message translates to:
  /// **'Stop at Playlist End'**
  String get stopAtPlaylistEnd;

  /// No description provided for @stopAtPlaylistEndSub.
  ///
  /// In en, this message translates to:
  /// **'Stop playback when playlist ends'**
  String get stopAtPlaylistEndSub;

  /// No description provided for @closeAppWhenStopped.
  ///
  /// In en, this message translates to:
  /// **'Close app when stopped'**
  String get closeAppWhenStopped;

  /// No description provided for @slidePicker.
  ///
  /// In en, this message translates to:
  /// **'Slide to adjust time'**
  String get slidePicker;

  /// No description provided for @setTimerWithMin.
  ///
  /// In en, this message translates to:
  /// **'Set Timer ({minutes} min)'**
  String setTimerWithMin(int minutes);

  /// No description provided for @cancelTimerBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel Timer'**
  String get cancelTimerBtn;

  /// No description provided for @startSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Start Sleep Timer'**
  String get startSleepTimer;

  /// No description provided for @track.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get track;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @saveAsNewFile.
  ///
  /// In en, this message translates to:
  /// **'Save as New File'**
  String get saveAsNewFile;

  /// No description provided for @replaceOriginal.
  ///
  /// In en, this message translates to:
  /// **'Replace Original File'**
  String get replaceOriginal;

  /// No description provided for @savingProgress.
  ///
  /// In en, this message translates to:
  /// **'Saving: {percent}%'**
  String savingProgress(int percent);

  /// No description provided for @audioSettings.
  ///
  /// In en, this message translates to:
  /// **'Audio Settings'**
  String get audioSettings;

  /// No description provided for @automaticHeadset.
  ///
  /// In en, this message translates to:
  /// **'Automatic (Prefer Headset)'**
  String get automaticHeadset;

  /// No description provided for @forceSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Force Internal Speaker'**
  String get forceSpeaker;

  /// No description provided for @forceHeadset.
  ///
  /// In en, this message translates to:
  /// **'Force Headset / Bluetooth'**
  String get forceHeadset;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Modern Music Player with Video Converter'**
  String get appSlogan;

  /// No description provided for @recentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get recentlyPlayed;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @songUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Song unavailable'**
  String get songUnavailable;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @closeApp.
  ///
  /// In en, this message translates to:
  /// **'Close App'**
  String get closeApp;

  /// No description provided for @expandToFullApp.
  ///
  /// In en, this message translates to:
  /// **'Expand to Full App'**
  String get expandToFullApp;

  /// No description provided for @overlaySettings.
  ///
  /// In en, this message translates to:
  /// **'Overlay Settings'**
  String get overlaySettings;

  /// No description provided for @backgroundBlur.
  ///
  /// In en, this message translates to:
  /// **'Background Blur'**
  String get backgroundBlur;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// No description provided for @addedSongsToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added {count} songs to {name}'**
  String addedSongsToPlaylist(int count, String name);

  /// No description provided for @notSupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Not supported on this platform'**
  String get notSupportedPlatform;

  /// No description provided for @permissionWriteSettings.
  ///
  /// In en, this message translates to:
  /// **'Permission is needed to modify system settings'**
  String get permissionWriteSettings;

  /// No description provided for @ringtoneFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to set ringtone'**
  String get ringtoneFailed;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @refreshLibrary.
  ///
  /// In en, this message translates to:
  /// **'Refresh Library'**
  String get refreshLibrary;

  /// No description provided for @storageAndCache.
  ///
  /// In en, this message translates to:
  /// **'Storage & Cache'**
  String get storageAndCache;

  /// No description provided for @cacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache Size'**
  String get cacheSize;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearCacheSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get clearCacheSuccess;

  /// No description provided for @clearCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'Delete temporary videos and files to free up space'**
  String get clearCacheDesc;

  /// No description provided for @cacheClean.
  ///
  /// In en, this message translates to:
  /// **'Cache is clean (0 B)'**
  String get cacheClean;

  /// No description provided for @restoreExcludedTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Tracks to Library'**
  String get restoreExcludedTitle;

  /// No description provided for @restoreExcludedPromptSingle.
  ///
  /// In en, this message translates to:
  /// **'This track was previously removed from your library. Do you want to add it back?'**
  String get restoreExcludedPromptSingle;

  /// No description provided for @restoreExcludedPromptMultiple.
  ///
  /// In en, this message translates to:
  /// **'Found tracks that were previously removed from your library. Do you want to add them back?'**
  String get restoreExcludedPromptMultiple;

  /// No description provided for @restoreExcludedAction.
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
  String get restoreExcludedAction;

  /// No description provided for @restoreExcludedKeepHidden.
  ///
  /// In en, this message translates to:
  /// **'Keep Hidden'**
  String get restoreExcludedKeepHidden;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @restoredSongsCount.
  ///
  /// In en, this message translates to:
  /// **'Added {count} tracks to library'**
  String restoredSongsCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
