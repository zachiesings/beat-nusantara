#!/usr/bin/env python3
"""
Beat Nusantara — procedural MUSIC + chart generator (v2, "real-song" engine).

100% ORIGINAL, license-safe audio synthesised from pure stdlib. Unlike v1 (which
just walked a pentatonic scale over a kick), v2 composes actual *songs*:

  • chord progressions (pop / dangdut-koplo / EDM / city-pop / phonk / lo-fi)
  • song structure  intro → verse → chorus → bridge → chorus → outro
  • a repeating melodic HOOK (motif) in the chorus so it's catchy
  • layered arrangement: sub-bass, bassline, chord stabs/pads, supersaw lead,
    plus a full drum kit (kick / snare / clap / closed+open hi-hat)
  • per-genre grooves, Indonesian-dominant (koplo, gamelan, angklung, suling
    timbres) with worldwide flavours (EDM, K/J-pop, phonk) mixed in.

The gameplay chart is generated FROM the lead hook, so tapping a note lands on
the melody. A 2-bar INTRO (no notes) gives every chart a proper lead-in, so the
first note can never reach the hit-line before the player can react.

Outputs (committed to the repo):
  assets/audio/songs/<id>.wav      (mono 22050 Hz 16-bit)
  assets/audio/sfx/*.wav , bgm/menu_loop.wav
  assets/charts/<id>__<diff>.json
  tool/_generated_manifest.json    (durations + note counts; fed into manifest)

Pure stdlib (wave/struct/math/random/zlib). Slow path is mitigated by a
one-shot voice RENDER CACHE — repeated notes are synthesised once and blitted.

Usage:
  python3 tool/generate_assets.py                 # everything
  python3 tool/generate_assets.py senja_jakarta   # one song (for iteration)
  python3 tool/generate_assets.py --songs-only    # skip sfx/menu
"""
import json, math, os, random, struct, sys, wave, zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SR = 22050

# ============================================================================
# Low-level synthesis
# ============================================================================

def _saw(ph):   return 2.0 * (ph - math.floor(ph + 0.5))
def _square(ph):return 1.0 if (ph % 1.0) < 0.5 else -1.0
def _tri(ph):   return 2.0 * abs(_saw(ph)) - 1.0
def _sine(ph):  return math.sin(2 * math.pi * ph)

def midi_to_hz(m): return 440.0 * (2 ** ((m - 69) / 12.0))

def _adsr(n, a, d, s, r):
    """Per-sample ADSR envelope of length n (samples)."""
    a = max(1, int(a * SR)); d = max(1, int(d * SR)); r = max(1, int(r * SR))
    env = [0.0] * n
    for i in range(n):
        if i < a:
            env[i] = i / a
        elif i < a + d:
            env[i] = 1.0 - (1.0 - s) * (i - a) / d
        elif i < n - r:
            env[i] = s
        else:
            env[i] = s * max(0.0, (n - i) / r)
    return env

def _lowpass(buf, alpha):
    """Cheap one-pole low-pass in place (alpha 0..1, lower = darker)."""
    y = 0.0
    for i in range(len(buf)):
        y += alpha * (buf[i] - y)
        buf[i] = y
    return buf

# ---- voice render cache: synth each unique (instrument,freq,dur) once --------
_VOICE_CACHE = {}

def render_voice(inst, freq, dur):
    key = (inst, round(freq, 1), round(dur, 3))
    cached = _VOICE_CACHE.get(key)
    if cached is not None:
        return cached
    out = _render_voice(inst, freq, dur)
    _VOICE_CACHE[key] = out
    return out

def _render_voice(inst, freq, dur):
    n = max(1, int(dur * SR))
    buf = [0.0] * n
    sp = freq / SR  # phase increment per sample

    if inst == "sub":  # deep sine sub-bass
        env = _adsr(n, 0.006, 0.05, 0.85, 0.08)
        ph = 0.0
        for i in range(n):
            buf[i] = 0.9 * env[i] * _sine(ph); ph += sp
        return buf

    if inst == "bass":  # round saw bass, low-passed
        env = _adsr(n, 0.005, 0.06, 0.7, 0.07)
        ph = 0.0
        for i in range(n):
            buf[i] = env[i] * (0.7 * _saw(ph) + 0.5 * _sine(ph)); ph += sp
        _lowpass(buf, 0.18)
        return buf

    if inst == "pluck":  # short decaying tri/saw — koplo/pop lead body
        env = _adsr(n, 0.004, 0.10, 0.0, 0.06)
        ph = 0.0
        for i in range(n):
            buf[i] = env[i] * (0.6 * _tri(ph) + 0.25 * _saw(ph * 2)); ph += sp
        return buf

    if inst == "lead":  # bright supersaw (detuned) lead for choruses
        env = _adsr(n, 0.006, 0.08, 0.75, 0.09)
        dets = (0.994, 1.0, 1.006)
        ph = [0.0, 0.0, 0.0]
        for i in range(n):
            s = 0.0
            for k, dt in enumerate(dets):
                s += _saw(ph[k]); ph[k] += sp * dt
            buf[i] = env[i] * 0.34 * s
        _lowpass(buf, 0.5)
        return buf

    if inst == "stab":  # plucky chord-stab voice (one note of a chord)
        env = _adsr(n, 0.004, 0.12, 0.35, 0.10)
        ph = 0.0
        for i in range(n):
            buf[i] = env[i] * (0.5 * _saw(ph) + 0.3 * _square(ph)); ph += sp
        _lowpass(buf, 0.4)
        return buf

    if inst == "pad":  # soft sustained pad (one note of a chord)
        env = _adsr(n, 0.18, 0.2, 0.8, 0.4)
        ph = 0.0; ph2 = 0.0
        for i in range(n):
            buf[i] = env[i] * 0.4 * (_sine(ph) + 0.5 * _sine(ph2)); ph += sp; ph2 += sp * 2
        return buf

    if inst == "bell":  # gamelan/angklung struck-metal — inharmonic partials
        ratios = (1.0, 2.76, 5.40, 8.93)
        env = [math.exp(-i / SR * 7.0) for i in range(n)]
        for i in range(n):
            t = i / SR; s = 0.0
            for r in ratios:
                s += math.sin(2 * math.pi * freq * r * t)
            buf[i] = env[i] * 0.22 * s / len(ratios)
        return buf

    if inst == "flute":  # suling-ish breathy sine lead
        env = _adsr(n, 0.04, 0.05, 0.8, 0.12)
        ph = 0.0
        for i in range(n):
            vib = 1.0 + 0.006 * math.sin(2 * math.pi * 5.0 * i / SR)
            buf[i] = env[i] * 0.5 * (_sine(ph) + 0.12 * _sine(ph * 2)); ph += sp * vib
        return buf

    # default fallback
    env = _adsr(n, 0.01, 0.1, 0.4, 0.1); ph = 0.0
    for i in range(n):
        buf[i] = env[i] * 0.4 * _tri(ph); ph += sp
    return buf

