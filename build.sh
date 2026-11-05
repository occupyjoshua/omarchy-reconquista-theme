#!/bin/bash
# Rebuilds backgrounds/ and unlock.png from src/ and public-domain art on Wikimedia Commons.
# Needs: curl, ImageMagick 7 (magick), rsvg-convert.
set -euo pipefail
cd "$(dirname "$0")"

CACHE=${CACHE:-.cache}
OUT=backgrounds
IRON='#121314' GOLD='#b8923a'
mkdir -p "$CACHE" "$OUT"

fetch() { # <local-name> <Commons file title>
  [[ -s $CACHE/$1 ]] && return
  curl -sfL -A "omarchy-reconquista-theme build" -o "$CACHE/$1" \
    "https://commons.wikimedia.org/wiki/Special:FilePath/${2// /_}"
  sleep 1
}

fetch montgisard.jpg "Schlacht von Montgisard 2.jpg"
fetch deesis.jpg     "Christ Pantocrator Deesis mosaic Hagia Sophia.jpg"
fetch delacroix.jpg   "Prise de Constantinople par les croisés (12 avril 1204) - Eugène Delacroix - Musée du Louvre Peintures INV 3821 ; LP 4674 - après restauration 2026.jpg"
fetch sallet.jpg     "HJRK A 60 - Sallet, 1480-85.jpg"
fetch candles.jpg    "Candles in church.jpg"
fetch window.jpg     "Stained glass at Sainte-Chapelle 06.jpg"
fetch chapelle.jpg   "2017-07-29 France, Paris DSC 2711 DxO 2.jpg"
fetch cefalu.jpg     "Cefalu Cathedral MosaicChristPantocrator 009 6038.jpg"

# Dark iron field with a soft centre glow; noise stops gradient banding.
field() { # <w> <h> <out>
  magick -size "$1x$2" radial-gradient:'#1e1f21-#0a0a0b' \
    -seed 7 -attenuate 0.25 +noise Gaussian "$3"
}

# Full-bleed painting: cover-crop, grade toward the palette, vignette.
bleed() { # <in> <gravity> <out> [width]
  local w=${4:-2560} h=$(( ${4:-2560} * 9 / 16 ))
  magick "$1" -shave 1.5%x1.5% -resize "${w}x${h}^" -gravity "$2" -extent "${w}x${h}" \
    -modulate 82,78 -level 3%,100%,0.92 \
    \( -size "${w}x${h}" radial-gradient:white-'#1a1a1a' -level 0%,85% \) \
    -compose multiply -composite -quality 90 "$3"
}

# Jerusalem cross in flat gold on the iron field.
cross() { # <height> <out>
  local w=3840 h=2160
  field $w $h "$CACHE/field.png"
  rsvg-convert -h "$1" src/jerusalem-cross.svg | magick - -fill "$GOLD" -colorize 100 "$CACHE/art.png"
  magick "$CACHE/field.png" "$CACHE/art.png" -gravity center -composite -quality 92 "$2"
}

bleed  "$CACHE/montgisard.jpg" center "$OUT/01-montgisard.jpg"
bleed  "$CACHE/deesis.jpg"     north  "$OUT/02-pantocrator.jpg"
bleed  "$CACHE/delacroix.jpg" center  "$OUT/03-constantinople.jpg" 3840
bleed  "$CACHE/sallet.jpg"    center  "$OUT/04-sallet.jpg" 3840
bleed  "$CACHE/candles.jpg"   center  "$OUT/05-candles.jpg" 3840
bleed  "$CACHE/window.jpg"    center  "$OUT/06-sainte-chapelle-window.jpg" 3840
bleed  "$CACHE/chapelle.jpg"  center  "$OUT/07-sainte-chapelle.jpg" 3840
bleed  "$CACHE/cefalu.jpg"    center  "$OUT/08-cefalu.jpg" 3840
cross 760                             "$OUT/09-jerusalem-cross.jpg"

# Boot / disk-unlock logo (Plymouth).
rsvg-convert -h 300 src/jerusalem-cross.svg -o unlock.png
echo "built: $(ls "$OUT" | tr '\n' ' ') unlock.png"
