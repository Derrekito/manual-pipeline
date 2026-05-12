#!/bin/bash
# manual-pipeline/scripts/create_pdf.sh
# Centralized PDF generation script for manual-pipeline

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# PIPELINE_DIR can be set externally, defaults to parent of script
PIPELINE_DIR="${PIPELINE_DIR:-${SCRIPT_DIR}/..}"

# MANUAL_DIR must be set by the calling Makefile (project's manual directory)
if [ -z "${MANUAL_DIR}" ]; then
    echo "Error: MANUAL_DIR must be set to the project's manual directory"
    exit 1
fi

BUILD_DIR="${MANUAL_DIR}/build"
PROJECT_ROOT="${MANUAL_DIR}/.."

# Use pipeline assets for fonts/logos, with project assets as fallback for custom logos
export TEXINPUTS="${MANUAL_DIR}/assets/logos:${PIPELINE_DIR}/assets/logos:${PIPELINE_DIR}/assets/Fonts:"
export LUAFONTDIR="${PIPELINE_DIR}/assets/Fonts"
export MERMAID_FILTER_CONFIG="${PIPELINE_DIR}/config/mermaid-config.json"
export MERMAID_FILTER_MERMAID_CSS="${PIPELINE_DIR}/config/mermaid.css"
export MERMAID_BIN="${PIPELINE_DIR}/node_modules/.bin/mmdc"
export MERMAID_OUTPUT_DIR="${BUILD_DIR}/mermaid_images"

check_usage() {
    if [ -z "$1" ]; then
        echo "Usage: MANUAL_DIR=/path/to/manual $0 <input_file> [toc] [format]"
        echo "  format: pdf (default) or docx"
        exit 1
    fi
}

setup_paths() {
    local input_file="$1"
    IN_FILE="$input_file"
    IN_DIR="$(dirname "${IN_FILE}")"
    FILE_BASENAME="$(basename "${IN_FILE}" .md)"
    TEX_FILE="${BUILD_DIR}/${FILE_BASENAME}.tex"
    PANDOC_LOG="${BUILD_DIR}/pandoc_output.log"
    LATEXMK_LOG="${BUILD_DIR}/latexmk_full_output.log"
    LUALATEX_LOG="${BUILD_DIR}/${FILE_BASENAME}.log"
    MERMAID_SUBDIR="${MERMAID_OUTPUT_DIR}/mermaid-images"
    OUTPUT_DIR="${MANUAL_DIR}/output"
    OUTPUT_FILE="${OUTPUT_DIR}/${FILE_BASENAME}.${FORMAT}"
    mkdir -p "${OUTPUT_DIR}" || { echo "Failed to create ${OUTPUT_DIR}"; exit 1; }
    mkdir -p "${BUILD_DIR}" || { echo "Failed to create ${BUILD_DIR}"; exit 1; }
    mkdir -p "${MERMAID_SUBDIR}" || { echo "Failed to create ${MERMAID_SUBDIR}"; exit 1; }

    # Symlink pipeline assets into build directory for LaTeX to find fonts
    [ ! -L "${BUILD_DIR}/assets" ] && [ -d "${PIPELINE_DIR}/assets" ] && ln -sf "${PIPELINE_DIR}/assets" "${BUILD_DIR}/assets"
}

print_log_locations() {
    echo "Log files:"
    echo "  - Pandoc: ${PANDOC_LOG}"
    [ "$FORMAT" = "pdf" ] && echo "  - latexmk: ${LATEXMK_LOG}"
    [ "$FORMAT" = "pdf" ] && [ -f "${LUALATEX_LOG}" ] && echo "  - lualatex: ${LUALATEX_LOG}" || echo "  - lualatex: ${LUALATEX_LOG} (not yet generated)"
}

