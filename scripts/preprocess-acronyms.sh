#!/bin/bash
# preprocess-acronyms.sh
# Convert \ac{...} and related commands to raw latex inline syntax
# before pandoc can corrupt the \a escape sequence
#
# Usage: preprocess-acronyms.sh input.md > output.md

sed -E '
  # Convert \ac{...} to `\ac{...}`{=latex}
  s/\\ac\{([^}]+)\}/`\\ac{\1}`{=latex}/g
  s/\\Ac\{([^}]+)\}/`\\Ac{\1}`{=latex}/g
  s/\\acf\{([^}]+)\}/`\\acf{\1}`{=latex}/g
  s/\\acs\{([^}]+)\}/`\\acs{\1}`{=latex}/g
  s/\\acl\{([^}]+)\}/`\\acl{\1}`{=latex}/g
  s/\\acp\{([^}]+)\}/`\\acp{\1}`{=latex}/g
  s/\\acro\{([^}]+)\}/`\\acro{\1}`{=latex}/g
' "$1"
