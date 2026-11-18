# Sonus app (Flutter)

Mobile app for **Sonus**: AI-assisted Sinhala phoneme substitution analysis for adult speakers and
speech therapists. Final-year ICBT project, six-week build. The user is a native Sinhala speaker and
the project author; they make the phonetic and design decisions.

The ML side lives in the sibling repo **`../sonus`** (Python), which you can read:
- `../sonus/PROJECT_GUIDE.md`: full project plan. Read it before big decisions.
- `../sonus/docs/`: phoneme inventory, G2P rules, data, training results.
- `../sonus/train/predict.py` and `../sonus/train/align.py`: the recogniser and the expected-vs-predicted
  alignment that the analysis service wraps.

## Non-negotiable rules

1. **Suggestions, not diagnoses.** Never write "diagnosis", "disorder", "correct/incorrect speech"
   or "accuracy of your speech" in the UI. Use wording such as "possible substitution", "match with the
   expected sounds", "for your therapist to review". The match % measures phoneme-sequence agreement,
   not speech health or therapy progress. Show this note on every result screen.
2. **The automated result is never changed.** A therapist's review or override is stored as a
   separate record next to the original. Firestore rules must make the automated result write-once.
3. **Privacy.**
   - Recordings are personal data.
   - A user sees only their own data.
   - A therapist sees only users assigned to them.
   - No analytics or crash SDKs that upload audio or text.
4. Do not commit Firebase config secrets (`google-services.json`, `GoogleService-Info.plist`).
   `lib/firebase_options.dart` may be committed (it holds no secrets).

## Roles and screens

| Role | Screens |
|---|---|
| Both | Sign up / log in (email + password), role chosen at sign-up. Therapist linking by invite code |
| Adult user | My exercises (assigned) → exercise detail (Sinhala text, play hint) → record → result → history |
| Therapist | My users → user detail + history → exercise library (create word/phrase) → assign exercises → review an attempt (replay audio, see automated result, add override + note) |

## Analysis flow (one attempt)

1. The therapist creates an exercise: Sinhala word or short phrase (e.g. මල).
2. The service converts the text to **expected phonemes** with G2P.
3. The user records audio. A **quality check** runs on the device first: reject empty, < 0.3 s, > 15 s
   or near-silent recordings, with a friendly "please record again".
4. The audio is uploaded to Firebase Storage. The app then calls the analysis service with the audio
   and the exercise text.
5. The service returns the predicted phonemes, the alignment, candidate substitutions and the match %.
6. The result is stored on the attempt (write-once). The therapist can replay it and add an override.

Record **16 kHz, mono, WAV (PCM 16-bit)** if the recorder plugin allows it, since that is what the
model uses. The service also converts other formats, but uploads are smaller and checks simpler with
16 kHz mono.

## Analysis service API (draft, Python FastAPI in `../sonus/service/`, not built yet)

Until it exists, use a **mock service** in the app (same JSON) behind an interface, so the switch
later is one line.

`POST /analyze` (multipart): `audio` (file), `text` (Sinhala, UTF-8)

```json
{
  "quality": {"ok": true, "reason": null, "duration_s": 0.84},
  "expected": ["m", "a", "l", "ə"],
  "predicted": ["m", "a", "r", "ə"],
  "ops": [
    {"op": "match", "expected": "m", "predicted": "m", "position": 0},
    {"op": "match", "expected": "a", "predicted": "a", "position": 1},
    {"op": "sub",   "expected": "l", "predicted": "r", "position": 2},
    {"op": "match", "expected": "ə", "predicted": "ə", "position": 3}
  ],
  "match_percent": 75.0,
  "model_version": "mms300m-L12-bilstm-ctc",
  "g2p_version": "inv-v1.1+cff96fb2"
}
```

- `op` is one of `match`, `sub`, `del` or `ins`.
- When `quality.ok` is false, the phoneme fields are empty and `reason` says why.