# ---- drums (rendered once, cached) -----------------------------------------
_DRUM_CACHE = {}

def render_drum(kind):
    d = _DRUM_CACHE.get(kind)
    if d is not None:
        return d
    d = _render_drum(kind)
    _DRUM_CACHE[kind] = d
    return d

def _render_drum(kind):
    if kind == "kick":
        n = int(0.18 * SR); buf = [0.0] * n
        for i in range(n):
            t = i / SR
            f = 115 * math.exp(-t * 26) + 48
            buf[i] = math.exp(-t * 14) * math.sin(2 * math.pi * f * t)
        return buf
    if kind == "snare":
        n = int(0.16 * SR); buf = [0.0] * n
        for i in range(n):
            t = i / SR
            tone = 0.5 * math.sin(2 * math.pi * 190 * t) * math.exp(-t * 26)
            noise = (random.random() * 2 - 1) * math.exp(-t * 22)
            buf[i] = 0.7 * (tone + noise)
        _lowpass(buf, 0.7)
        return buf
    if kind == "clap":
        n = int(0.16 * SR); buf = [0.0] * n
        bursts = (0.0, 0.012, 0.024)
        for i in range(n):
            t = i / SR; s = 0.0
            for b in bursts:
                if t >= b:
                    s += (random.random() * 2 - 1) * math.exp(-(t - b) * 40)
            buf[i] = 0.5 * s
        _lowpass(buf, 0.8)
        return buf
    if kind == "hatC":
        n = int(0.035 * SR); buf = [0.0] * n
        for i in range(n):
            buf[i] = 0.4 * (random.random() * 2 - 1) * math.exp(-i / n * 5)
        return buf
    if kind == "hatO":
        n = int(0.13 * SR); buf = [0.0] * n
        for i in range(n):
            buf[i] = 0.32 * (random.random() * 2 - 1) * math.exp(-i / n * 2.2)
        return buf
    if kind == "rim":
        n = int(0.05 * SR); buf = [0.0] * n
        for i in range(n):
            t = i / SR
            buf[i] = 0.4 * math.sin(2 * math.pi * 420 * t) * math.exp(-t * 60)
        return buf
    return [0.0]

# ---- mixing -----------------------------------------------------------------

def mix(buf, voice, start_s, gain):
    o = int(start_s * SR)
    if o < 0:
        voice = voice[-o:]; o = 0
    L = len(voice)
    end = o + L
    if end > len(buf):
        L = len(buf) - o; end = len(buf)
        if L <= 0:
            return
        voice = voice[:L]
    seg = buf[o:end]
    buf[o:end] = [seg[i] + voice[i] * gain for i in range(L)]

def write_wav(path, buf):
    peak = max(1e-6, max(abs(x) for x in buf))
    norm = 0.95 / peak if peak > 0.95 else 1.0
    frames = bytearray()
    for x in buf:
        v = math.tanh(x * norm * 1.05)
        frames += struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(bytes(frames))

# ============================================================================
# Music theory
# ============================================================================

SCALES = {
    "major":      [0, 2, 4, 5, 7, 9, 11],
    "minor":      [0, 2, 3, 5, 7, 8, 10],
    "dorian":     [0, 2, 3, 5, 7, 9, 10],
    "major_pent": [0, 2, 4, 7, 9],
    "minor_pent": [0, 3, 5, 7, 10],
    "pelog_ish":  [0, 1, 3, 7, 8],   # gamelan-evoking (original, not a real tuning)
}

CHORD_Q = {
    "maj":  [0, 4, 7], "min":  [0, 3, 7],
    "maj7": [0, 4, 7, 11], "min7": [0, 3, 7, 10], "dom7": [0, 4, 7, 10],
    "sus4": [0, 5, 7],
}

# progressions as (root-offset-from-tonic, quality), 1 chord per bar (looped)
PROGRESSIONS = {
    "pop":     [(0, "maj"), (7, "maj"), (9, "min"), (5, "maj")],          # I–V–vi–IV
    "pop_emo": [(9, "min"), (5, "maj"), (0, "maj"), (7, "maj")],          # vi–IV–I–V
    "citypop": [(0, "maj7"), (9, "min7"), (5, "maj7"), (7, "dom7")],
    "kpop":    [(0, "maj"), (4, "min"), (5, "maj"), (7, "maj")],          # I–iii–IV–V
    "dangdut": [(0, "min"), (10, "maj"), (8, "maj"), (7, "dom7")],        # Andalusian i–VII–VI–V
    "koplo":   [(0, "min"), (5, "min"), (10, "maj"), (7, "dom7")],
    "edm_min": [(0, "min"), (8, "maj"), (3, "maj"), (10, "maj")],         # i–VI–III–VII
    "edm_maj": [(9, "min"), (5, "maj"), (0, "maj"), (7, "maj")],
    "phonk":   [(0, "min"), (0, "min"), (8, "maj"), (10, "maj")],
    "lofi":    [(0, "min7"), (5, "min7"), (10, "maj7"), (3, "maj7")],
}

# melodic hook templates. rhythm = sixteenth-step onsets in a 2-bar (32-step)
# phrase; contour = relative scale-step movement applied across those onsets.
HOOKS = [
    {"rhythm": [0, 4, 8, 12, 16, 20, 24, 28],            "contour": [0, 2, 1, 3, 2, 4, 3, 1]},
    {"rhythm": [0, 6, 8, 14, 16, 22, 24, 30],            "contour": [0, 1, 2, 1, 3, 2, 1, 0]},
    {"rhythm": [0, 2, 4, 8, 12, 16, 20, 24, 28],         "contour": [4, 3, 2, 0, 1, 4, 3, 2, 0]},
    {"rhythm": [0, 4, 6, 8, 12, 16, 18, 20, 24, 28, 30], "contour": [0, 1, 2, 3, 2, 0, 1, 2, 3, 4, 2]},
    {"rhythm": [0, 3, 6, 8, 11, 16, 19, 22, 24, 27],     "contour": [0, 2, 4, 3, 1, 0, 2, 4, 3, 1]},  # syncopated
]

