# Soundfont native synth — setup (BASAHIN ITO)

Ang app ay gagamit ng totoong **SoundFont (.sf2)** kapag kompleto ang 3 bagay na ito.
Kung kulang, awtomatikong babalik ito sa built-in na General MIDI synth (walang crash).

## 1. Kailangan ang NDK
Sa Android Studio: **Tools > SDK Manager > SDK Tools**, i-check ang:
- **NDK (Side by side)**
- **CMake**
Tapos i-apply/i-download. (Isang beses lang.)

## 2. Idagdag ang 2 header files sa folder na ito (`app/src/main/cpp/`)
Parehong public domain, single-file (walang ibang dependency):

- `tsf.h`  →  https://raw.githubusercontent.com/schellingb/TinySoundFont/master/tsf.h
- `tml.h`  →  https://raw.githubusercontent.com/schellingb/TinySoundFont/master/tml.h

I-download ang RAW na laman at i-save nang eksakto bilang `tsf.h` at `tml.h` dito.

## 3. Idagdag ang soundfont
Maglagay ng isang `.sf2` file dito:

    app/src/main/assets/soundfont.sf2

Mga libre at magagandang General MIDI soundfont (piliin ang isa, i-rename sa `soundfont.sf2`):
- **GeneralUser GS** (~30 MB, napakaganda) — https://schristiancollins.com/generaluser.php
- **FluidR3 GM** (~140 MB, studio quality)
- **TimGM6mb.sf2** (~6 MB, maliit, para sa maliit na APK)

> Mas maganda ang tunog = mas malaki ang APK. Simulan sa ~6–30 MB.

## Build
Pagkatapos ng 3 hakbang, i-build lang tulad ng dati (`assembleDebug`).
Ang CMake ay awtomatikong iko-compile ang `synth.cpp` kasama ang tsf.h/tml.h.
