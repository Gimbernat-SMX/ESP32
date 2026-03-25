#!/usr/bin/env bash
set -euo pipefail

# Shared build helper for ESP32-S3 + Wokwi projects using arduino-cli.
# Usage: ./compiler.sh ejercicio_1 [--refresh]

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-}"
FQBN="${FQBN:-esp32:esp32:esp32s3}"
JOBS="${JOBS:-0}"
ARDUINO_PACKAGES_DIR="${HOME}/Library/Arduino15/packages"
ESP32_CORE_DIR="${ARDUINO_PACKAGES_DIR}/esp32/hardware/esp32"
REFRESH_INDEX="false"

if [[ -z "$TARGET" ]]; then
  echo "Uso: $(basename "$0") <ejercicio_n> [--refresh]"
  exit 1
fi

shift || true
for arg in "$@"; do
  case "$arg" in
    --refresh)
      REFRESH_INDEX="true"
      ;;
    *)
      echo "Argumento no reconocido: ${arg}"
      echo "Uso: $(basename "$0") <ejercicio_n> [--refresh]"
      exit 1
      ;;
  esac
done

PROJECT_DIR="${ROOT_DIR}/${TARGET}"
SKETCH_FILE="${PROJECT_DIR}/sketch.ino"
BUILD_DIR="${PROJECT_DIR}/build"
BUILD_CACHE_DIR="${BUILD_DIR}/arduino-cli"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
STAGING_DIR="${BUILD_DIR}/staging/${PROJECT_NAME}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Error: no existe el directorio ${PROJECT_DIR}"
  exit 1
fi

if [[ ! -f "$SKETCH_FILE" ]]; then
  echo "Error: no se encontro ${SKETCH_FILE}"
  exit 1
fi

if ! command -v arduino-cli >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Error: Homebrew no esta instalado. Instala Homebrew primero: https://brew.sh"
    exit 1
  fi

  echo "arduino-cli no encontrado. Instalando con Homebrew..."
  brew install arduino-cli
fi

if [[ "$REFRESH_INDEX" == "true" ]]; then
  echo "Limpiando cache de compilacion..."
  rm -rf "$BUILD_CACHE_DIR" "$STAGING_DIR"
fi

mkdir -p "$BUILD_DIR" "$BUILD_CACHE_DIR" "$STAGING_DIR"

if ! arduino-cli config dump >/dev/null 2>&1; then
  echo "Inicializando configuracion de arduino-cli..."
  arduino-cli config init >/dev/null
fi

if [[ ! -d "$ESP32_CORE_DIR" ]] || [[ -z "$(find "$ESP32_CORE_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)" ]]; then
  echo "Core esp32:esp32 no instalado. Actualizando indice de placas..."
  if ! arduino-cli core update-index; then
    echo "Aviso: no se pudo actualizar el indice."
  fi

  echo "Instalando core esp32:esp32..."
  arduino-cli core install esp32:esp32
elif [[ "$REFRESH_INDEX" == "true" ]]; then
  echo "Actualizando indice de placas..."
  if ! arduino-cli core update-index; then
    echo "Aviso: no se pudo actualizar el indice. Se continuara con los cores ya instalados."
  fi
else
  echo "Core esp32:esp32 ya instalado."
fi

echo "Compilando ${SKETCH_FILE} para ${FQBN}..."
COMPILE_START_TIME="$(date +%s)"

# arduino-cli requires the main .ino filename to match its containing folder.
STAGING_SKETCH_FILE="${STAGING_DIR}/${PROJECT_NAME}.ino"
if [[ ! -f "$STAGING_SKETCH_FILE" ]] || ! cmp -s "$SKETCH_FILE" "$STAGING_SKETCH_FILE"; then
  cp "$SKETCH_FILE" "$STAGING_SKETCH_FILE"
fi

compile_args=(
  --fqbn "$FQBN"
  --jobs "$JOBS"
  --build-path "$BUILD_CACHE_DIR"
  --export-binaries
)

arduino-cli compile \
  "${compile_args[@]}" \
  "$STAGING_DIR"
COMPILE_END_TIME="$(date +%s)"
COMPILE_DURATION="$((COMPILE_END_TIME - COMPILE_START_TIME))"

sync_artifact() {
  local source_file="$1"
  local target_file="$2"

  if [[ -f "$source_file" ]] && { [[ ! -f "$target_file" ]] || ! cmp -s "$source_file" "$target_file"; }; then
    cp -f "$source_file" "$target_file"
  fi
}

# Copy only the final artifacts we care about from the build cache.
sync_artifact "${BUILD_CACHE_DIR}/${PROJECT_NAME}.ino.bin" "${BUILD_DIR}/${PROJECT_NAME}.ino.bin"
sync_artifact "${BUILD_CACHE_DIR}/${PROJECT_NAME}.ino.bootloader.bin" "${BUILD_DIR}/${PROJECT_NAME}.ino.bootloader.bin"
sync_artifact "${BUILD_CACHE_DIR}/${PROJECT_NAME}.ino.elf" "${BUILD_DIR}/${PROJECT_NAME}.ino.elf"
sync_artifact "${BUILD_CACHE_DIR}/${PROJECT_NAME}.ino.map" "${BUILD_DIR}/${PROJECT_NAME}.ino.map"
sync_artifact "${BUILD_CACHE_DIR}/${PROJECT_NAME}.ino.merged.bin" "${BUILD_DIR}/${PROJECT_NAME}.ino.merged.bin"
sync_artifact "${BUILD_CACHE_DIR}/${PROJECT_NAME}.ino.partitions.bin" "${BUILD_DIR}/${PROJECT_NAME}.ino.partitions.bin"
sync_artifact "${BUILD_CACHE_DIR}/${PROJECT_NAME}.ino.bin" "${BUILD_DIR}/sketch.ino.bin"
sync_artifact "${BUILD_CACHE_DIR}/${PROJECT_NAME}.ino.elf" "${BUILD_DIR}/sketch.ino.elf"

echo ""
echo "Tiempo de compilacion: ${COMPILE_DURATION}s"
echo "Modo: normal"
echo ""
echo "Listo. Archivos generados en ${BUILD_DIR}:"
ls -1 "$BUILD_DIR" | sed 's/^/ - /'

echo ""
echo "Si usas Wokwi, valida que existan:"
echo " - build/sketch.ino.bin"
echo " - build/sketch.ino.elf"
