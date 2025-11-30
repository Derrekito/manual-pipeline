#!/bin/bash
# manual/scripts/check_deps.sh
# Check and install dependencies for PDF manual generation

echo "Checking and installing dependencies..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANUAL_DIR="$(dirname "$SCRIPT_DIR")"
FILTER_DIR="$MANUAL_DIR/latex/filters"
FONTS_DIR="$MANUAL_DIR/assets/Fonts"

is_docker() {
  [ -f /.dockerenv ] || [ -f /run/.containerenv ]
}

check_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1
}

install_system_package() {
  local pkg="$1"
  local ubuntu_pkg="$2"
  local fedora_pkg="$3"
  local arch_pkg="$4"

  echo "Installing $pkg..."
  if [ -f /etc/debian_version ]; then
    sudo apt-get update && sudo apt-get install -y "$ubuntu_pkg" || {
      echo "Failed to install $pkg with apt-get."
      exit 1
    }
  elif [ -f /etc/fedora-release ]; then
    sudo dnf install -y "$fedora_pkg" || {
      echo "Failed to install $pkg with dnf."
      exit 1
    }
  elif [ -f /etc/arch-release ]; then
    sudo pacman -Syu --noconfirm "$arch_pkg" || {
      echo "Failed to install $pkg with pacman."
      exit 1
    }
  else
    echo "Unsupported OS. Please install $pkg manually."
    exit 1
  fi
  echo "$pkg installed successfully."
}

check_system_deps() {
  echo "Checking system dependencies..."

  local deps=(
    "make:make:make:make"
    "pandoc:pandoc:pandoc:pandoc"
    "latexmk:texlive-latexmk:texlive-latexmk:texlive-bin"
    "lualatex:texlive-luatex:texlive-luatex:texlive-core"
    "python3:python3:python3:python"
    "pip:python3-pip:python3-pip:python-pip"
    "node:nodejs:nodejs:nodejs"
    "npm:npm:npm:npm"
    "jq:jq:jq:jq"
  )

  if is_docker; then
    local missing=()
    for dep in "${deps[@]}"; do
      IFS=':' read -r cmd _ _ _ <<< "$dep"
      if ! check_command "$cmd"; then
        missing+=("$cmd")
      fi
    done
    if [ "${#missing[@]}" -gt 0 ]; then
      echo "ERROR: The following system dependencies are missing:"
      for dep in "${missing[@]}"; do
        echo "  - $dep"
      done
      exit 1
    fi
  else
    for dep in "${deps[@]}"; do
      IFS=':' read -r cmd ubuntu_pkg fedora_pkg arch_pkg <<< "$dep"
      if ! check_command "$cmd"; then
        echo "$cmd is missing."
        install_system_package "$cmd" "$ubuntu_pkg" "$fedora_pkg" "$arch_pkg"
      fi
    done
  fi
}

setup_python() {
  if ! check_command "python3"; then
    echo "ERROR: python3 is missing."
    exit 1
  fi
  if ! check_command "pip"; then
    echo "ERROR: pip is missing."
    exit 1
  fi

  cd "$MANUAL_DIR" || { echo "Failed to switch to manual directory"; exit 1; }

  local py_packages=("pandocfilters" "pygments")
  local is_arch=false
  [ -f /etc/arch-release ] && is_arch=true

  if is_docker; then
    local missing=()
    for pkg in "${py_packages[@]}"; do
      if ! python3 -c "import $pkg" >/dev/null 2>&1; then
        missing+=("$pkg")
      fi
    done
    if [ "${#missing[@]}" -gt 0 ]; then
      echo "ERROR: The following Python packages are missing:"
      for pkg in "${missing[@]}"; do
        echo "  - $pkg"
      done
      exit 1
    fi
  else
    if [ "$is_arch" = true ]; then
      echo "Detected Arch Linux. Using virtual environment."
    fi

    if [ ! -d "venv" ] || [ ! -f "venv/bin/activate" ]; then
      echo "Creating Python virtual environment..."
      python3 -m venv venv || { echo "Failed to create virtual environment."; exit 1; }
      source venv/bin/activate || { echo "Failed to activate virtual environment."; exit 1; }
    else
      if [ -z "$VIRTUAL_ENV" ]; then
        echo "Activating existing Python virtual environment..."
        source venv/bin/activate || { echo "Failed to activate virtual environment."; exit 1; }
      fi
    fi

    local need_install=false
    for pkg in "${py_packages[@]}"; do
      if ! python3 -c "import $pkg" >/dev/null 2>&1; then
        echo "Python package $pkg is missing."
        need_install=true
      fi
    done

    if [ "$need_install" = true ]; then
      echo "Installing missing Python packages..."
      for pkg in "${py_packages[@]}"; do
        if ! python3 -c "import $pkg" >/dev/null 2>&1; then
          echo "Installing $pkg..."
          pip install --quiet "$pkg" || { echo "Failed to install $pkg."; exit 1; }
        fi
      done
    fi

    if [ -f "requirements.txt" ]; then
      echo "Found requirements.txt. Installing..."
      pip install --quiet -r requirements.txt 2>/dev/null || {
        echo "Warning: Some requirements.txt deps failed to install."
      }
    fi
  fi
}

