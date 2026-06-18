#!/usr/bin/env python3
"""
Push Beat Nusantara metadata (ID + EN) and the 5 marketing screenshots to its
App Store Connect record via the ASC API.

Apple does NOT allow creating the app record via API (apps = GET/UPDATE only), so
create it once in the UI first: App Store Connect -> Apps -> "+" -> New App,
platform iOS, bundle id `id.beatnusantara.beatnusantara` (already registered),
name "Beat Nusantara", primary language Indonesian. Then run this:

    python3 tool/asc_push_beat.py

Idempotent: re-running updates the same editable version. Requires PyJWT.
"""
import hashlib, json, sys, time, urllib.error, urllib.request
import jwt

KEY_ID = "DK5TAZT3F9"
ISSUER = "cdaa6ed4-07f4-4151-ac76-eb1e66b6effb"
KP = "/mnt/c/Users/Desktop/Downloads/AuthKey_DK5TAZT3F9.p8"
BUNDLE = "id.beatnusantara.beatnusantara"
SHOTS = "/mnt/c/beat-nusantara/marketing/appstore/screenshots"
SHOT_FILES = ["01-gameplay.png", "02-home.png", "03-result.png", "04-library.png", "05-reward.png"]
BASE = "https://api.appstoreconnect.apple.com"

META = {
    "id": {
        "subtitle": "Game ritme rasa Nusantara",
        "promotionalText": "Ketuk irama, kejar Full Combo, nyalakan FEVER! Game ritme cute-premium dengan rasa gamelan & batik. 20 lagu, gratis dimainkan, tanpa pembelian dalam aplikasi.",
        "keywords": "ritme,musik,rhythm,game,gamelan,koplo,batik,nusantara,ketuk,beat,arcade,lagu,tap,fever,indonesia",
        "whatsNew": "Halo dunia! Rilis perdana Beat Nusantara: 20 lagu, 7 jenis not, mode FEVER, tema batik premium + gunungan wayang. Selamat menari!",
        "description": (
            "Rasakan ritme Nusantara!\n\n"
            "Beat Nusantara adalah game ritme cute-premium - semudah ketuk-mengikuti-irama, tapi dengan kedalaman rhythm game modern dan rasa khas Indonesia: gamelan, koplo, dan ornamen batik.\n\n"
            "Not jatuh ke garis, kamu ketuk lajur tepat waktu. Gampang dipahami, asyik dimainkan satu tangan, dan makin seru pas combo naik & FEVER menyala.\n\n"
            "KENAPA SERU\n"
            "- 7 jenis not: tap, hold, slide, flick, double, golden, dan fever\n"
            "- Combo, akurasi, dan grade dari C sampai SSS\n"
            "- Mode FEVER dengan skor ganda + kilatan emas\n"
            "- Efek juicy: bonang gong emas, denyut gamelan, ledakan & getaran tiap ketukan\n"
            "- Hasil meriah dengan confetti pas kamu Full Combo\n\n"
            "20 LAGU LINTAS GENRE\n"
            "Lo-fi pasar malam, pop Indonesia, koplo/dangdut, gamelan electronic, EDM, J-pop, K-pop, phonk, hyperpop, sampai lagu finale. Semua orisinal.\n\n"
            "RASA NUSANTARA\n"
            "Tema Batik Premium - emas prada, senja terracotta, indigo wedelan, ijo gamelan. Motif batik beda tiap layar (kawung, parang, ceplok, mega mendung) dan gunungan wayang di layar pembuka.\n\n"
            "ADIL & RAMAH\n"
            "- Semua lagu dasar bisa dimainkan GRATIS\n"
            "- TANPA pembelian dalam aplikasi\n"
            "- Tanpa lagu yang menghilang, tanpa hitung mundur menakutkan\n"
            "- Iklan 100% opsional - kamu yang pilih, kapan pun\n\n"
            "KUMPULKAN & PAMERKAN\n"
            "Buka skin lajur, efek ketukan, dan lencana prestasi - dari bermain, bukan dari dompet.\n\n"
            "Yuk, gas satu lagu!\n\n"
            "Catatan: semua lagu, judul, dan nama artis dalam game ini fiktif/orisinal."
        ),
    },
    "en-US": {
        "subtitle": "Cute Nusantara rhythm arcade",
        "promotionalText": "Tap the beat, chase Full Combo, ignite FEVER! A cute-premium rhythm game with gamelan & batik soul. 20 songs, free to play, no in-app purchases.",
        "keywords": "rhythm,music,game,tap,beat,arcade,gamelan,koplo,batik,nusantara,indonesia,fever,combo,songs,piano",
        "whatsNew": "Hello world! Beat Nusantara's debut: 20 songs, 7 note types, FEVER mode, a premium batik theme + wayang gunungan. Happy tapping!",
        "description": (
            "Feel the rhythm of the archipelago!\n\n"
            "Beat Nusantara is a cute-premium rhythm game - as easy to grasp as tap-to-the-beat, but with modern rhythm-game depth and a distinctly Indonesian soul: gamelan, koplo, and batik ornament.\n\n"
            "Notes fall to the line; tap the lanes in time. Easy to pick up, one-handed friendly, and thrilling as your combo climbs and FEVER ignites.\n\n"
            "WHY IT'S FUN\n"
            "- 7 note types: tap, hold, slide, flick, double, golden & fever\n"
            "- Combo, accuracy, and grades from C to SSS\n"
            "- FEVER mode with double score + a golden flash\n"
            "- Juicy feedback: golden bonang gongs, a gamelan pulse, bursts & haptics on every hit\n"
            "- Celebratory results with confetti on a Full Combo\n\n"
            "20 SONGS ACROSS GENRES\n"
            "Night-market lo-fi, Indonesian pop, koplo/dangdut, gamelan electronic, EDM, J-pop, K-pop, phonk, hyperpop, and a finale track. All original.\n\n"
            "NUSANTARA FLAVOUR\n"
            "A Batik Premium theme - prada gold, dusk terracotta, wedelan indigo, gamelan jade. A different batik motif per screen (kawung, parang, ceplok, mega mendung) and a wayang gunungan on the splash.\n\n"
            "FAIR & FRIENDLY\n"
            "- The base song library is FREE to play\n"
            "- NO in-app purchases\n"
            "- No disappearing songs, no scary countdowns\n"
            "- Ads are 100% optional - your choice, any time\n\n"
            "COLLECT & SHOW OFF\n"
            "Unlock lane skins, hit effects, and achievement badges - earned by playing, not by paying.\n\n"
            "Let's play one more!\n\n"
            "Note: all songs, titles, and artist names in this game are fictional/original."
        ),
    },
}

