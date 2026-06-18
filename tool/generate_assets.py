#!/usr/bin/env python3
"""
Beat Nusantara — procedural asset generator.

Generates 100% ORIGINAL, license-safe audio (pure-stdlib synthesis) together with
the gameplay chart that is *beat-aligned to that exact audio*. One source of truth:
the same beat grid that places audible lead "plucks" also emits the tap/hold/flick
notes — so when the player taps on the note, it lands on the music.

Outputs:
  assets/audio/songs/<id>.wav      (mono 22050 Hz 16-bit)
  assets/audio/sfx/*.wav           (hit / perfect / miss feedback)
  assets/charts/<id>__<diff>.json  (chart/beatmap consumed by chart_loader.dart)

No external packages required (uses `wave`, `struct`, `math`, `random`, `json`).
Re-run anytime:  python3 tool/generate_assets.py
"""
import json, math, os, random, struct, wave, zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SR = 22050  # sample rate

# ----------------------------------------------------------------------------
# Low-level synthesis (pure python, additive + simple envelopes)
# ----------------------------------------------------------------------------

def _osc(t, freq, kind):
    p = 2 * math.pi * freq * t
    if kind == "sine":
        return math.sin(p)
    if kind == "tri":
        return (2 / math.pi) * math.asin(math.sin(p))
    if kind == "square":
        return 1.0 if math.sin(p) >= 0 else -1.0
    if kind == "saw":
        x = (freq * t) % 1.0
        return 2 * x - 1
    return math.sin(p)


def add_tone(buf, start_s, dur_s, freq, vol=0.3, kind="tri", attack=0.005, release=0.08):
    """Mix a single enveloped tone into the float buffer in-place."""
    i0 = int(start_s * SR)
    n = int(dur_s * SR)
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    for i in range(n):
        idx = i0 + i
        if idx < 0 or idx >= len(buf):
            continue
        t = i / SR
        if i < a:
            env = i / a
        elif i > n - r:
            env = max(0.0, (n - i) / r)
        else:
            env = 1.0
        buf[idx] += vol * env * _osc(t, freq, kind)


def add_kick(buf, start_s, vol=0.55):
    """Punchy sine kick with pitch drop."""
    i0 = int(start_s * SR)
    n = int(0.16 * SR)
    for i in range(n):
        idx = i0 + i
        if idx < 0 or idx >= len(buf):
            continue
        t = i / SR
        f = 120 * math.exp(-t * 22) + 45
        env = math.exp(-t * 16)
        buf[idx] += vol * env * math.sin(2 * math.pi * f * t)


def add_hat(buf, start_s, vol=0.12):
    """Short noise burst hi-hat."""
    i0 = int(start_s * SR)
    n = int(0.04 * SR)
    for i in range(n):
        idx = i0 + i
        if idx < 0 or idx >= len(buf):
            continue
        env = math.exp(-i / n * 6)
        buf[idx] += vol * env * (random.random() * 2 - 1)


def add_metallic(buf, start_s, dur_s, freq, vol, ratios, decay, shimmer=0.0):
    """Inharmonic struck-metal tone — gamelan bonang/saron/gong flavour.
    Partials at non-integer ratios + optional beating shimmer."""
    i0 = int(start_s * SR)
    n = int(dur_s * SR)
    norm = len(ratios) * (2 if shimmer > 0 else 1)
    for i in range(n):
        idx = i0 + i
        if idx < 0 or idx >= len(buf):
            continue
        t = i / SR
        env = math.exp(-t * decay)
        s = 0.0
        for r in ratios:
            f = freq * r
            s += math.sin(2 * math.pi * f * t)
            if shimmer > 0:
                s += math.sin(2 * math.pi * f * (1 + shimmer) * t)
        buf[idx] += vol * env * (s / norm)


def write_wav(path, buf):
    # soft-clip + normalize
    peak = max(1e-6, max(abs(x) for x in buf))
    norm = 0.92 / peak if peak > 0.92 else 1.0
    frames = bytearray()
    for x in buf:
        v = x * norm
        v = math.tanh(v)  # gentle saturation
        s = int(max(-1.0, min(1.0, v)) * 32767)
        frames += struct.pack("<h", s)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(frames))