setup_npm() {
  if ! check_command "node"; then
    echo "ERROR: node is missing."
    exit 1
  fi
  if ! check_command "npm"; then
    echo "ERROR: npm is missing."
    exit 1
  fi

  cd "$MANUAL_DIR" || { echo "Failed to switch to manual directory"; exit 1; }

  local npm_packages=("@mermaid-js/mermaid-cli@10.9.1")

  if is_docker; then
    if ! "$MANUAL_DIR/node_modules/.bin/mmdc" --version >/dev/null 2>&1; then
      echo "Warning: mmdc (Mermaid CLI) not found. Mermaid diagrams will not work."
    fi
  else
    local need_install=false
    if [ ! -d "node_modules/@mermaid-js" ]; then
      need_install=true
    fi

    if [ "$need_install" = true ]; then
      if [ ! -f "package.json" ]; then
        echo "Creating package.json..."
        npm init -y >/dev/null 2>&1
      fi
      echo "Installing Mermaid CLI..."
      npm install "${npm_packages[@]}" --save-exact || { echo "Failed to install Mermaid CLI."; exit 1; }
    fi

    if [ -f "$MANUAL_DIR/node_modules/.bin/mmdc" ]; then
      echo "Mermaid CLI found."
    else
      echo "Warning: mmdc not installed. Mermaid diagrams will not render."
    fi
  fi
}

setup_fira_font() {
  echo "Checking for Fira Code font..."

  local fira_fonts=(
    "FiraCode-Bold.ttf"
    "FiraCode-Light.ttf"
    "FiraCode-Medium.ttf"
    "FiraCode-Regular.ttf"
    "FiraCode-Retina.ttf"
    "FiraCode-SemiBold.ttf"
  )

  check_project_fonts() {
    local all_found=true
    for font in "${fira_fonts[@]}"; do
      if [ ! -f "$FONTS_DIR/$font" ]; then
        all_found=false
        break
      fi
    done
    [ "$all_found" = true ]
  }

  if check_project_fonts; then
    echo "Fira Code fonts found in project."
    return 0
  fi

  # Check system fonts
  if find /usr/share/fonts /usr/local/share/fonts ~/.fonts ~/.local/share/fonts -name "FiraCode*.ttf" 2>/dev/null | grep -q .; then
    echo "Fira Code found in system fonts."
    return 0
  fi

  echo "Fira Code font not found. Downloading..."
  mkdir -p "$FONTS_DIR" || { echo "Failed to create fonts directory."; exit 1; }

  local fira_version="6.2"
  local fira_url="https://github.com/tonsky/FiraCode/releases/download/${fira_version}/Fira_Code_v${fira_version}.zip"
  local temp_dir=$(mktemp -d)
  local zip_file="$temp_dir/fira_code.zip"

  if check_command "curl"; then
    curl -L -o "$zip_file" "$fira_url" >/dev/null 2>&1 || { echo "Failed to download Fira Code font."; rm -rf "$temp_dir"; exit 1; }
  elif check_command "wget"; then
    wget -O "$zip_file" "$fira_url" >/dev/null 2>&1 || { echo "Failed to download Fira Code font."; rm -rf "$temp_dir"; exit 1; }
  else
    echo "Neither curl nor wget available."
    rm -rf "$temp_dir"
    exit 1
  fi

  if check_command "unzip"; then
    unzip -q "$zip_file" -d "$temp_dir" || { echo "Failed to extract font."; rm -rf "$temp_dir"; exit 1; }
  else
    echo "unzip not available."
    rm -rf "$temp_dir"
    exit 1
  fi

  for font in "${fira_fonts[@]}"; do
    if [ -f "$temp_dir/ttf/$font" ]; then
      cp "$temp_dir/ttf/$font" "$FONTS_DIR/"
    fi
  done

  rm -rf "$temp_dir"
  echo "Fira Code fonts installed."
}

main() {
  check_system_deps
  setup_python
  setup_npm
  setup_fira_font
  echo ""
  echo "All dependencies checked."
  echo "Ready to build manual from: $MANUAL_DIR"
}

main