# drum grooves over one bar = 16 sixteenth steps. beats land on 0,4,8,12.
GROOVES = {
    "pop":     {"kick": [0, 8, 10], "snare": [4, 12], "hatC": [0,2,4,6,8,10,12,14], "hatO": [], "clap": []},
    "edm":     {"kick": [0, 4, 8, 12], "snare": [], "hatC": [2,6,10,14], "hatO": [2,6,10,14], "clap": [4,12]},
    "koplo":   {"kick": [0, 3, 6, 8, 11, 14], "snare": [4, 12], "hatC": [0,2,4,6,8,10,12,14], "hatO": [], "rim": [2,6,10,14]},
    "dangdut": {"kick": [0, 6, 8, 11], "snare": [4, 12], "hatC": [0,2,4,6,8,10,12,14], "hatO": [], "rim": [3,7,10,14]},
    "phonk":   {"kick": [0, 7], "snare": [8], "hatC": [0,2,4,6,8,10,12,14], "hatO": [], "clap": []},
    "lofi":    {"kick": [0, 8, 10], "snare": [4, 12], "hatC": [0,3,4,7,8,11,12,15], "hatO": [], "clap": []},
    "citypop": {"kick": [0, 8, 11], "snare": [4, 12], "hatC": [0,2,4,6,8,10,12,14], "hatO": [6,14], "clap": []},
    "kpop":    {"kick": [0, 6, 8, 12], "snare": [], "hatC": [0,2,4,6,8,10,12,14], "hatO": [], "clap": [4,12]},
}

DIRS = ["left", "right", "up", "down"]
DIFF_DENSITY = {"Easy": 0.5, "Normal": 0.72, "Hard": 0.9, "Expert": 1.0}

# section plan: (name, bars). intro/outro carry NO chart notes. Sized so songs
# land roughly in a 52–82s window regardless of tempo (slow songs get trimmed).
def section_plan(bpm):
    bar_s = 4 * 60.0 / bpm
    full = [("intro", 2), ("verse", 8), ("chorus", 8), ("bridge", 4), ("verse", 4), ("chorus", 8), ("outro", 2)]
    mid  = [("intro", 2), ("verse", 8), ("chorus", 8), ("verse", 4), ("chorus", 6), ("outro", 2)]
    short = [("intro", 2), ("verse", 6), ("chorus", 8), ("chorus", 6), ("outro", 2)]
    for plan in (full, mid, short):
        if sum(b for _, b in plan) * bar_s <= 82:
            return plan
    return short

# ============================================================================
# Song specs — 20 originals. groove/progression chosen per vibe.
# Indonesian-dominant (koplo/dangdut/gamelan/angklung) + worldwide (EDM/pop/phonk)
# ============================================================================

SONGS = [
    {"id": "senja_jakarta",  "bpm": 90,  "root": 57, "scale": "minor_pent", "prog": "lofi",    "groove": "lofi",    "lead": "pluck", "flavor": "bell",  "lanes": 4, "energy": 0.45, "diffs": ["Easy", "Normal"]},
    {"id": "gamelan_pulse",  "bpm": 124, "root": 60, "scale": "pelog_ish",  "prog": "edm_min", "groove": "edm",     "lead": "bell",  "flavor": "bell",  "lanes": 4, "energy": 0.72, "diffs": ["Normal", "Hard"]},
    {"id": "koplo_neon",     "bpm": 140, "root": 62, "scale": "dorian",     "prog": "koplo",   "groove": "koplo",   "lead": "lead",  "flavor": "flute", "lanes": 5, "energy": 0.95, "diffs": ["Normal", "Hard", "Expert"]},
    {"id": "melati_senja",   "bpm": 100, "root": 60, "scale": "major_pent", "prog": "pop_emo", "groove": "pop",     "lead": "pluck", "flavor": "bell",  "lanes": 4, "energy": 0.55, "diffs": ["Easy", "Normal", "Hard"]},
    {"id": "hujan_neon",     "bpm": 116, "root": 62, "scale": "major",      "prog": "pop",     "groove": "citypop", "lead": "lead",  "flavor": None,    "lanes": 4, "energy": 0.62, "diffs": ["Normal", "Hard"]},
    {"id": "sambal_bass",    "bpm": 145, "root": 62, "scale": "dorian",     "prog": "koplo",   "groove": "koplo",   "lead": "lead",  "flavor": "flute", "lanes": 5, "energy": 0.9,  "diffs": ["Normal", "Hard"]},
    {"id": "goyang_galaksi", "bpm": 128, "root": 60, "scale": "minor",      "prog": "dangdut", "groove": "dangdut", "lead": "lead",  "flavor": "flute", "lanes": 4, "energy": 0.8,  "diffs": ["Normal", "Hard"]},
    {"id": "sasando_drift",  "bpm": 118, "root": 60, "scale": "pelog_ish",  "prog": "edm_maj", "groove": "citypop", "lead": "bell",  "flavor": "bell",  "lanes": 4, "energy": 0.65, "diffs": ["Normal", "Hard"]},
    {"id": "angklung_arcade","bpm": 130, "root": 64, "scale": "major_pent", "prog": "pop",     "groove": "pop",     "lead": "bell",  "flavor": "bell",  "lanes": 4, "energy": 0.8,  "diffs": ["Normal", "Hard"]},
    {"id": "tokyo_kilat",    "bpm": 150, "root": 64, "scale": "major",      "prog": "citypop", "groove": "citypop", "lead": "lead",  "flavor": None,    "lanes": 5, "energy": 0.9,  "diffs": ["Normal", "Hard", "Expert"]},
    {"id": "seoul_mirror",   "bpm": 124, "root": 57, "scale": "minor",      "prog": "kpop",    "groove": "kpop",    "lead": "lead",  "flavor": None,    "lanes": 4, "energy": 0.8,  "diffs": ["Normal", "Hard"]},
    {"id": "midnight_avenue","bpm": 112, "root": 60, "scale": "major",      "prog": "citypop", "groove": "citypop", "lead": "lead",  "flavor": None,    "lanes": 4, "energy": 0.6,  "diffs": ["Normal", "Hard"]},
    {"id": "concrete_flow",  "bpm": 92,  "root": 55, "scale": "minor_pent", "prog": "lofi",    "groove": "lofi",    "lead": "pluck", "flavor": None,    "lanes": 4, "energy": 0.55, "diffs": ["Normal", "Hard"]},
    {"id": "voltage",        "bpm": 128, "root": 62, "scale": "minor",      "prog": "edm_min", "groove": "edm",     "lead": "lead",  "flavor": None,    "lanes": 4, "energy": 0.85, "diffs": ["Normal", "Hard"]},
    {"id": "deep_jakarta",   "bpm": 122, "root": 57, "scale": "minor",      "prog": "edm_min", "groove": "edm",     "lead": "lead",  "flavor": None,    "lanes": 4, "energy": 0.75, "diffs": ["Normal", "Hard"]},
    {"id": "phonk_pasar",    "bpm": 138, "root": 55, "scale": "minor",      "prog": "phonk",   "groove": "phonk",   "lead": "lead",  "flavor": "bell",  "lanes": 5, "energy": 0.9,  "diffs": ["Hard", "Expert"]},
    {"id": "hyper_melati",   "bpm": 160, "root": 64, "scale": "major",      "prog": "kpop",    "groove": "edm",     "lead": "lead",  "flavor": None,    "lanes": 5, "energy": 0.95, "diffs": ["Hard", "Expert"]},
    {"id": "ombak_tenang",   "bpm": 84,  "root": 57, "scale": "minor_pent", "prog": "lofi",    "groove": "lofi",    "lead": "flute", "flavor": "bell",  "lanes": 4, "energy": 0.4,  "diffs": ["Easy", "Normal"]},
    {"id": "kopi_pagi",      "bpm": 88,  "root": 60, "scale": "major_pent", "prog": "pop_emo", "groove": "lofi",    "lead": "pluck", "flavor": "bell",  "lanes": 4, "energy": 0.42, "diffs": ["Easy", "Normal"]},
    {"id": "garuda_rising",  "bpm": 172, "root": 62, "scale": "minor",      "prog": "edm_min", "groove": "edm",     "lead": "lead",  "flavor": "flute", "lanes": 5, "energy": 1.0,  "diffs": ["Hard", "Expert"]},
]