generate_tex() {
    local toc="$1"
    local template="${PIPELINE_DIR}/latex/template.latex"

    # Ensure build directory exists
    mkdir -p "${BUILD_DIR}"

    # Preprocess markdown to protect \ac{} commands from pandoc escape interpretation
    # Keep in same directory as original so relative !include paths still work
    local preprocessed="${IN_DIR}/.$(basename "${IN_FILE}" .md)_preprocessed.md"
    "${PIPELINE_DIR}/scripts/preprocess-acronyms.sh" "${IN_FILE}" > "${preprocessed}"
    trap "rm -f '${preprocessed}'" EXIT

    local pandoc_cmd="pandoc \"${preprocessed}\" --from markdown+raw_tex --template=\"${template}\" --filter=\"${PIPELINE_DIR}/scripts/inject_logos.py\" --lua-filter=\"${PIPELINE_DIR}/latex/filters/include-files.lua\" --lua-filter=\"${PIPELINE_DIR}/latex/filters/readme-only.lua\" --lua-filter=\"${PIPELINE_DIR}/latex/filters/notebook-toggle.lua\" --lua-filter=\"${PIPELINE_DIR}/latex/filters/nobreak-codeblock.lua\" --lua-filter=\"${PIPELINE_DIR}/latex/filters/md-links-to-refs.lua\" --filter=\"${PIPELINE_DIR}/latex/filters/pandoc-mermaid.py\" --filter=\"${PIPELINE_DIR}/latex/filters/pandoc-minted.py\" --highlight-style=pygments --trace --data-dir=\"${PROJECT_ROOT}\" --metadata output_dir=\"${MERMAID_OUTPUT_DIR}\" --verbose"
    [ -n "$toc" ] && [ "$toc" != "0" ] && pandoc_cmd+=" --toc"
    echo "Generating LaTeX from ${IN_FILE}..."
    if [ -f "${MERMAID_BIN}" ]; then
        if ! command -v "${MERMAID_BIN}" >/dev/null 2>&1; then
            echo "Warning: Mermaid CLI (mmdc) found but not executable. Mermaid diagrams will fail."
        fi
    fi
    eval "$pandoc_cmd -o \"${TEX_FILE}\"" > "${PANDOC_LOG}" 2>&1
    [ $? -ne 0 ] && { echo "Pandoc failed."; print_log_locations; cat "${PANDOC_LOG}" >&2; exit 1; }
    [ ! -s "${TEX_FILE}" ] && { echo "${TEX_FILE} empty or missing."; print_log_locations; exit 1; }
}

generate_pdf() {
    (
      cd "${MANUAL_DIR}" || exit 1
      latexmk -verbose -lualatex -shell-escape -output-directory="${BUILD_DIR}" "${TEX_FILE}"
    ) 2>&1 | tee "${LATEXMK_LOG}"
    [ ${PIPESTATUS[0]} -ne 0 ] && { echo "latexmk failed."; print_log_locations; exit 1; }
}

generate_docx() {
    local toc="$1"
    local pandoc_cmd="pandoc \"${IN_FILE}\" --from markdown+raw_tex --to docx --lua-filter=\"${PIPELINE_DIR}/latex/filters/include-files.lua\" --lua-filter=\"${PIPELINE_DIR}/latex/filters/notebook-toggle.lua\" --lua-filter=\"${PIPELINE_DIR}/latex/filters/md-links-to-refs.lua\" --filter=\"${PIPELINE_DIR}/latex/filters/pandoc-mermaid.py\" --filter=\"${PIPELINE_DIR}/latex/filters/pandoc-minted.py\" --highlight-style=pygments --data-dir=\"${PROJECT_ROOT}\" --metadata output_dir=\"${MERMAID_OUTPUT_DIR}\" --verbose"
    [ -n "$toc" ] && [ "$toc" != "0" ] && pandoc_cmd+=" --toc"
    echo "Generating DOCX from ${IN_FILE}..."
    if ! command -v convert >/dev/null 2>&1; then
        echo "Warning: ImageMagick (convert) not found. Some images may not convert properly."
    fi
    BUILD_DIR="${BUILD_DIR}" eval "$pandoc_cmd -o \"${OUTPUT_FILE}\"" > "${PANDOC_LOG}" 2>&1
    [ $? -ne 0 ] && { echo "Pandoc failed."; print_log_locations; cat "${PANDOC_LOG}" >&2; exit 1; }
    [ ! -s "${OUTPUT_FILE}" ] && { echo "${OUTPUT_FILE} empty or missing."; print_log_locations; exit 1; }
    echo "DOCX created: ${OUTPUT_FILE}"
}

move_pdf() {
    local pdf_file="${BUILD_DIR}/${FILE_BASENAME}.pdf"
    if [ -f "${pdf_file}" ]; then
        mv "${pdf_file}" "${OUTPUT_FILE}"
        [ $? -ne 0 ] && { echo "Error moving PDF."; print_log_locations; exit 1; } || echo "PDF created: ${OUTPUT_FILE}"
    else
        echo "No PDF at ${pdf_file}."; print_log_locations; exit 1
    fi
}

main() {
    check_usage "$1"
    FORMAT="${3:-pdf}"
    setup_paths "$1"
    echo "Starting conversion for ${IN_FILE} to ${FORMAT}..."
    if [ "$FORMAT" = "pdf" ]; then
        generate_tex "$2"
        generate_pdf
        move_pdf
    elif [ "$FORMAT" = "docx" ]; then
        generate_docx "$2"
    else
        echo "Unsupported format: ${FORMAT}. Use 'pdf' or 'docx'."
        exit 1
    fi
}

main "$1" "$2" "$3"