`GET /g2p?text=මල` returns `{"phonemes": ["m","a","l","ə"], "ascii": "m a l ax"}`. It is used for the
exercise preview when a therapist creates an exercise.

## Phonemes (inventory v1.1, 39 symbols)

- Symbols can be several Unicode code points (`t̪`, `ⁿd̪`), so **always split phoneme strings on
  spaces**, never per character.
- Show IPA, with the ASCII name as a fallback or tooltip.

| Class | IPA (ASCII) |
|---|---|
| Vowels | a (a), aː (aa), æ (ae), æː (aae), i (i), iː (ii), u (u), uː (uu), e (e), eː (ee), o (o), oː (oo), ə (ax) |
| Stops | p, b, t̪ (t), d̪ (d), ʈ (T), ɖ (D), k, ɡ (g) |
| Affricates | tʃ (ch), dʒ (j) |
| Prenasalized | ᵐb (mb), ⁿd̪ (nd), ⁿɖ (nD), ᵑɡ (ngg) |
| Nasals | m, n, ɲ (ny), ŋ (ng) |
| Fricatives | s, ʃ (sh), h, f |
| Liquids / glides | r, l, j (y), ʋ (w) |

Result screen idea: show the expected sequence as chips. Substituted chips are highlighted with the
predicted sound under them ("l → r"), and deleted chips are struck through. Use colour **and** an icon
or label, never colour alone.

## Suggested stack (confirm with the user before adding big dependencies)

- Flutter stable, Dart 3, Material 3, Android first (iOS optional).
- Firebase: Auth (email/password), Cloud Firestore, Storage. Use FlutterFire CLI for config.
- State: Riverpod. Routing: go_router. Recording: `record`. Playback: `just_audio`. HTTP: `http` or `dio`.
- Sinhala text: use a font with full Sinhala support (e.g. Noto Sans Sinhala) and test conjuncts
  (ක්‍ෂ, ශ්‍රී) and vowel signs render correctly.

## Firestore model (draft)

```
users/{uid}                 role: "user"|"therapist", name, email, therapistId?, inviteCode? (therapist)
exercises/{id}              therapistId, text (Sinhala, NFC), expectedPhonemes[], g2pVersion, createdAt
assignments/{id}            therapistId, userId, exerciseId, dueAt?, createdAt
attempts/{id}               userId, therapistId, exerciseId, audioPath, createdAt,
                            result{...API response...}   <- write-once
attempts/{id}/reviews/{id}  therapistId, overridePhonemes[]?, overrideMatch?, note, createdAt
```

Security rules (write tests for them in week 6, with the Firebase emulator):
- A user reads and writes only their own attempts.
- A therapist reads only the attempts of users whose `therapistId` is theirs.
- `result` cannot be changed after the attempt is created.
- Only therapists can create exercises and assignments.

## Plan (app part of the six-week plan)

- [ ] Flutter project, Firebase project, FlutterFire config
- [ ] Login and sign-up with two roles; role-based home screen
- [ ] Therapist: exercise library + G2P preview (mock), assignment to a user
- [ ] User: exercise list → record (quality check) → upload → result (mock service) → history
- [ ] Therapist review: replay, automated result, override + note (separate record)
- [ ] Switch the mock to the real FastAPI service
- [ ] Security-rule tests, permission tests, demo build (APK)

## Working conventions

- Windows 11, PowerShell 5.1 (no `&&`). Flutter SDK at `C:\Users\8supu\flutter`, Android SDK at
  `%LOCALAPPDATA%\Android\Sdk`, emulator AVD `sonus_pixel` (keep paths free of spaces).
  Visual Studio is not installed: it is only needed for Windows desktop builds, which we don't do.
- **Git: never add a "Co-Authored-By: Claude" line or any Claude attribution to commits or PRs.**
  Commit only when the user asks.
- Keep code simple and readable. This is a student project that will be explained in a viva.
- Before writing a big feature, say in one or two lines what you will build and which files it touches.