# ============================================================================
# FOLK MELODY ENGINE — real public-domain Indonesian lagu daerah / lagu rakyat.
# Melodies encoded as (midi, beats) in a C reference (60=C4), 0=rest. These are
# BEST-EFFORT reconstructions from memory of traditional, anonymous, public-
# domain tunes — NOT commercial copyrighted songs. Verify by ear & correct the
# note arrays as needed; the rhythm engine plays whatever notes are here.
# ============================================================================

SEMI = {1: 0, 2: 2, 3: 4, 4: 5, 5: 7, 6: 9, 7: 11}  # major-scale degree -> semitone

def _na(lines):
    """Parse notasi angka (moveable do, 1=do..7=si; trailing ' = +oct, , = -oct,
    0 = rest) into (midi, beats) with do=60. 0.5 beat/note, 1.0 on the last note
    of a phrase, +0.5 breath rest between lines. Pitches are authoritative (from
    the user's notation); rhythm is engine-side (even, song stays recognizable)."""
    out = []
    for ln in lines:
        toks = ln.split()
        for i, tok in enumerate(toks):
            beats = 1.0 if i == len(toks) - 1 else 0.5
            if tok == "0":
                out.append((0, beats)); continue
            deg = int(tok[0]); oc = tok.count("'") - tok.count(",")
            out.append((60 + 12 * oc + SEMI[deg], beats))
        out.append((0, 0.5))  # breath between phrases
    return out

# Real public-domain melodies as notasi angka supplied by the user (Indonesian
# lagu daerah / rakyat). Verified source — edit a line here to fix a tune.
NOTANGKA = {
    "apuse": ["5, 1 3 2 3 2 1", "5, 1 3 3 2 3 4 2", "5, 1 2 4 5 4 3 2 3 2 1"],
    "ampar_pisang": ["5, 1 1 7, 1 2", "5, 5, 2 2 1 2 3", "4 2 2 3 1 1 2 2 1 7, 1",
        "4 2 2 3 1 1 2 2 1 7, 1", "5, 5, 5, 1 1 7, 1 2", "5, 2 2 1 2 3",
        "3 4 4 2 2 3 3", "1 1 2 2 1 7, 1", "3 5 5 4 4 5 2", "2 4 4 3 2 1"],
    "soleram": ["1 2 3 3 4 5 4 3 2", "3 4 5 5 6 5 4 6 5",
        "5 6 7 1 5 6 5 4 6 5 4 3 2 1", "5 5 5 6 4 2 7 1 3 2 1"],
    "gundul_pacul": ["1 3 1 3 4 5 5", "7 1' 7 1' 7 5", "1 3 1 3 4 5 5",
        "7 1' 7 1' 7 5", "1 3 5 4 4 5 4 3 1 4 3 1", "1 3 5 4 4 5 4 3 1 4 3 1"],
    "cublak_suweng": ["0 3 5 5 2 3 1 2 3 2 5 3 2", "1 2 3 2 5 3 2 1 1 5, 6, 1 2 1",
        "1 1 1 5, 6, 1 2 6, 1 5 0 5 3 2 1 2", "3 5 0 5 3 2 1 2 3"],
    "yamko": ["1 5 5 6 3 5 6", "5 5 6 2 3 1", "1 5 5 5 6 5 6 1 2 3 2 3",
        "2 3 2 3 1 2 3 2 1", "5 5 5 6 5 5 6 2", "1 1 2 3 2 2 3 1"],
    "rasa_sayange": ["1 1 3 5 5 5 5 6 5", "5 5 4 3 3 3 1 2 3", "1 1 1 4 4 4 5 4 3",
        "5 4 3 2 2 2 1 7, 1", "3 4 5 5 1' 7 6 5 5 3 4 5",
        "1' 7 6 6 5 4 3 5 1 3 2 2 1 7, 1"],
    "anak_kambing": ["1 1 1 1 1 7, 6, 1 7, 6, 5,", "5, 2 2 2 2 2 1 2 3 4 3 2 1",
        "4 4 4 4 4 6 6", "3 3 3 3 3 5 5", "2 2 2 2 2 5 4 3 3 2 2 1"],
    "bungong_jeumpa": ["6 7 6 5 6 7 6 5", "6 7 1' 7 1'", "1' 2' 1' 7 1' 2' 1' 7",
        "1' 7 6 5 6", "3' 2' 1' 7", "2' 3' 1' 7 6", "1' 1' 7 6 5 6 7", "1' 7 6 5 6"],
    "sajojo": ["1 4 4 0 0 6 1' 6", "2' 0 2' 2' 2' 0 2' 2' 2'", "2' 2' 2' 1' 1' 7",
        "6 0 5 0 5 5 5 6 0 4 4"],
}
MELODIES = {k: _na(v) for k, v in NOTANGKA.items()}

