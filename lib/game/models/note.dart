/// Note types supported by the chart format. The renderer/judge treat them as:
///  - tap     : single timed press on a lane
///  - hold    : press at startTime, body until endTime (tail auto-resolves)
///  - slide   : like hold (horizontal flavor); judged on the head
///  - flick   : timed press with a `direction` arrow (gesture = Phase 2)
///  - double  : authored as two simultaneous notes in different lanes
///  - golden  : bonus tap, worth 2× score
///  - fever   : tap that fills the fever meter faster
enum NoteType { tap, hold, slide, flick, double, golden, fever }

NoteType _noteTypeFrom(String s) {
  switch (s) {
    case 'hold':
      return NoteType.hold;
    case 'slide':
      return NoteType.slide;
    case 'flick':
      return NoteType.flick;
    case 'double':
      return NoteType.double;
    case 'golden':
      return NoteType.golden;
    case 'fever':
      return NoteType.fever;
    default:
      return NoteType.tap;
  }
}

class Note {
  final NoteType type;
  final int lane;
  final int startTimeMs;
  final int? endTimeMs; // hold/slide tail
  final String? direction; // flick

  // ---- mutable gameplay state (not serialized) ----
  bool judged = false;
  bool holding = false; // hold currently being held
  bool holdComplete = false;

  Note({
    required this.type,
    required this.lane,
    required this.startTimeMs,
    this.endTimeMs,
    this.direction,
  });

  bool get isHold => type == NoteType.hold || type == NoteType.slide;
  int get tail => endTimeMs ?? startTimeMs;

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        type: _noteTypeFrom((j['type'] ?? 'tap') as String),
        lane: (j['lane'] ?? 0) as int,
        startTimeMs: (j['startTimeMs'] ?? 0) as int,
        endTimeMs: j['endTimeMs'] as int?,
        direction: j['direction'] as String?,
      );
}