# ----------------------------------------------------------------------------
# Musical helpers
# ----------------------------------------------------------------------------

def midi_to_hz(m):
    return 440.0 * (2 ** ((m - 69) / 12))

# scale degree sets (semitone offsets from root)
SCALES = {
    "minor_pent": [0, 3, 5, 7, 10],
    "major_pent": [0, 2, 4, 7, 9],
    "pelog_ish":  [0, 1, 3, 7, 8],     # gamelan-evoking (original, not a real tuning)
    "dorian":     [0, 2, 3, 5, 7, 9, 10],
}

DIRS = ["left", "right", "up", "down"]


# ----------------------------------------------------------------------------
# Song definitions  (all fictional / original — no real songs or artists)
# ----------------------------------------------------------------------------

SONGS = [
    # the 3 original demos (kept)
    {"id": "senja_jakarta", "bpm": 88, "bars": 20, "root": 57, "scale": "minor_pent", "kind": "tri", "lanes": 4, "energy": 0.45, "diffs": ["Easy", "Normal"]},
    {"id": "gamelan_pulse", "bpm": 124, "bars": 24, "root": 60, "scale": "pelog_ish", "kind": "square", "lanes": 4, "energy": 0.7, "diffs": ["Normal", "Hard"]},
    {"id": "koplo_neon", "bpm": 140, "bars": 24, "root": 62, "scale": "dorian", "kind": "saw", "lanes": 5, "energy": 0.95, "diffs": ["Normal", "Hard", "Expert"]},
    # 17 more (all original, license-safe) — ids match assets/song_manifest.json
    {"id": "melati_senja", "bpm": 102, "bars": 16, "root": 60, "scale": "major_pent", "kind": "tri", "lanes": 4, "energy": 0.55, "diffs": ["Easy", "Normal", "Hard"]},
    {"id": "hujan_neon", "bpm": 116, "bars": 16, "root": 62, "scale": "major_pent", "kind": "tri", "lanes": 4, "energy": 0.6, "diffs": ["Normal", "Hard"]},
    {"id": "sambal_bass", "bpm": 145, "bars": 16, "root": 62, "scale": "dorian", "kind": "saw", "lanes": 5, "energy": 0.9, "diffs": ["Normal", "Hard"]},
    {"id": "goyang_galaksi", "bpm": 128, "bars": 16, "root": 60, "scale": "dorian", "kind": "saw", "lanes": 4, "energy": 0.8, "diffs": ["Normal", "Hard"]},
    {"id": "sasando_drift", "bpm": 120, "bars": 16, "root": 60, "scale": "pelog_ish", "kind": "tri", "lanes": 4, "energy": 0.65, "diffs": ["Normal", "Hard"]},
    {"id": "angklung_arcade", "bpm": 130, "bars": 16, "root": 64, "scale": "major_pent", "kind": "square", "lanes": 4, "energy": 0.8, "diffs": ["Normal", "Hard"]},
    {"id": "tokyo_kilat", "bpm": 150, "bars": 16, "root": 64, "scale": "major_pent", "kind": "saw", "lanes": 5, "energy": 0.9, "diffs": ["Normal", "Hard", "Expert"]},
    {"id": "seoul_mirror", "bpm": 124, "bars": 16, "root": 57, "scale": "minor_pent", "kind": "square", "lanes": 4, "energy": 0.8, "diffs": ["Normal", "Hard"]},
    {"id": "midnight_avenue", "bpm": 118, "bars": 16, "root": 60, "scale": "major_pent", "kind": "tri", "lanes": 4, "energy": 0.6, "diffs": ["Normal", "Hard"]},
    {"id": "concrete_flow", "bpm": 92, "bars": 16, "root": 55, "scale": "minor_pent", "kind": "square", "lanes": 4, "energy": 0.55, "diffs": ["Normal", "Hard"]},
    {"id": "voltage", "bpm": 128, "bars": 16, "root": 62, "scale": "dorian", "kind": "saw", "lanes": 4, "energy": 0.85, "diffs": ["Normal", "Hard"]},
    {"id": "deep_jakarta", "bpm": 122, "bars": 16, "root": 57, "scale": "minor_pent", "kind": "saw", "lanes": 4, "energy": 0.75, "diffs": ["Normal", "Hard"]},
    {"id": "phonk_pasar", "bpm": 138, "bars": 16, "root": 55, "scale": "minor_pent", "kind": "square", "lanes": 5, "energy": 0.9, "diffs": ["Hard", "Expert"]},
    {"id": "hyper_melati", "bpm": 160, "bars": 16, "root": 64, "scale": "major_pent", "kind": "saw", "lanes": 5, "energy": 0.95, "diffs": ["Hard", "Expert"]},
    {"id": "ombak_tenang", "bpm": 80, "bars": 14, "root": 57, "scale": "minor_pent", "kind": "tri", "lanes": 4, "energy": 0.4, "diffs": ["Easy", "Normal"]},
    {"id": "kopi_pagi", "bpm": 84, "bars": 14, "root": 60, "scale": "major_pent", "kind": "tri", "lanes": 4, "energy": 0.42, "diffs": ["Easy", "Normal"]},
    {"id": "garuda_rising", "bpm": 174, "bars": 16, "root": 62, "scale": "dorian", "kind": "saw", "lanes": 5, "energy": 1.0, "diffs": ["Hard", "Expert"]},
]

