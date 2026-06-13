#!/usr/bin/env bash
# aax-to-chapters.sh — Split an Audible AAX file into per-chapter M4A or MP3 files.
#
# Usage:
#   audible/aax-to-chapters.sh [options] <file.aax>
#
# Options:
#   -a, --activation-bytes BYTES   8-hex-char Audible activation key
#                                  (also read from $AUDIBLE_ACTIVATION_BYTES or
#                                   ~/.audible/activation_bytes)
#   -f, --format m4a|mp3           Output format (default: m4a — lossless stream copy)
#   -o, --output DIR               Output directory (default: book title next to source)
#   -q, --quality NUM              MP3 VBR quality 0–9, lower = better (default: 2)
#       --no-cover                 Skip embedding cover art
#   -v, --verbose                  Show ffmpeg output
#   -h, --help                     Show this help
#
# Requirements: ffmpeg ≥ 4.0, ffprobe, yq
# Install:  brew install ffmpeg yq
#
# Getting activation bytes (one-time setup):
#   uv run python audible/get_activation_bytes.py

set -euo pipefail

# ── colours ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; CYAN=''; BOLD=''; RESET=''
fi

info()    { echo -e "${CYAN}▶${RESET} $*"; }
success() { echo -e "${GREEN}✔${RESET} $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $*" >&2; }
die()     { echo -e "${RED}✖${RESET}  $*" >&2; exit 1; }
step()    { echo -e "${BOLD}[$1/$2]${RESET} $3"; }

# ── defaults ─────────────────────────────────────────────────────────────────
FORMAT="m4a"
OUTPUT_DIR=""
ACTIVATION_BYTES="${AUDIBLE_ACTIVATION_BYTES:-}"
MP3_QUALITY=2
EMBED_COVER=true
VERBOSE=false
INPUT_FILE=""

# ── argument parsing ──────────────────────────────────────────────────────────
usage() {
  sed -n '2,/^$/{s/^# \{0,1\}//; p;}' "$0"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--activation-bytes) ACTIVATION_BYTES="$2"; shift 2 ;;
    -f|--format)           FORMAT="$(echo "$2" | tr '[:upper:]' '[:lower:]')"; shift 2 ;;
    -o|--output)           OUTPUT_DIR="$2";         shift 2 ;;
    -q|--quality)          MP3_QUALITY="$2";        shift 2 ;;
    --no-cover)            EMBED_COVER=false;        shift   ;;
    -v|--verbose)          VERBOSE=true;             shift   ;;
    -h|--help)             usage ;;
    -*)                    die "Unknown option: $1" ;;
    *)                     INPUT_FILE="$1";          shift   ;;
  esac
done

# ── validate input ────────────────────────────────────────────────────────────
[[ -z "$INPUT_FILE" ]] && { usage; exit 1; }
[[ -f "$INPUT_FILE" ]] || die "File not found: $INPUT_FILE"

INPUT_EXT="${INPUT_FILE##*.}"
INPUT_EXT_LOWER="$(echo "$INPUT_EXT" | tr '[:upper:]' '[:lower:]')"
[[ "$INPUT_EXT_LOWER" == "aax" || "$INPUT_EXT_LOWER" == "aaxc" ]] \
  || warn "File extension is .$INPUT_EXT, not .aax — continuing anyway."

[[ "$FORMAT" == "m4a" || "$FORMAT" == "mp3" ]] \
  || die "Unsupported format '$FORMAT'. Choose m4a or mp3."

# ── check dependencies ────────────────────────────────────────────────────────
for cmd in ffmpeg ffprobe yq; do
  command -v "$cmd" &>/dev/null || die \
    "$cmd is required but not installed.\n  → brew install ffmpeg yq"
done

# ── resolve activation bytes ──────────────────────────────────────────────────
if [[ -z "$ACTIVATION_BYTES" ]]; then
  BYTES_FILE="$HOME/.audible/activation_bytes"
  if [[ -f "$BYTES_FILE" ]]; then
    ACTIVATION_BYTES="$(tr -d '[:space:]' < "$BYTES_FILE")"
    info "Loaded activation bytes from $BYTES_FILE"
  fi
