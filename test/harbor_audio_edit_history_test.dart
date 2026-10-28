import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/features/desktop/harbor_audio_effects.dart';

void main() {
  test(
      'an entire trim gesture is one undo step and redo restores its exact edit',
      () {
    final history = AudioEditHistory(const AudioEditDraft(end: 60));
    history.begin();
    for (var i = 1; i <= 40; i++) {
      history.update(history.value.copyWith(start: i / 10, end: 50));
    }
    history.end();
    expect(history.retainedEdits, 1);
    expect(history.value.start, 4);
    history.undo();
    expect(history.value.start, 0);
    expect(history.value.end, 60);
    history.redo();
    expect(history.value.start, 4);
    expect(history.value.end, 50);
    expect(history.value.outputSeconds, 46);
    history.undo();
    history.update(history.value.copyWith(speed: 2));
    expect(history.canRedo, isFalse);
    expect(history.value.outputSeconds, 30);
  });
  test('edit history stays bounded and invalid effect parameters are rejected',
      () {
    final history = AudioEditHistory(const AudioEditDraft(end: 60));
    for (var i = 0; i < 1000; i++) {
      history.update(history.value.copyWith(gainDb: i.toDouble()));
    }
    expect(history.retainedEdits, 32);
    expect(
        () => const AudioEditEffects(speed: 0).validate(), throwsArgumentError);
    expect(() => const AudioEditEffects(speed: double.nan).validate(),
        throwsArgumentError);
    expect(
        () => const AudioEditEffects(bass: 13).validate(), throwsArgumentError);
    expect(() => const AudioEditEffects(channels: 7).validate(),
        throwsArgumentError);
    expect(const AudioEditDraft(gainDb: 0).volume, 1);
    expect(audioEditSampleRates('opus'), [48000]);
    expect(audioEditSampleRates('mp3'), isNot(contains(96000)));
    expect(audioEditBitrates('mp3', 22050).last, 160);
  });
}