DIFF_DENSITY = {"Easy": 0.5, "Normal": 0.72, "Hard": 0.9, "Expert": 1.0}


def build_song(spec):
    bpm = spec["bpm"]
    beat = 60.0 / bpm
    step = beat / 2.0           # eighth-note grid
    bars = spec["bars"]
    steps = bars * 8            # 8 eighths per 4/4 bar
    total_s = steps * step + 1.0
    buf = [0.0] * int(total_s * SR)
    scale = SCALES[spec["scale"]]
    root = spec["root"]
    lanes = spec["lanes"]
    rng = random.Random(zlib.crc32(spec["id"].encode()))  # stable across runs (not Python's randomized hash)

    # --- backing track: kick on the beat, hats on offbeats, bass on downbeats ---
    for s in range(steps):
        t = s * step
        if s % 2 == 0:
            add_kick(buf, t, vol=0.5 + 0.1 * spec["energy"])
        else:
            add_hat(buf, t, vol=0.10)
        if s % 8 == 0:  # bar downbeat bass
            bass_f = midi_to_hz(root - 12 + scale[(s // 8) % len(scale)])
            add_tone(buf, t, beat * 1.5, bass_f, vol=0.34, kind="sine", release=0.25)

    # --- lead melody + the chart notes share the SAME placement loop ---
    notes_by_diff = {d: [] for d in spec["diffs"]}
    prev_lane = 0
    for s in range(steps):
        t = s * step
        # melodic pluck on most onsets (every step in busy songs, every other in chill)
        place_lead = (s % 1 == 0) if spec["energy"] > 0.6 else (s % 2 == 0 or rng.random() < 0.35)
        if not place_lead:
            continue
        deg = scale[(s * 2 + (s // 8)) % len(scale)]
        octave = 12 * (1 + (1 if (s % 8) in (4, 6) else 0))
        freq = midi_to_hz(root + octave + deg)
        add_tone(buf, t, step * 0.9, freq, vol=0.26, kind=spec["kind"], release=0.10)

        # lane chosen to flow (avoid big jumps), deterministic per step
        lane = (prev_lane + 1 + (s % (lanes - 1))) % lanes
        prev_lane = lane
        start_ms = int(t * 1000)

        # decide a base note type for this onset (shared design), then each
        # difficulty subsamples by density so all charts stay musically aligned.
        onset_type, extra = _pick_type(s, steps, rng, lanes, beat)

        for d in spec["diffs"]:
            if rng.random() > DIFF_DENSITY[d]:
                continue
            note = {"type": onset_type, "lane": lane, "startTimeMs": start_ms}
            if onset_type in ("hold", "slide"):
                note["endTimeMs"] = start_ms + int(extra * 1000)
            if onset_type == "flick":
                note["direction"] = DIRS[s % len(DIRS)]
            notes_by_diff[d].append(note)
            # doubles only on higher difficulties
            if onset_type == "double" and d in ("Hard", "Expert"):
                notes_by_diff[d].append({
                    "type": "tap", "lane": (lane + 2) % lanes, "startTimeMs": start_ms})

    write_wav(os.path.join(ROOT, "assets/audio/songs", spec["id"] + ".wav"), buf)

    charts = {}
    for d in spec["diffs"]:
        ns = sorted(notes_by_diff[d], key=lambda n: (n["startTimeMs"], n["lane"]))
        chart = {
            "songId": spec["id"],
            "difficulty": d,
            "bpm": bpm,
            "offsetMs": 0,
            "notes": ns,
        }
        fn = "%s__%s.json" % (spec["id"], d.lower())
        with open(os.path.join(ROOT, "assets/charts", fn), "w") as f:
            json.dump(chart, f, indent=1)
        charts[d] = "assets/charts/" + fn
    return total_s, charts, {d: len(notes_by_diff[d]) for d in spec["diffs"]}


def _pick_type(s, steps, rng, lanes, beat):
    """Deterministic-ish note type for variety. Returns (type, holdLenSeconds)."""
    pos = s % 16
    if pos == 0:
        return "fever", 0
    if pos in (7, 15):
        return "golden", 0
    if pos in (4, 12):
        return "hold", beat * 1.5
    if pos in (10,):
        return "flick", 0
    if pos in (2, 6) and lanes >= 5:
        return "double", 0
    if pos in (8,):
        return "slide", beat
    return "tap", 0


def main():
    # --- SFX (short, original) ---
    hit = [0.0] * int(0.10 * SR)
    add_tone(hit, 0, 0.09, 880, vol=0.5, kind="tri", release=0.05)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/hit.wav"), hit)

    perfect = [0.0] * int(0.18 * SR)
    add_tone(perfect, 0, 0.08, 1175, vol=0.45, kind="tri", release=0.05)
    add_tone(perfect, 0.05, 0.10, 1568, vol=0.45, kind="tri", release=0.06)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/perfect.wav"), perfect)

    miss = [0.0] * int(0.16 * SR)
    add_tone(miss, 0, 0.14, 196, vol=0.5, kind="square", release=0.10)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/miss.wav"), miss)

    # combo milestone — bright bonang/saron "ting" (gamelan)
    combo = [0.0] * int(0.5 * SR)
    add_metallic(combo, 0, 0.46, 740, 0.5, [1, 2.76, 5.40, 8.9], decay=10, shimmer=0.004)
    add_tone(combo, 0, 0.16, 1480, vol=0.22, kind="tri", release=0.1)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/combo.wav"), combo)

    # fever activation — gong ageng (deep, long, shimmering) + bright accent
    fever = [0.0] * int(1.7 * SR)
    add_metallic(fever, 0, 1.6, 98, 0.55, [1, 2.4, 3.8, 5.9, 8.2], decay=2.2, shimmer=0.006)
    add_metallic(fever, 0.02, 0.9, 392, 0.18, [1, 2.7, 5.1], decay=5, shimmer=0.012)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/fever.wav"), fever)

    manifest_fragment = []
    for spec in SONGS:
        dur_s, charts, counts = build_song(spec)
        manifest_fragment.append({
            "id": spec["id"], "durationMs": int(dur_s * 1000),
            "charts": charts, "noteCounts": counts,
        })
        print("✔ %-16s %4d bpm  %5.1fs  notes=%s" % (
            spec["id"], spec["bpm"], dur_s, counts))

    with open(os.path.join(ROOT, "tool", "_generated_manifest.json"), "w") as f:
        json.dump(manifest_fragment, f, indent=2)
    print("\nWrote 3 songs + 7 charts + 3 sfx. Manifest fragment -> tool/_generated_manifest.json")


if __name__ == "__main__":
    main()