fi

if [[ -z "$ACTIVATION_BYTES" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  UV_AUDIBLE=(uv run --project "$SCRIPT_DIR/.." audible)
  if command -v uv &>/dev/null && uv run --project "$SCRIPT_DIR/.." audible --version &>/dev/null 2>&1; then
    info "Trying audible-cli (uv) to fetch activation bytes…"
    ACTIVATION_BYTES="$("${UV_AUDIBLE[@]}" activation-bytes 2>/dev/null | grep -Eo '[0-9a-fA-F]{8}' | tail -1)" || true
    [[ -n "$ACTIVATION_BYTES" ]] && info "Got activation bytes via audible-cli."
  fi
fi

if [[ -z "$ACTIVATION_BYTES" ]]; then
  # Try without activation bytes (works for DRM-free or already-unlocked files)
  warn "No activation bytes found — attempting DRM-free decode."
  warn "If this fails, provide them with -a XXXXXXXX."
  warn "See: uv run python audible/get_activation_bytes.py"
  BYTES_ARGS=()
else
  [[ "${#ACTIVATION_BYTES}" -eq 8 ]] \
    || die "Activation bytes must be exactly 8 hex characters, got: $ACTIVATION_BYTES"
  BYTES_ARGS=(-activation_bytes "$ACTIVATION_BYTES")
fi

# ── ffmpeg verbosity ──────────────────────────────────────────────────────────
if $VERBOSE; then
  FF_QUIET=()
else
  FF_QUIET=(-loglevel error -stats)
fi

# ── probe the file ────────────────────────────────────────────────────────────
info "Probing: $(basename "$INPUT_FILE")"

PROBE_JSON=$(ffprobe "${BYTES_ARGS[@]}" \
  -i "$INPUT_FILE" \
  -print_format json \
  -show_format \
  -show_chapters \
  -loglevel error) \
  || die "ffprobe failed — are your activation bytes correct?"

# Extract book metadata
BOOK_TITLE=$(echo "$PROBE_JSON"  | yq -p json -r '.format.tags.title   // "Unknown Title"')
BOOK_ARTIST=$(echo "$PROBE_JSON" | yq -p json -r '.format.tags.artist  // .format.tags.author // "Unknown Author"')
BOOK_YEAR=$(echo "$PROBE_JSON"   | yq -p json -r '.format.tags.date    // .format.tags.year   // ""' | grep -Eo '^[0-9]{4}' || true)
BOOK_GENRE=$(echo "$PROBE_JSON"  | yq -p json -r '.format.tags.genre   // "Audiobook"')
CHAPTER_COUNT=$(echo "$PROBE_JSON" | yq -p json '.chapters | length')

echo ""
echo -e "  ${BOLD}Title :${RESET}  $BOOK_TITLE"
echo -e "  ${BOLD}Author:${RESET}  $BOOK_ARTIST"
[[ -n "$BOOK_YEAR" ]] && echo -e "  ${BOLD}Year  :${RESET}  $BOOK_YEAR"
echo -e "  ${BOLD}Format:${RESET}  $FORMAT  •  $CHAPTER_COUNT chapters"
echo ""

[[ "$CHAPTER_COUNT" -eq 0 ]] && die "No chapters found in file."

# ── sanitise a string for use as a filename ───────────────────────────────────
sanitise() {
  echo "$1" \
    | tr -d '[:cntrl:]' \
    | sed 's|[/\\:*?"<>|]|_|g' \
    | sed 's/  */ /g; s/^ //; s/ $//' \
    | cut -c1-120
}

# ── set up output directory ───────────────────────────────────────────────────
if [[ -z "$OUTPUT_DIR" ]]; then
  SAFE_TITLE=$(sanitise "$BOOK_TITLE")
  BASE_DIR="$(dirname "$(realpath "$INPUT_FILE")")"
  OUTPUT_DIR="$BASE_DIR/$SAFE_TITLE"
fi

mkdir -p "$OUTPUT_DIR"
info "Output → $OUTPUT_DIR"
echo ""

# ── extract cover art ─────────────────────────────────────────────────────────
COVER_FILE=""
if $EMBED_COVER; then
  COVER_FILE="$OUTPUT_DIR/.cover.jpg"
  ffmpeg -y "${BYTES_ARGS[@]}" -i "$INPUT_FILE" \
    -an -vcodec copy "$COVER_FILE" \
    "${FF_QUIET[@]}" 2>/dev/null \
    && success "Cover art extracted." \
    || { warn "Could not extract cover art — skipping."; COVER_FILE=""; }
fi

# ── codec / container settings ────────────────────────────────────────────────
if [[ "$FORMAT" == "m4a" ]]; then
  # Stream-copy the native AAC — no quality loss, very fast
  AUDIO_ARGS=(-vn -c:a copy)
  EXT="m4a"
else
  AUDIO_ARGS=(-vn -c:a libmp3lame -q:a "$MP3_QUALITY")
  EXT="mp3"
fi

# ── split into chapters ───────────────────────────────────────────────────────
DIGITS=${#CHAPTER_COUNT}   # zero-pad width matches total count

FAILED=0
for i in $(seq 0 $(( CHAPTER_COUNT - 1 )) ); do
  TRACK=$(( i + 1 ))
  PADDED=$(printf "%0${DIGITS}d" "$TRACK")

  START=$(echo "$PROBE_JSON" | yq -p json -r ".chapters[$i].start_time")
  END=$(echo "$PROBE_JSON"   | yq -p json -r ".chapters[$i].end_time")
  CH_TITLE=$(echo "$PROBE_JSON" | yq -p json -r ".chapters[$i].tags.title // \"Chapter $TRACK\"")

  SAFE_CH=$(sanitise "$CH_TITLE")
  OUT_FILE="$OUTPUT_DIR/${PADDED} - ${SAFE_CH}.${EXT}"

  step "$TRACK" "$CHAPTER_COUNT" "$CH_TITLE"

  # Build cover-embedding args (M4A only; MP3 uses -map / -map_metadata differently)
  COVER_ARGS=()
  if [[ -n "$COVER_FILE" && "$FORMAT" == "m4a" ]]; then
    COVER_ARGS=(-i "$COVER_FILE" -map 0:a -map 1:v -c:v copy -disposition:v:0 attached_pic)
  fi

  # Metadata tags
  META_ARGS=(
    -metadata "title=$CH_TITLE"
    -metadata "artist=$BOOK_ARTIST"
    -metadata "album=$BOOK_TITLE"
    -metadata "track=$TRACK/$CHAPTER_COUNT"
    -metadata "genre=$BOOK_GENRE"
  )
  [[ -n "$BOOK_YEAR" ]] && META_ARGS+=(-metadata "date=$BOOK_YEAR")

  if ffmpeg -y \
      "${BYTES_ARGS[@]}" \
      -ss "$START" -to "$END" \
      -i "$INPUT_FILE" \
      "${COVER_ARGS[@]}" \
      "${AUDIO_ARGS[@]}" \
      "${META_ARGS[@]}" \
      "$OUT_FILE" \
      "${FF_QUIET[@]}"; then
    success "  → $(basename "$OUT_FILE")"
  else
    warn "  Chapter $TRACK failed — skipping."
    (( FAILED++ )) || true
  fi
done

# ── clean up temp cover ───────────────────────────────────────────────────────
[[ -n "$COVER_FILE" && -f "$COVER_FILE" ]] && rm -f "$COVER_FILE"

# ── summary ───────────────────────────────────────────────────────────────────
echo ""
DONE=$(( CHAPTER_COUNT - FAILED ))
if [[ $FAILED -eq 0 ]]; then
  success "Done! $DONE/$CHAPTER_COUNT chapters saved to:"
  echo    "  $OUTPUT_DIR"
else
  warn "$FAILED chapter(s) failed. $DONE/$CHAPTER_COUNT saved to:"
  echo "  $OUTPUT_DIR"
  exit 1
fi