_tok = None
def token():
    global _tok
    n = int(time.time())
    _tok = jwt.encode({"iss": ISSUER, "iat": n, "exp": n + 1100, "aud": "appstoreconnect-v1"},
                      open(KP).read(), algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"})
    return _tok

def call(method, path, body=None):
    url = path if path.startswith("http") else BASE + path
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method,
                               headers={"Authorization": "Bearer " + _tok, "Content-Type": "application/json"})
    try:
        resp = urllib.request.urlopen(r)
        return resp.status, (json.loads(resp.read().decode() or "{}"))
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or "{}")

def put_bytes(op, blob):
    hdrs = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
    chunk = blob[op["offset"]:op["offset"] + op["length"]]
    r = urllib.request.Request(op["url"], data=chunk, method=op["method"], headers=hdrs)
    urllib.request.urlopen(r).read()

def main():
    token()
    st, apps = call("GET", f"/v1/apps?filter[bundleId]={BUNDLE}&limit=1")
    if not apps.get("data"):
        print(f"!! App record for {BUNDLE} not found. Create it in App Store Connect first.")
        sys.exit(1)
    app = apps["data"][0]
    app_id = app["id"]
    print("App:", app["attributes"]["name"], "| id:", app_id)

    # ---- App Info localizations (subtitle) ----
    _, infos = call("GET", f"/v1/apps/{app_id}/appInfos?limit=5")
    info_id = infos["data"][0]["id"]
    _, locs = call("GET", f"/v1/appInfos/{info_id}/appInfoLocalizations?limit=50")
    have = {l["attributes"]["locale"]: l["id"] for l in locs.get("data", [])}
    for loc, m in META.items():
        attrs = {"subtitle": m["subtitle"]}
        if loc in have:
            call("PATCH", f"/v1/appInfoLocalizations/{have[loc]}",
                 {"data": {"type": "appInfoLocalizations", "id": have[loc], "attributes": attrs}})
        else:
            call("POST", "/v1/appInfoLocalizations", {"data": {"type": "appInfoLocalizations",
                 "attributes": {**attrs, "locale": loc, "name": "Beat Nusantara"},
                 "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info_id}}}}})
        print("  subtitle set:", loc)

    # ---- App Store Version (editable) ----
    _, vers = call("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=10")
    editable = next((v for v in vers.get("data", [])
                     if v["attributes"]["appStoreState"] in
                     ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED")), None)
    if not editable:
        _, cr = call("POST", "/v1/appStoreVersions", {"data": {"type": "appStoreVersions",
              "attributes": {"platform": "IOS", "versionString": "1.0"},
              "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})
        editable = cr["data"]
    ver_id = editable["id"]
    print("Version:", editable["attributes"]["versionString"], "| id:", ver_id)

    # ---- Version localizations (description/keywords/promo/whatsNew) ----
    _, vlocs = call("GET", f"/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations?limit=50")
    vhave = {l["attributes"]["locale"]: l["id"] for l in vlocs.get("data", [])}
    vloc_id = {}
    for loc, m in META.items():
        attrs = {"description": m["description"], "keywords": m["keywords"],
                 "promotionalText": m["promotionalText"], "whatsNew": m["whatsNew"]}
        if loc in vhave:
            call("PATCH", f"/v1/appStoreVersionLocalizations/{vhave[loc]}",
                 {"data": {"type": "appStoreVersionLocalizations", "id": vhave[loc], "attributes": attrs}})
            vloc_id[loc] = vhave[loc]
        else:
            _, cr = call("POST", "/v1/appStoreVersionLocalizations", {"data": {"type": "appStoreVersionLocalizations",
                  "attributes": {**attrs, "locale": loc},
                  "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver_id}}}}})
            vloc_id[loc] = cr["data"]["id"]
        print("  metadata set:", loc)

    # ---- Screenshots (6.7" set) on the primary locale ----
    primary = "id"
    pl = vloc_id[primary]
    _, sets = call("GET", f"/v1/appStoreVersionLocalizations/{pl}/appScreenshotSets?limit=50")
    set67 = next((s for s in sets.get("data", [])
                  if s["attributes"]["screenshotDisplayType"] == "APP_IPHONE_67"), None)
    if not set67:
        _, cr = call("POST", "/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets",
              "attributes": {"screenshotDisplayType": "APP_IPHONE_67"},
              "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": pl}}}}})
        set67 = cr["data"]
    set_id = set67["id"]

    # existing shots → skip re-upload if already 5
    _, ex = call("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=50")
    if len(ex.get("data", [])) >= len(SHOT_FILES):
        print(f"  screenshots already present ({len(ex['data'])}); skipping upload")
    else:
        for fn in SHOT_FILES:
            blob = open(f"{SHOTS}/{fn}", "rb").read()
            _, res = call("POST", "/v1/appScreenshots", {"data": {"type": "appScreenshots",
                  "attributes": {"fileName": fn, "fileSize": len(blob)},
                  "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
            sid = res["data"]["id"]
            for op in res["data"]["attributes"]["uploadOperations"]:
                put_bytes(op, blob)
            md5 = hashlib.md5(blob).hexdigest()
            call("PATCH", f"/v1/appScreenshots/{sid}",
                 {"data": {"type": "appScreenshots", "id": sid,
                           "attributes": {"uploaded": True, "sourceFileChecksum": md5}}})
            print("  uploaded:", fn)

    print("\nDONE. Remaining in App Store Connect UI: App Privacy, (optional) preview video,")
    print("pricing=Free, then attach the Codemagic build and Submit.")

if __name__ == "__main__":
    main()
