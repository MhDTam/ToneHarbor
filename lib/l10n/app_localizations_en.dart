// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ToneHarbor';

  @override
  String get home => 'Home';

  @override
  String get library => 'Library';

  @override
  String get convertVideo => 'Converter';

  @override
  String get playlists => 'Playlists';

  @override
  String get settings => 'Settings';

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get quickPlaylists => 'Quick Playlists';

  @override
  String get recentConversions => 'Recent Conversions';

  @override
  String get quickVideoConvert => 'Quick Video Convert';

  @override
  String get selectVideo => 'Select Video';

  @override
  String get converting => 'Converting';

  @override
  String get conversionComplete => 'Conversion Complete';

  @override
  String get conversionFailed => 'Conversion Failed';

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String sleepTimerRemaining(int minutes) {
    return '$minutes min remaining';
  }

  @override
  String get singleTrackMode => 'Single Track Mode';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get repeat => 'Repeat';

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get editPlaylist => 'Edit Playlist';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String get renamePlaylist => 'Rename Playlist';

  @override
  String get playlistName => 'Playlist Name';

  @override
  String get noSongsFound => 'No songs found';

  @override
  String get noPlaylists => 'No playlists yet';

  @override
  String get createFirstPlaylist => 'Create your first playlist';

  @override
  String songCount(int count) {
    return '$count songs';
  }

  @override
  String get timerOptionTimeAndLock => 'Timer + Lock Screen';

  @override
  String get timerOptionTrackEnd => 'Stop at Track End';

  @override
  String get timerOptionTimeOnly => 'Timer Only';

  @override
  String get timerDuration => 'Timer Duration';

  @override
  String get minutes => 'minutes';

  @override
  String get setTimer => 'Set Timer';

  @override
  String get cancelTimer => 'Cancel Timer';

  @override
  String timerSet(int minutes) {
    return 'Sleep timer set for $minutes minutes';
  }

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get selectLanguagePrompt =>
      'Select your preferred language to get started';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get persian => 'Persian';

  @override
  String get continueBtn => 'Continue';

  @override
  String get theme => 'Theme';

  @override
  String get darkOcean => 'Dark Ocean';

  @override
  String get desertSand => 'Desert Sand';

  @override
  String get aurora => 'Aurora';

  @override
  String get midnight => 'Midnight';

  @override
  String get lightBreeze => 'Light Breeze';

  @override
  String get goldBlack => 'Gold Black';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get allSongs => 'All Songs';

  @override
  String get albums => 'Albums';

  @override
  String get artists => 'Artists';

  @override
  String get searchSongs => 'Search songs...';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get permissionMessage =>
      'Storage permission is needed to access your music files.';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get noConversions => 'No conversions yet';

  @override
  String get convertFirst => 'Convert a video to get started';

  @override
  String get outputAudio => 'Output Audio';

  @override
  String get sourceVideo => 'Source Video';

  @override
  String get fileSize => 'File Size';

  @override
  String get setAsRingtone => 'Set as Ringtone';

  @override
  String get ringtoneSetSuccess => 'Ringtone set successfully';

  @override
  String get share => 'Share';

  @override
  String get themeGoldBlack => 'Gold Black';

  @override
  String get themeGreenGrey => 'Green Grey';

  @override
  String get themeWarmBrown => 'Warm Brown';

  @override
  String get themeQuran => 'Quranic';

  @override
  String get themeAshura => 'Ashura';

  @override
  String get themeMuharram => 'Muharram';

  @override
  String get themeHussaini => 'Husseini';

  @override
  String get themeRamadan => 'Ramadan';

  @override
  String get themeBlueSky => 'Blue Sky';

  @override
  String get themeRoyalRed => 'Muharram';

  @override
  String get themeEmeraldGold => 'Emerald & Gold';

  @override
  String get themeLavender => 'Lavender Light';

  @override
  String get themeCrescentTeal => 'Crescent Teal';

  @override
  String get themeRoyalCrimson => 'Royal Crimson';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get deleteConfirmTitle => 'Delete Playlist';

  @override
  String deleteConfirmMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get addSongs => 'Add Songs';

  @override
  String get removeSong => 'Remove Song';

  @override
  String get playAll => 'Play All';

  @override
  String get shuffleAll => 'Shuffle All';

  @override
  String get like => 'Like';

  @override
  String get unlike => 'Unlike';

  @override
  String get unknown => 'Unknown';

  @override
  String get unknownArtist => 'Unknown Artist';

  @override
  String get unknownAlbum => 'Unknown Album';

  @override
  String get sortBy => 'Sort By';

  @override
  String get title => 'Title';

  @override
  String get artist => 'Artist';

  @override
  String get duration => 'Duration';

  @override
  String get dateAdded => 'Date Added';

  @override
  String get renameFile => 'Rename File';

  @override
  String get enterNewName => 'Enter new name...';

  @override
  String get trimAudio => 'Trim Audio';

  @override
  String get loadingWaveform => 'Loading waveform...';

  @override
  String get volume => 'Volume';

  @override
  String get highVolumeWarning => 'High volume may cause distortion';

  @override
  String get fadeEffects => 'Fade Effects';

  @override
  String get fadeIn => 'Fade In';

  @override
  String get fadeOut => 'Fade Out';

  @override
  String get eightDAudio => '8D Audio Effect';

  @override
  String get eightDDescription => 'Creates a spatial panning sound';

  @override
  String get rotationSpeed => 'Rotation Speed';

  @override
  String get speedSlow => 'Slow';

  @override
  String get speedNormal => 'Normal';

  @override
  String get speedFast => 'Fast';

  @override
  String get effectIntensity => 'Effect Intensity';

  @override
  String get reverbDepth => 'Room Ambience (Reverb)';

  @override
  String get reverbSmall => 'Small Studio';

  @override
  String get reverbMedium => 'Concert Hall';

  @override
  String get reverbLarge => 'Grand Theatre';

  @override
  String get previewEffect => 'Preview Effect';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get generatingPreview => 'Generating high-quality preview...';

  @override
  String get processing => 'Processing...';

  @override
  String get savingAudio => 'Saving audio...';

  @override
  String get audioSavedSuccess => 'Audio saved successfully';

  @override
  String get audioSavedError => 'Error saving audio';

  @override
  String get extractingVideoInfo => 'Extracting video info...';

  @override
  String get conversionCancelled => 'Conversion cancelled.';

  @override
  String get startingConversion => 'Starting conversion...';

  @override
  String get allFilesPermissionContent =>
      'To save converted files to the public Music folder, the app needs \"All files access\". \n\nWould you like to open settings to grant this permission?';

  @override
  String get later => 'Later';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get selectFormat => 'Select Format';

  @override
  String get conversionDone => 'Conversion Done!';

  @override
  String savedAs(String filename) {
    return 'Saved as: $filename';
  }

  @override
  String get editMetadata => 'Edit Metadata';

  @override
  String get trackTitle => 'Track Title';

  @override
  String get artistName => 'Artist Name';

  @override
  String get albumTitle => 'Album Title';

  @override
  String get saveMetadata => 'Save Metadata';

  @override
  String get outputName => 'Output Name';

  @override
  String get enterOutputFilename => 'Enter output filename...';

  @override
  String get format => 'Format';

  @override
  String get pleaseWaitMoment => 'Please wait, this may take a moment';

  @override
  String get permissionExplanation =>
      'To save converted files to the public Music folder, the app needs \"All files access\". \n\nWould you like to open settings to grant this permission?';

  @override
  String get processed => 'Processed';

  @override
  String get failedToSave => 'Converted but failed to save to Music folder.';

  @override
  String get selectDifferentVideo => 'Select Different Video';

  @override
  String get convertToAudio => 'Convert to Audio';

  @override
  String get editInfo => 'Edit Info';

  @override
  String get save => 'Save';

  @override
  String get changeCover => 'Change Cover';

  @override
  String get savingChanges => 'Saving changes...';

  @override
  String get failedPickImage => 'Failed to pick image';

  @override
  String get titleEmptyError => 'Title cannot be empty';

  @override
  String get editAudio => 'Edit Audio';

  @override
  String get previewGenerationFailed => 'Preview generation failed.';

  @override
  String get processingFailed => 'Processing failed.';

  @override
  String get failed => 'Failed';

  @override
  String get error => 'Error';

  @override
  String get editing => 'Audio Editor';

  @override
  String get history => 'History';

  @override
  String get tools => 'Tools';

  @override
  String get convertVideoToAudio => 'Video to Audio';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get extractionComplete => 'Audio Extraction Complete';

  @override
  String get savedTo => 'Saved to';

  @override
  String get convertAnother => 'Convert Another';

  @override
  String get chooseVideoToStart => 'Choose a video to start';

  @override
  String get toggleFavorite => 'Toggle Favorite';

  @override
  String get favorites => 'Favorites';

  @override
  String get addAudioToEdit => 'Add Audio to Edit';

  @override
  String get selectFromLibrary => 'Select from Library';

  @override
  String get removeFromLibrary => 'Remove from Library';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get showInFolder => 'Show in Folder';

  @override
  String get selectAll => 'Select All';

  @override
  String get clear => 'Clear';

  @override
  String selected(int count) {
    return '$count Selected';
  }

  @override
  String get addMusicFolder => 'Add Music Folder';

  @override
  String get addAudioFile => 'Add Audio File';

  @override
  String get mediaAdded => 'Media added! Scanning...';

  @override
  String get filesAdded => 'Files added!';

  @override
  String get renameSong => 'Rename Song';

  @override
  String get editInfoTitleArt => 'Edit Info (Title, Art, ...)';

  @override
  String get editAudioTrim8D => 'Edit Audio (Trim, 8D)';

  @override
  String get noResults => 'No results found';

  @override
  String get placeMusicFolder => 'Place audio files in your Music folder';

  @override
  String get songRenamed => 'Song renamed successfully';

  @override
  String get renameFailed => 'Rename failed';

  @override
  String get songDeleted => 'Song deleted successfully';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get songRemoved => 'Song removed from library';

  @override
  String removedItems(int count) {
    return 'Removed $count items from library';
  }

  @override
  String deletedItems(int count) {
    return 'Deleted $count items permanently';
  }

  @override
  String addedToPlaylist(String name) {
    return 'Added to $name';
  }

  @override
  String get alreadyInPlaylist => 'Already in playlist';

  @override
  String get noPlaylistsCreate => 'No playlists available. Create one first!';

  @override
  String get removeFromLibraryTitle => 'Remove from Library?';

  @override
  String get removeFromLibraryMsg =>
      'Hide this song from your library? The original file will remain on your device.';

  @override
  String get deleteTitle => 'Delete Permanently?';

  @override
  String get deleteMsg =>
      'Are you sure you want to permanently delete this from your device? This action cannot be undone.';

  @override
  String get remove => 'Remove';

  @override
  String get fileType => 'File Type';

  @override
  String get defaultPlayer => 'Default Audio Player';

  @override
  String get defaultPlayerMsg =>
      'Would you like to set ToneHarbor as your default audio player?';

  @override
  String get noThanks => 'No, thanks';

  @override
  String get yesOpenSettings => 'Yes, open settings';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get convertVideoBtn => 'Convert Video to Audio';

  @override
  String get moreActions => 'More Actions';

  @override
  String secondsVideo(String seconds) {
    return '$seconds Seconds Video';
  }

  @override
  String get chooseSource => 'Choose Source';

  @override
  String get gallery => 'Gallery (Videos)';

  @override
  String get files => 'Files (Videos)';

  @override
  String get selectVideoOnly => 'Please select a video file';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get noSongPlaying => 'No song playing';

  @override
  String get back => 'Back';

  @override
  String get timer => 'Timer';

  @override
  String get single => 'Single';

  @override
  String get playbackSpeed => 'Playback Speed';

  @override
  String get stopAtTimerEnd => 'Stop at Timer End';

  @override
  String get stopAtTimerEndSub => 'Stop playback after X minutes';

  @override
  String get stopAtTrackEnd => 'Stop at Track End';

  @override
  String get stopAtTrackEndSub => 'Stop playback when song finishes';

  @override
  String get stopAtPlaylistEnd => 'Stop at Playlist End';

  @override
  String get stopAtPlaylistEndSub => 'Stop playback when playlist ends';

  @override
  String get closeAppWhenStopped => 'Close app when stopped';

  @override
  String get slidePicker => 'Slide to adjust time';

  @override
  String setTimerWithMin(int minutes) {
    return 'Set Timer ($minutes min)';
  }

  @override
  String get cancelTimerBtn => 'Cancel Timer';

  @override
  String get startSleepTimer => 'Start Sleep Timer';

  @override
  String get track => 'Track';

  @override
  String get list => 'List';

  @override
  String get saveAsNewFile => 'Save as New File';

  @override
  String get replaceOriginal => 'Replace Original File';

  @override
  String savingProgress(int percent) {
    return 'Saving: $percent%';
  }

  @override
  String get audioSettings => 'Audio Settings';

  @override
  String get automaticHeadset => 'Automatic (Prefer Headset)';

  @override
  String get forceSpeaker => 'Force Internal Speaker';

  @override
  String get forceHeadset => 'Force Headset / Bluetooth';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get appSlogan => 'Modern Music Player with Video Converter';

  @override
  String get recentlyPlayed => 'Recently Played';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get songUnavailable => 'Song unavailable';

  @override
  String get rename => 'Rename';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get closeApp => 'Close App';

  @override
  String get expandToFullApp => 'Expand to Full App';

  @override
  String get overlaySettings => 'Overlay Settings';

  @override
  String get backgroundBlur => 'Background Blur';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String addedSongsToPlaylist(int count, String name) {
    return 'Added $count songs to $name';
  }

  @override
  String get notSupportedPlatform => 'Not supported on this platform';

  @override
  String get permissionWriteSettings =>
      'Permission is needed to modify system settings';

  @override
  String get ringtoneFailed => 'Failed to set ringtone';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get refreshLibrary => 'Refresh Library';

  @override
  String get storageAndCache => 'Storage & Cache';

  @override
  String get cacheSize => 'Cache Size';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheSuccess => 'Cache cleared successfully';

  @override
  String get clearCacheDesc =>
      'Delete temporary videos and files to free up space';

  @override
  String get cacheClean => 'Cache is clean (0 B)';

  @override
  String get restoreExcludedTitle => 'Add Tracks to Library';

  @override
  String get restoreExcludedPromptSingle =>
      'This track was previously removed from your library. Do you want to add it back?';

  @override
  String get restoreExcludedPromptMultiple =>
      'Found tracks that were previously removed from your library. Do you want to add them back?';

  @override
  String get restoreExcludedAction => 'Add to Library';

  @override
  String get restoreExcludedKeepHidden => 'Keep Hidden';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String restoredSongsCount(int count) {
    return 'Added $count tracks to library';
  }
}
