#!/usr/bin/env bash
set -euo pipefail

# Shared build helper for ESP32-S3 + Wokwi projects using arduino-cli.
# Usage: ./compiler.sh ejercicio_1

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-}"
FQBN="${FQBN:-esp32:esp32:esp32s3}"

if [[ -z "$TARGET" ]]; then
  echo "Uso: $(basename "$0") <ejercicio_n>"
  exit 1
fi

PROJECT_DIR="${ROOT_DIR}/${TARGET}"
SKETCH_FILE="${PROJECT_DIR}/sketch.ino"
BUILD_DIR="${PROJECT_DIR}/build"
BUILD_CACHE_DIR="${BUILD_DIR}/arduino-cli"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Error: no existe el directorio ${PROJECT_DIR}"
  exit 1
fi

if [[ ! -f "$SKETCH_FILE" ]]; then
  echo "Error: no se encontro ${SKETCH_FILE}"
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew no esta instalado. Instala Homebrew primero: https://brew.sh"
  exit 1
fi

if ! command -v arduino-cli >/dev/null 2>&1; then
  echo "arduino-cli no encontrado. Instalando con Homebrew..."
  brew install arduino-cli
fi

mkdir -p "$BUILD_DIR"
mkdir -p "$BUILD_CACHE_DIR"

if ! arduino-cli config dump >/dev/null 2>&1; then
  echo "Inicializando configuracion de arduino-cli..."
  arduino-cli config init >/dev/null
fi

echo "Actualizando indice de placas..."
if ! arduino-cli core update-index; then
  echo "Aviso: no se pudo actualizar el indice. Se continuara con los cores ya instalados."
fi

if ! arduino-cli core list | grep -q "esp32:esp32"; then
  echo "Instalando core esp32:esp32..."
  arduino-cli core install esp32:esp32
else
  echo "Core esp32:esp32 ya instalado."
fi

echo "Compilando ${SKETCH_FILE} para ${FQBN}..."

# arduino-cli requires the main .ino filename to match its containing folder.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TMP_SKETCH_DIR="${TMP_DIR}/${PROJECT_NAME}"
mkdir -p "$TMP_SKETCH_DIR"
cp "$SKETCH_FILE" "${TMP_SKETCH_DIR}/${PROJECT_NAME}.ino"

arduino-cli compile \
  --fqbn "$FQBN" \
  --build-path "$BUILD_CACHE_DIR" \
  --output-dir "$BUILD_DIR" \
  --export-binaries \
  "$TMP_SKETCH_DIR"

# Normalize output names to match wokwi.toml defaults in this project.
if [[ -f "${BUILD_DIR}/${PROJECT_NAME}.ino.bin" ]]; then
  cp -f "${BUILD_DIR}/${PROJECT_NAME}.ino.bin" "${BUILD_DIR}/sketch.ino.bin"
fi

if [[ -f "${BUILD_DIR}/${PROJECT_NAME}.ino.elf" ]]; then
  cp -f "${BUILD_DIR}/${PROJECT_NAME}.ino.elf" "${BUILD_DIR}/sketch.ino.elf"
fi

echo ""
echo "Listo. Archivos generados en ${BUILD_DIR}:"
ls -1 "$BUILD_DIR" | sed 's/^/ - /'

echo ""
echo "Si usas Wokwi, valida que existan:"
echo " - build/sketch.ino.bin"
echo " - build/sketch.ino.elf"
