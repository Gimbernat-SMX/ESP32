#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPILER_SCRIPT="${ROOT_DIR}/compiler.sh"

if [[ ! -x "$COMPILER_SCRIPT" ]]; then
  echo "No se puede ejecutar ${COMPILER_SCRIPT}."
  echo "Asegurate de que existe y tiene permisos de ejecucion."
  exit 1
fi

exercise_dirs=()
for dir in "$ROOT_DIR"/ejercicio_*; do
  if [[ -d "$dir" ]]; then
    exercise_dirs+=("$(basename "$dir")")
  fi
done

if [[ ${#exercise_dirs[@]} -eq 0 ]]; then
  echo "No se ha encontrado ninguna carpeta ejercicio_* en ${ROOT_DIR}."
  exit 1
fi

echo "Selecciona el ejercicio que quieres compilar:"
select option in "${exercise_dirs[@]}"; do
  if [[ -n "${option:-}" ]]; then
    echo ""
    echo "Selecciona el modo de compilacion:"

    select build_mode in "Usar Cache" "Sin Cache"; do
      case "${build_mode:-}" in
        "Usar Cache")
          "$COMPILER_SCRIPT" "$option"
          break 2
          ;;
        "Sin Cache")
          "$COMPILER_SCRIPT" "$option" "--refresh"
          break 2
          ;;
        *)
          echo "Opcion no valida. Intentalo de nuevo."
          ;;
      esac
    done
  fi

  if [[ -z "${option:-}" ]]; then
    echo "Opcion no valida. Intentalo de nuevo."
  fi
done
