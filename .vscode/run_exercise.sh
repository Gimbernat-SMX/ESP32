#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-build}"
TARGET="${2:-}"

exercise_dirs=()
for dir in "$WORKSPACE_DIR"/ejercicio_*; do
  if [[ -d "$dir" ]]; then
    exercise_dirs+=("$(basename "$dir")")
  fi
done

if [[ ${#exercise_dirs[@]} -eq 0 ]]; then
  echo "No se ha encontrado ninguna carpeta ejercicio_* en ${WORKSPACE_DIR}."
  exit 1
fi

if [[ -z "$TARGET" ]]; then
  if [[ ${#exercise_dirs[@]} -eq 1 ]]; then
    TARGET="${exercise_dirs[0]}"
  else
    echo "Selecciona el ejercicio que quieres usar:"
    select option in "${exercise_dirs[@]}"; do
      if [[ -n "${option:-}" ]]; then
        TARGET="$option"
        break
      fi

      echo "Opcion no valida. Intentalo de nuevo."
    done
  fi
fi

PROJECT_DIR="${WORKSPACE_DIR}/${TARGET}"
BUILD_SCRIPT="${PROJECT_DIR}/build_wokwi_esp32s3.sh"

if [[ ! -x "$BUILD_SCRIPT" ]]; then
  echo "No se puede ejecutar ${BUILD_SCRIPT}."
  echo "Asegurate de que existe y tiene permisos de ejecucion."
  exit 1
fi

"$BUILD_SCRIPT"

if [[ "$MODE" == "launch" ]]; then
  echo ""
  echo "Ejercicio listo: ${TARGET}"
  echo "Firmware: ${PROJECT_DIR}/build/sketch.ino.bin"
  echo "ELF: ${PROJECT_DIR}/build/sketch.ino.elf"
  echo "Puedes abrir ${PROJECT_DIR}/wokwi.toml para simularlo en Wokwi."
fi
