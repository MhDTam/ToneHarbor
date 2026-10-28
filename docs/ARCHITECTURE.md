# Architecture

ToneHarbor is a Flutter Windows app with a native C++ runner.

| Path | Responsibility |
| --- | --- |
| `lib/features/desktop/` | Shell, workspaces, players, artwork, waveforms, editing and conversion |
| `lib/services/audio/` | Playback/queue, metadata, scanning and external file opening |
| `lib/data/` | Models, repositories, preferences and library storage |
| `lib/core/` | Routing, utilities and platform helpers |
| `lib/l10n/` | English, Arabic and Persian source/generated localizations |
| `windows/runner/` | Frameless window, single-instance activation, Open with |
| `test/` | Widget, lifecycle, storage, playback, memory and FFmpeg integration tests |
| `tool/` | Build, source export and license inventory scripts |

Playback uses just_audio's Windows backend. FFmpeg processes media and extracts waveforms. Editing previews have an independent lazy player, temporary files and generation guards, preventing cancelled work from starting late.

Selection uses fixed row geometry and stable IDs. Small clock/cursor widgets observe playback position; artwork/waveform caches are bounded. Metadata workers stop at safe boundaries after file handles close.

Existing database names, preference keys, native storage identifiers and matching platform-channel names are compatibility interfaces. Resource metadata can affect Windows support-directory locations; changing it needs migration.

Videos are not automatically imported as library audio. Library removal and confirmed permanent deletion are separate actions. User media/preferences are never source-export inputs.
