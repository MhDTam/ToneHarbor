# Local tools

`ffmpeg.exe` is ignored by Git and excluded from source archives.

Install FFmpeg on `PATH` or put the executable here. The application checks `tools/ffmpeg.exe` beside its executable, then in the working directory, then `ffmpeg` on `PATH`. Full export tests need MP3 (`libmp3lame`), AAC, FLAC, Vorbis (`libvorbis`) and Opus (`libopus`) encoders.

The development reference was FFmpeg 6.0 full build from Gyan. The supplied `FFmpeg-LICENSE.txt` and `FFmpeg-BUILD-INFO.txt` describe that reference. Different builds require their actual licensing/build information.

Do not commit application or FFmpeg executables. Binary distribution is separate; see [third-party notices](../THIRD_PARTY_NOTICES.md). Optional Dart probes use synthetic media and write to ignored `output/`.