# folk songs — real public-domain Indonesian lagu daerah / lagu rakyat, arranged
# in modern grooves. Become real catalog entries (category "Lagu Daerah"/"Lagu Anak").
_LD = "Lagu Daerah"; _LA = "Lagu Anak"
FOLK = [
    {"id": "apuse",          "melody": "apuse",          "title": "Apuse",               "region": "Papua",              "category": _LD, "bpm": 104, "root": 60, "groove": "citypop", "lead": "flute", "flavor": "bell",  "lanes": 4, "diffs": ["Easy", "Normal", "Hard"]},
    {"id": "ampar_pisang",   "melody": "ampar_pisang",   "title": "Ampar-Ampar Pisang",  "region": "Kalimantan Selatan", "category": _LD, "bpm": 108, "root": 60, "groove": "koplo",   "lead": "pluck", "flavor": "bell",  "lanes": 4, "diffs": ["Easy", "Normal", "Hard"]},
    {"id": "soleram",        "melody": "soleram",        "title": "Soleram",             "region": "Riau",               "category": _LD, "bpm": 92,  "root": 60, "groove": "lofi",    "lead": "flute", "flavor": "bell",  "lanes": 4, "diffs": ["Easy", "Normal"]},
    {"id": "rasa_sayange",   "melody": "rasa_sayange",   "title": "Rasa Sayange",        "region": "Maluku",             "category": _LD, "bpm": 100, "root": 60, "groove": "citypop", "lead": "flute", "flavor": "bell",  "lanes": 4, "diffs": ["Easy", "Normal", "Hard"]},
    {"id": "yamko",          "melody": "yamko",          "title": "Yamko Rambe Yamko",   "region": "Papua",              "category": _LD, "bpm": 128, "root": 60, "groove": "edm",     "lead": "lead",  "flavor": "flute", "lanes": 4, "diffs": ["Normal", "Hard"]},
    {"id": "bungong_jeumpa", "melody": "bungong_jeumpa", "title": "Bungong Jeumpa",      "region": "Aceh",               "category": _LD, "bpm": 96,  "root": 57, "groove": "lofi",    "lead": "flute", "flavor": "bell",  "lanes": 4, "diffs": ["Easy", "Normal"]},
    {"id": "sajojo",         "melody": "sajojo",         "title": "Sajojo",              "region": "Papua",              "category": _LD, "bpm": 124, "root": 60, "groove": "koplo",   "lead": "lead",  "flavor": "flute", "lanes": 4, "diffs": ["Normal", "Hard"]},
    {"id": "cublak_suweng",  "melody": "cublak_suweng",  "title": "Cublak-Cublak Suweng","region": "Jawa Tengah",        "category": _LA, "bpm": 116, "root": 60, "groove": "edm",     "lead": "bell",  "flavor": "bell",  "lanes": 4, "diffs": ["Normal", "Hard"]},
    {"id": "gundul_pacul",   "melody": "gundul_pacul",   "title": "Gundul-Gundul Pacul", "region": "Jawa Tengah",        "category": _LA, "bpm": 120, "root": 60, "groove": "koplo",   "lead": "lead",  "flavor": "flute", "lanes": 4, "diffs": ["Normal", "Hard"]},
    {"id": "anak_kambing",   "melody": "anak_kambing",   "title": "Anak Kambing Saya",   "region": "Nusa Tenggara Timur","category": _LA, "bpm": 112, "root": 62, "groove": "pop",     "lead": "pluck", "flavor": None,    "lanes": 4, "diffs": ["Easy", "Normal"]},
]

# chords that could harmonise a melody, scored by how many melody notes they contain
_CHORD_CANDIDATES = [(0, "maj"), (5, "maj"), (7, "maj"), (9, "min"), (2, "min"), (4, "min")]

def derive_chord(key_root, melody_pcs):
    best = (0, "maj"); bestscore = -1
    for off, q in _CHORD_CANDIDATES:
        pcs = set((key_root + off + iv) % 12 for iv in CHORD_Q[q])
        score = sum(1 for pc in melody_pcs if pc in pcs)
        if score > bestscore:
            bestscore = score; best = (off, q)
    return best

def build_song_melody(spec, write=False):
    """Render a folk song whose LEAD is a real public-domain melody; chords are
    auto-derived to fit, drums/bass from the groove. Returns the audio buffer +
    (total_s, charts, counts, first_ms, preview_ms)."""
    bpm = spec["bpm"]; beat = 60.0 / bpm; step = beat / 4.0; spb = 16
    sections = section_plan(bpm)
    total_bars = sum(b for _, b in sections)
    total_s = total_bars * spb * step + 1.2
    buf = [0.0] * int(total_s * SR)
    root = spec["root"]; key_pc = root % 12
    groove = GROOVES[spec["groove"]]
    lanes = spec.get("lanes", 4)
    rng = random.Random(zlib.crc32(spec["melody"].encode()))
    transpose = root - 60
    mel = [(m + transpose if m > 0 else 0, b) for (m, b) in MELODIES[spec["melody"]]]

    # bar layout
    bars = []  # (global_bar_index, section_name, t_bar)
    gi = 0
    for sec_name, sec_bars in sections:
        for _ in range(sec_bars):
            bars.append((gi, sec_name, gi * spb * step)); gi += 1
    note_bars = [b for b in bars if b[1] in ("verse", "chorus")]

    # lay melody across note-bearing bars (looping)
    per_bar = {b[0]: [] for b in bars}
    gb = 0.0; ei = 0; guard = 0
    while int(gb // 4) < len(note_bars) and guard < 100000:
        midi, beats = mel[ei % len(mel)]
        bar_i = int(gb // 4); offset = gb - bar_i * 4
        per_bar[note_bars[bar_i][0]].append((offset, midi, beats))
        gb += beats; ei += 1; guard += 1

    # derive a chord per note-bearing bar
    chord_of = {}
    for (gbar, sec, t_bar) in note_bars:
        pcs = [n[1] % 12 for n in per_bar[gbar] if n[1] > 0]
        chord_of[gbar] = derive_chord(key_pc, pcs)

    diffs = spec.get("diffs", ["Easy", "Normal", "Hard"])
    notes_by_diff = {d: [] for d in diffs}
    prev_lane = 0; first_ms = None

    for (gbar, sec, t_bar) in bars:
        full = sec == "chorus"; light = sec in ("intro", "bridge")
        # drums
        if sec != "outro":
            for st in range(spb):
                t = t_bar + st * step
                if st in groove.get("kick", []): mix(buf, render_drum("kick"), t, 0.78)
                if st in groove.get("snare", []) and not light: mix(buf, render_drum("snare"), t, 0.6)
                if st in groove.get("clap", []) and full: mix(buf, render_drum("clap"), t, 0.5)
                if st in groove.get("rim", []) and not light: mix(buf, render_drum("rim"), t, 0.34)
                if st in groove.get("hatC", []) and (full or light or st % 4 == 0):
                    mix(buf, render_drum("hatC"), t, 0.30 if not light else 0.20)
                if st in groove.get("hatO", []) and full: mix(buf, render_drum("hatO"), t, 0.34)
        # chord + bass (only where we have a chord = note-bearing bars)
        ch = chord_of.get(gbar)
        if ch and sec != "outro":
            croot = root + ch[0]; ints = CHORD_Q[ch[1]]
            for k in (0, 4, 8, 12):
                t = t_bar + k * step
                mix(buf, render_voice("bass", midi_to_hz(croot - 24), beat * 0.5), t, 0.5)
            stab_steps = [0, 4, 8, 12] if full else [0, 8]
            for st in stab_steps:
                t = t_bar + st * step
                for iv in ints:
                    if full:
                        mix(buf, render_voice("stab", midi_to_hz(croot + iv), beat * 0.9), t, 0.18)
                    else:
                        mix(buf, render_voice("pad", midi_to_hz(croot + iv), beat * 2.0), t, 0.14)
        # lead melody (the real tune) + chart
        if sec in ("verse", "chorus"):
            for (offset, midi, beats) in per_bar[gbar]:
                if midi <= 0:
                    continue
                t = t_bar + offset * beat
                pitch = midi + (12 if full else 0)
                dur = beat * beats * 0.95
                mix(buf, render_voice(spec["lead"], midi_to_hz(pitch), dur), t, 0.6 if full else 0.42)
                if spec.get("flavor") and full and beats >= 1.0:
                    mix(buf, render_voice(spec["flavor"], midi_to_hz(pitch + 12), beat * beats * 0.8), t, 0.13)
                # chart note
                start_ms = int(t * 1000)
                if first_ms is None: first_ms = start_ms
                lane = (prev_lane + 1 + (int(offset * 2) % max(1, lanes - 1))) % lanes
                prev_lane = lane
                ntype = "hold" if beats >= 1.5 else ("golden" if (offset == 0 and gbar % 4 == 0 and full) else "tap")
                for d in diffs:
                    dens = DIFF_DENSITY[d] * (1.0 if full else 0.85)
                    # Easy keeps only the strong (on-beat) notes
                    if d == "Easy" and (offset % 1.0) > 0.01:
                        continue
                    if rng.random() > dens:
                        continue
                    note = {"type": ntype, "lane": lane, "startTimeMs": start_ms}
                    if ntype == "hold":
                        note["endTimeMs"] = start_ms + int(beats * beat * 1000)
                    notes_by_diff[d].append(note)

    charts = {}
    if write:
        sid = spec["id"]
        write_wav(os.path.join(ROOT, "assets/audio/songs", sid + ".wav"), buf)
        for d in diffs:
            ns = sorted(notes_by_diff[d], key=lambda n: (n["startTimeMs"], n["lane"]))
            chart = {"songId": sid, "difficulty": d, "bpm": bpm, "offsetMs": 0, "notes": ns}
            fn = "%s__%s.json" % (sid, d.lower())
            with open(os.path.join(ROOT, "assets/charts", fn), "w") as f:
                json.dump(chart, f, indent=1)
            charts[d] = "assets/charts/" + fn

    intro_verse_bars = sections[0][1] + sections[1][1]
    preview_ms = int(intro_verse_bars * spb * step * 1000)
    counts = {d: len(notes_by_diff[d]) for d in diffs}
    return buf, total_s, charts, counts, (first_ms or 0), preview_ms

# ============================================================================
# Song builder
# ============================================================================

def scale_pitch_ladder(root, scale, lo_oct, hi_oct):
    out = []
    for o in range(lo_oct, hi_oct + 1):
        for s in scale:
            out.append(root + 12 * o + s)
    return sorted(set(out))

def nearest_chord_tone(pitch, chord_pcs):
    """Snap a midi pitch to the nearest pitch whose pitch-class is in the chord."""
    best = pitch; bestd = 99
    for dp in range(-4, 5):
        if (pitch + dp) % 12 in chord_pcs:
            if abs(dp) < bestd:
                bestd = abs(dp); best = pitch + dp
    return best

def build_song(spec):
    bpm = spec["bpm"]
    beat = 60.0 / bpm
    step = beat / 4.0                 # sixteenth-note grid
    spb = 16                          # steps per bar
    sections = section_plan(bpm)
    total_bars = sum(b for _, b in sections)
    total_steps = total_bars * spb
    total_s = total_steps * step + 1.2
    buf = [0.0] * int(total_s * SR)

    scale = SCALES[spec["scale"]]
    root = spec["root"]
    lanes = spec["lanes"]
    prog = PROGRESSIONS[spec["prog"]]
    groove = GROOVES[spec["groove"]]
    energy = spec["energy"]
    rng = random.Random(zlib.crc32(spec["id"].encode()))
    hook = HOOKS[zlib.crc32(spec["id"].encode()) % len(HOOKS)]
    ladder = scale_pitch_ladder(root, scale, 1, 3)   # melody range
    base_idx = len(ladder) // 2

    notes_by_diff = {d: [] for d in spec["diffs"]}
    prev_lane = 0
    first_note_step = None

    bar_cursor = 0
    for sec_name, sec_bars in sections:
        for b in range(sec_bars):
            bar = bar_cursor + b
            chord_root_off, qual = prog[bar % len(prog)]
            chord_root = root + chord_root_off
            chord_ints = CHORD_Q[qual]
            chord_pcs = set((chord_root + iv) % 12 for iv in chord_ints)
            t_bar = bar * spb * step

            # ---------- drums (verse lighter than chorus for contrast) ----------
            play_drums = sec_name not in ("outro",)
            light = sec_name in ("intro", "bridge")
            full = sec_name == "chorus"
            for st in range(spb):
                t = t_bar + st * step
                if not play_drums:
                    continue
                if st in groove.get("kick", []):
                    mix(buf, render_drum("kick"), t, 0.78)
                if st in groove.get("snare", []) and not light:
                    mix(buf, render_drum("snare"), t, 0.6)
                if st in groove.get("clap", []) and full:
                    mix(buf, render_drum("clap"), t, 0.5)
                if st in groove.get("rim", []) and not light:
                    mix(buf, render_drum("rim"), t, 0.34)
                if st in groove.get("hatC", []):
                    # verses use only the on-beat hats → less busy than chorus
                    if full or light or st % 4 == 0:
                        mix(buf, render_drum("hatC"), t, 0.30 if not light else 0.20)
                if st in groove.get("hatO", []) and full:
                    mix(buf, render_drum("hatO"), t, 0.34)
            # one-bar fill/riser into every chorus (snare roll) for a "drop" feel
            if sec_name == "chorus" and b == 0:
                for j in range(8):
                    tt = t_bar - (8 - j) * (step * 0.5)
                    mix(buf, render_drum("snare"), tt, 0.18 + 0.05 * j)

            # ---------- bass ----------
            bass_oct = -2
            if sec_name != "outro":
                if spec["groove"] in ("koplo", "dangdut"):
                    # walking dangdut bass: root–fifth–octave–seventh on 8ths
                    walk = [0, 7, 12, 10, 0, 7, 5, 7]
                    for k in range(8):
                        t = t_bar + k * (step * 2)
                        bf = midi_to_hz(chord_root + 12 * bass_oct + walk[k % len(walk)])
                        mix(buf, render_voice("bass", bf, beat * 0.5), t, 0.5)
                elif spec["groove"] in ("edm", "phonk"):
                    for st in groove.get("kick", []):
                        t = t_bar + st * step
                        bf = midi_to_hz(chord_root + 12 * bass_oct)
                        dur = beat * (1.6 if spec["groove"] == "phonk" else 0.45)
                        mix(buf, render_voice("sub", bf, dur), t, 0.6)
                else:
                    for k in (0, 4, 8, 12, 14):
                        t = t_bar + k * step
                        bf = midi_to_hz(chord_root + 12 * bass_oct)
                        mix(buf, render_voice("bass", bf, beat * 0.5), t, 0.5)

            # ---------- chords (stabs in chorus, pads elsewhere) ----------
            if sec_name in ("verse", "chorus", "bridge"):
                use_pad = sec_name != "chorus"
                stab_steps = [0, 4, 8, 12] if sec_name == "chorus" else [0, 8]
                for st in stab_steps:
                    t = t_bar + st * step
                    for iv in chord_ints:
                        cf = midi_to_hz(chord_root + iv)
                        if use_pad:
                            mix(buf, render_voice("pad", cf, beat * 2.0), t, 0.16)
                        else:
                            mix(buf, render_voice("stab", cf, beat * 0.9), t, 0.2)

            # ---------- lead hook + CHART (verse/chorus only) ----------
            if sec_name in ("verse", "chorus"):
                is_chorus = sec_name == "chorus"
                phrase_pos = (bar % 2) * spb     # 2-bar hook phrase
                for k, rstep in enumerate(hook["rhythm"]):
                    if rstep < phrase_pos or rstep >= phrase_pos + spb:
                        continue
                    st = rstep - phrase_pos
                    # verses thin the hook out for contrast
                    if not is_chorus and (k % 2 == 1):
                        continue
                    t = t_bar + st * step
                    strong = st % 4 == 0
                    idx = base_idx + hook["contour"][k % len(hook["contour"])]
                    idx = max(0, min(len(ladder) - 1, idx))
                    pitch = ladder[idx] + (12 if is_chorus else 0)
                    if strong:
                        pitch = nearest_chord_tone(pitch, chord_pcs)
                    pitch = min(pitch, root + 26)   # ceiling: keep lead from getting shrill
                    lf = midi_to_hz(pitch)
                    lead_inst = spec["lead"]
                    note_dur = step * (3.0 if (strong and is_chorus) else 1.7)
                    mix(buf, render_voice(lead_inst, lf, note_dur),
                        t, 0.62 if is_chorus else 0.42)
                    # optional regional flavor doubling (gamelan bell / suling)
                    if spec["flavor"] and is_chorus and strong:
                        mix(buf, render_voice(spec["flavor"], midi_to_hz(pitch + 12), step * 2),
                            t, 0.14)

                    # ----- chart note (drives gameplay = play the melody) -----
                    global_step = bar * spb + st
                    if first_note_step is None:
                        first_note_step = global_step
                    lane = (prev_lane + 1 + (k % (lanes - 1))) % lanes
                    prev_lane = lane
                    start_ms = int(t * 1000)
                    ntype, hold_s = _chart_type(bar, st, is_chorus, lanes, beat, k)
                    for d in spec["diffs"]:
                        dens = DIFF_DENSITY[d]
                        if not is_chorus:
                            dens *= 0.82
                        if rng.random() > dens:
                            continue
                        note = {"type": ntype, "lane": lane, "startTimeMs": start_ms}
                        if ntype in ("hold", "slide"):
                            note["endTimeMs"] = start_ms + int(hold_s * 1000)
                        if ntype == "flick":
                            note["direction"] = DIRS[k % len(DIRS)]
                        notes_by_diff[d].append(note)
                        if ntype == "double" and d in ("Hard", "Expert"):
                            notes_by_diff[d].append({"type": "tap",
                                "lane": (lane + 2) % lanes, "startTimeMs": start_ms})
        bar_cursor += sec_bars

    write_wav(os.path.join(ROOT, "assets/audio/songs", spec["id"] + ".wav"), buf)

    charts = {}
    for d in spec["diffs"]:
        ns = sorted(notes_by_diff[d], key=lambda n: (n["startTimeMs"], n["lane"]))
        chart = {"songId": spec["id"], "difficulty": d, "bpm": bpm, "offsetMs": 0, "notes": ns}
        fn = "%s__%s.json" % (spec["id"], d.lower())
        with open(os.path.join(ROOT, "assets/charts", fn), "w") as f:
            json.dump(chart, f, indent=1)
        charts[d] = "assets/charts/" + fn

    first_ms = int((first_note_step or 0) * step * 1000)
    # chorus #1 start ms for song-preview
    intro_verse_bars = 2 + 8
    preview_ms = int(intro_verse_bars * spb * step * 1000)
    return total_s, charts, {d: len(notes_by_diff[d]) for d in spec["diffs"]}, first_ms, preview_ms

def _chart_type(bar, st, is_chorus, lanes, beat, k):
    if st == 0 and bar % 8 == 0:
        return "fever", 0
    if is_chorus and st == 0 and bar % 4 == 2:
        return "golden", 0
    if st == 8 and is_chorus:
        return "hold", beat * 1.0
    if st == 12 and k % 3 == 0:
        return "flick", 0
    if is_chorus and lanes >= 5 and st in (4,) and bar % 2 == 1:
        return "double", 0
    return "tap", 0

# ============================================================================
# SFX + menu (kept compact; gamelan-flavoured feedback)
# ============================================================================

def _bell_sfx(buf, t0, freq, vol, decay):
    n = len(buf)
    for i in range(int(t0 * SR), min(n, int(t0 * SR) + int(0.6 * SR))):
        t = (i - t0 * SR) / SR
        env = math.exp(-t * decay)
        s = 0.0
        for r in (1, 2.76, 5.40, 8.9):
            s += math.sin(2 * math.pi * freq * r * t)
        buf[i] += vol * env * s / 4

def build_sfx():
    def tone(buf, t0, dur, f, vol, kind):
        v = render_voice({"tri": "pluck", "sine": "sub"}.get(kind, "pluck"), f, dur)
        mix(buf, v, t0, vol)

    hit = [0.0] * int(0.12 * SR); _bell_sfx(hit, 0, 880, 0.4, 24)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/hit.wav"), hit)

    perfect = [0.0] * int(0.22 * SR)
    _bell_sfx(perfect, 0.0, 1175, 0.4, 18); _bell_sfx(perfect, 0.05, 1568, 0.4, 18)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/perfect.wav"), perfect)

    miss = [0.0] * int(0.16 * SR)
    mix(miss, render_voice("bass", 150, 0.14), 0, 0.6)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/miss.wav"), miss)

    combo = [0.0] * int(0.5 * SR); _bell_sfx(combo, 0, 740, 0.5, 11)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/combo.wav"), combo)

    fever = [0.0] * int(1.7 * SR); _bell_sfx(fever, 0, 196, 0.5, 3.0); _bell_sfx(fever, 0.02, 392, 0.3, 5)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/fever.wav"), fever)

    unlock = [0.0] * int(0.75 * SR)
    for t0, f in [(0.0, 587), (0.09, 740), (0.19, 988)]:
        _bell_sfx(unlock, t0, f, 0.4, 11)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/unlock.wav"), unlock)

    win = [0.0] * int(2.0 * SR); _bell_sfx(win, 0, 220, 0.45, 2.2)
    for t0, f in [(0.0, 494), (0.12, 659), (0.24, 784), (0.36, 988), (0.5, 1175)]:
        _bell_sfx(win, t0, f, 0.3, 8)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/win.wav"), win)

    lose = [0.0] * int(1.5 * SR); _bell_sfx(lose, 0, 174, 0.4, 2.6)
    for t0, f in [(0.0, 494), (0.17, 415), (0.34, 349)]:
        _bell_sfx(lose, t0, f, 0.26, 9)
    write_wav(os.path.join(ROOT, "assets/audio/sfx/lose.wav"), lose)
    print("✔ sfx (8)")

def build_menu():
    dur = 32.0
    buf = [0.0] * int(dur * SR)
    rng = random.Random(777)
    root = 57; scale = SCALES["minor_pent"]
    prog = [(0, "min"), (8, "maj"), (5, "min"), (7, "maj")]
    beat = 60.0 / 76
    for bar in range(int(dur / 4)):
        t0 = bar * 4.0
        croot_off, q = prog[bar % len(prog)]
        for iv in CHORD_Q[q]:
            f = midi_to_hz(root + croot_off + iv)
            mix(buf, render_voice("pad", f, 4.2), t0, 0.22)
    steps = int(dur / 2.0)
    for i in range(steps):
        if rng.random() < 0.5:
            t0 = i * 2.0 + rng.uniform(0.0, 0.25)
            deg = rng.randrange(len(scale))
            _bell_sfx(buf, t0, midi_to_hz(root + 12 + scale[deg]), 0.10, 4)
    write_wav(os.path.join(ROOT, "assets/audio/bgm/menu_loop.wav"), buf)
    print("✔ menu_loop 32s")

# ============================================================================

def build_folk_sampler():
    """Render the FOLK songs and stitch a ~clear chorus sampler to docs/ for the
    user to verify melody recognition. Does NOT touch assets/ or the manifest."""
    import struct as _st
    SRr = SR; out = []; gap = [0] * int(0.4 * SRr)
    order = []
    for spec in FOLK:
        _VOICE_CACHE.clear()
        spec = dict(spec); spec["id"] = spec["melody"]; spec["lanes"] = 4
        buf, total_s, _c, _n, first_ms, preview_ms = build_song_melody(spec, write=False)
        start = int(preview_ms / 1000 * SRr)
        seg = [int(max(-32767, min(32767, v * 30000))) for v in buf[start:start + int(13 * SRr)]]
        f = int(0.05 * SRr)
        for i in range(min(f, len(seg))): seg[i] = int(seg[i] * i / f)
        for i in range(min(f, len(seg))): seg[-1 - i] = int(seg[-1 - i] * i / f)
        out += seg + gap
        order.append(spec["title"])
        print("✔ %-22s %s (%dbpm)" % (spec["title"], spec["region"], spec["bpm"]))
    path = os.path.join(ROOT, "docs", "Beat-Nusantara-FOLK-SAMPLER.wav")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SRr)
        w.writeframes(_st.pack("<%dh" % len(out), *out))
    print("\nFOLK sampler %.1fs -> docs/Beat-Nusantara-FOLK-SAMPLER.wav\norder: %s" % (
        len(out) / SRr, " / ".join(order)))

def main():
    args = sys.argv[1:]
    if "--folk" in args:
        build_folk_sampler(); return
    songs_only = "--songs-only" in args
    ids = [a for a in args if not a.startswith("--")]
    todo = [s for s in SONGS if not ids or s["id"] in ids]

    if not songs_only and not ids:
        build_sfx(); build_menu()

    frag = []
    for spec in todo:
        _VOICE_CACHE.clear()  # per-song cache (pitches differ) to bound memory
        dur_s, charts, counts, first_ms, preview_ms = build_song(spec)
        frag.append({"id": spec["id"], "durationMs": int(dur_s * 1000),
                     "charts": charts, "noteCounts": counts,
                     "firstNoteMs": first_ms, "previewStartTimeMs": preview_ms})
        print("✔ %-16s %4dbpm %5.1fs first=%4dms notes=%s" % (
            spec["id"], spec["bpm"], dur_s, first_ms, counts))

    # folk lagu-daerah songs (real public-domain melodies) — full catalog entries
    if not ids:
        for spec in FOLK:
            _VOICE_CACHE.clear()
            buf, dur_s, charts, counts, first_ms, preview_ms = build_song_melody(spec, write=True)
            frag.append({"id": spec["id"], "durationMs": int(dur_s * 1000), "charts": charts,
                         "noteCounts": counts, "firstNoteMs": first_ms, "previewStartTimeMs": preview_ms,
                         "folk": True, "title": spec["title"], "region": spec["region"],
                         "category": spec["category"], "bpm": spec["bpm"], "diffs": spec["diffs"]})
            print("✔ %-16s %4dbpm %5.1fs FOLK[%s] notes=%s" % (
                spec["id"], spec["bpm"], dur_s, spec["title"], counts))

    if not ids:
        with open(os.path.join(ROOT, "tool", "_generated_manifest.json"), "w") as f:
            json.dump(frag, f, indent=2)
        print("\nWrote manifest fragment -> tool/_generated_manifest.json")

if __name__ == "__main__":
    main()
