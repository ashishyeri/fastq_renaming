#!/usr/bin/env bash
# Create pipeline storage dirs under FASTQ_PIPELINE_ROOT, install prerequisites
# (uv, Java 17+, Miniconda, Nextflow), and write config/paths.config and
# config/install_paths.env (sourceable; adds conda, uv, nextflow to PATH).
# Usage: export FASTQ_PIPELINE_ROOT=/path/to/storage && ./scripts/setup_dirs.sh
# Or:    FASTQ_PIPELINE_ROOT=/path ./scripts/setup_dirs.sh
# Set SKIP_INSTALLS=1 to only create dirs and write config (use existing tools).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$PROJECT_DIR/config"

ROOT="${FASTQ_PIPELINE_ROOT:-$PROJECT_DIR/storage}"
if [[ -z "${FASTQ_PIPELINE_ROOT:-}" ]]; then
  echo "FASTQ_PIPELINE_ROOT is not set. Using default: $ROOT"
fi
mkdir -p "$ROOT"
# Resolve to absolute path
if command -v realpath &>/dev/null; then
  ROOT="$(realpath "$ROOT")"
else
  ROOT="$(cd "$ROOT" && pwd)"
fi

echo "Creating directories under: $ROOT"
mkdir -p "$ROOT/large_files/merged_fastq"
mkdir -p "$ROOT/large_files/fastqc"
mkdir -p "$ROOT/work"
mkdir -p "$ROOT/conda_env"
mkdir -p "$ROOT/miniconda_env"
mkdir -p "$ROOT/conda_packages"
mkdir -p "$ROOT/miniconda_packages"
mkdir -p "$ROOT/tmp"
mkdir -p "$ROOT/bin"
mkdir -p "$CONFIG_DIR"

# ---- Install prerequisites (unless SKIP_INSTALLS=1) ----
install_java() {
  local need_java=1
  if command -v java &>/dev/null; then
    local ver
    ver="$(java -version 2>&1 | head -1)" || true
    if [[ "$ver" =~ 1[789]\.|[2-9][0-9]\. ]]; then
      need_java=0
      echo "Java already installed: $ver"
    fi
  fi
  if [[ "$need_java" -eq 0 ]]; then return 0; fi
  echo "Installing Java 17..."
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if command -v brew &>/dev/null; then
      brew install openjdk@17 2>/dev/null || brew install --cask openjdk@17 2>/dev/null || true
      if [[ -d /opt/homebrew/opt/openjdk@17 ]]; then
        export PATH="/opt/homebrew/opt/openjdk@17/bin:${PATH}"
      elif [[ -d /usr/local/opt/openjdk@17 ]]; then
        export PATH="/usr/local/opt/openjdk@17/bin:${PATH}"
      fi
    else
      echo "  Install Java 17 manually (e.g. brew install openjdk@17 or from https://adoptium.net/)"
      return 1
    fi
  else
    if command -v apt-get &>/dev/null; then
      sudo apt-get update -qq && sudo apt-get install -y openjdk-17-jdk 2>/dev/null || true
    elif command -v yum &>/dev/null; then
      sudo yum install -y java-17-openjdk-devel 2>/dev/null || true
    else
      echo "  Install Java 17 manually for your OS (Nextflow requires Java 17+)"
      return 1
    fi
  fi
  command -v java &>/dev/null && java -version 2>&1 | head -1 || true
}

install_miniconda() {
  if command -v conda &>/dev/null; then
    echo "Conda already installed: $(conda --version)"
    return 0
  fi
  local conda_dir="$ROOT/miniconda3"
  if [[ -x "$conda_dir/bin/conda" ]]; then
    echo "Miniconda already present at $conda_dir"
    export PATH="$conda_dir/bin:${PATH}"
    return 0
  fi
  echo "Installing Miniconda to $conda_dir..."
  local os arch url
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Darwin)
      [[ "$arch" == "arm64" ]] && arch="arm64" || arch="x86_64"
      url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-${arch}.sh"
      ;;
    Linux)
      [[ "$arch" == "aarch64" ]] || arch="x86_64"
      url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${arch}.sh"
      ;;
    *)
      echo "  Unsupported OS for Miniconda: $os"; return 1
      ;;
  esac
  local installer="$ROOT/tmp/miniconda_installer.sh"
  mkdir -p "$ROOT/tmp"
  curl -sSL "$url" -o "$installer"
  bash "$installer" -b -p "$conda_dir"
  rm -f "$installer"
  export PATH="$conda_dir/bin:${PATH}"
  echo "Miniconda installed at $conda_dir"
}

install_uv() {
  if command -v uv &>/dev/null; then
    echo "uv already installed: $(uv --version 2>/dev/null || true)"
    return 0
  fi
  if [[ -x "$ROOT/bin/uv" ]]; then
    echo "uv already present at $ROOT/bin/uv"
    export PATH="$ROOT/bin:${PATH}"
    return 0
  fi
  echo "Installing uv to $ROOT/bin..."
  curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$ROOT/bin" sh
  export PATH="$ROOT/bin:${PATH}"
  echo "uv installed: $(uv --version 2>/dev/null || true)"
}

install_nextflow() {
  if command -v nextflow &>/dev/null; then
    echo "Nextflow already installed: $(nextflow -version 2>/dev/null | head -1 || true)"
    return 0
  fi
  if [[ -x "$ROOT/bin/nextflow" ]]; then
    echo "Nextflow already present at $ROOT/bin/nextflow"
    export PATH="$ROOT/bin:${PATH}"
    return 0
  fi
  if ! command -v java &>/dev/null; then
    echo "Skipping Nextflow install (Java not found). Install Java 17+ and re-run."
    return 1
  fi
  echo "Installing Nextflow to $ROOT/bin..."
  (cd "$ROOT/bin" && curl -s https://get.nextflow.io | bash)
  chmod +x "$ROOT/bin/nextflow"
  export PATH="$ROOT/bin:${PATH}"
  echo "Nextflow installed: $(nextflow -version 2>/dev/null | head -1 || true)"
}

if [[ "${SKIP_INSTALLS:-}" != "1" ]]; then
  echo "--- Checking/installing prerequisites ---"
  install_java || true
  install_miniconda || true
  install_uv || true
  install_nextflow || true
  echo "--- Done prerequisites ---"
fi

# ---- paths.config for Nextflow ----
PATHS_CONFIG="$CONFIG_DIR/paths.config"
cat > "$PATHS_CONFIG" << EOF
// Generated by scripts/setup_dirs.sh - do not edit by hand
params {
    storage_root = "$ROOT"
    work_dir = "$ROOT/work"
    large_files_dir = "$ROOT/large_files"
    merged_fastq_dir = "$ROOT/large_files/merged_fastq"
    publish_fastqc_dir = "$ROOT/large_files/fastqc"
    conda_cache_dir = "$ROOT/conda_env"
    conda_packages_dir = "$ROOT/conda_packages"
    tmp_dir = "$ROOT/tmp"
}
workDir = params.work_dir
conda.cacheDir = params.conda_cache_dir
EOF
echo "Wrote $PATHS_CONFIG"

# ---- Discover and write install_paths.env ----
# Prefer installs under ROOT, then env vars, then existing PATH
CONDA_ROOT="${CONDA_ROOT:-}"
if [[ -z "$CONDA_ROOT" ]] && [[ -x "$ROOT/miniconda3/bin/conda" ]]; then
  CONDA_ROOT="$ROOT/miniconda3"
fi
if [[ -z "$CONDA_ROOT" ]] && command -v conda &>/dev/null; then
  CONDA_ROOT="$(conda info --base 2>/dev/null || true)"
fi
if [[ -z "$CONDA_ROOT" ]] && command -v conda &>/dev/null; then
  _conda_bin="$(command -v conda)"
  CONDA_ROOT="$(dirname "$(dirname "$_conda_bin")")"
fi

MINICONDA_ROOT="${MINICONDA_ROOT:-$CONDA_ROOT}"

UV_BIN=""
if [[ -x "$ROOT/bin/uv" ]]; then
  UV_BIN="$ROOT/bin"
elif [[ -n "${UV_HOME:-}" ]]; then
  UV_BIN="$UV_HOME"
elif [[ -n "${UV_BIN:-}" ]]; then
  :
elif command -v uv &>/dev/null; then
  _uv="$(command -v uv)"
  UV_BIN="$(dirname "$_uv")"
  UV_BIN="$(cd "$UV_BIN" && pwd)"
fi

NEXTFLOW_BIN=""
if [[ -x "$ROOT/bin/nextflow" ]]; then
  NEXTFLOW_BIN="$ROOT/bin"
elif [[ -n "${NEXTFLOW_BIN:-}" ]]; then
  :
elif command -v nextflow &>/dev/null; then
  _nf="$(command -v nextflow)"
  NEXTFLOW_BIN="$(dirname "$_nf")"
  NEXTFLOW_BIN="$(cd "$NEXTFLOW_BIN" && pwd)"
fi

INSTALL_ENV="$CONFIG_DIR/install_paths.env"
{
  echo "# Generated by scripts/setup_dirs.sh - source this to get conda, uv, nextflow on PATH"
  echo "# Usage: source $INSTALL_ENV"
  echo ""
  if [[ -n "$CONDA_ROOT" ]]; then
    echo "export CONDA_ROOT=\"$CONDA_ROOT\""
    echo "export MINICONDA_ROOT=\"$MINICONDA_ROOT\""
    echo 'export PATH="${CONDA_ROOT}/bin:${PATH}"'
  else
    echo "# CONDA_ROOT not found (set CONDA_ROOT or ensure conda is on PATH and re-run)"
  fi
  if [[ -n "$UV_BIN" ]]; then
    echo "export UV_BIN=\"$UV_BIN\""
    echo 'export PATH="${UV_BIN}:${PATH}"'
  else
    echo "# UV_BIN not found (set UV_BIN or install uv and re-run)"
  fi
  if [[ -n "$NEXTFLOW_BIN" ]]; then
    echo "export NEXTFLOW_BIN=\"$NEXTFLOW_BIN\""
    echo 'export PATH="${NEXTFLOW_BIN}:${PATH}"'
  else
    echo "# NEXTFLOW_BIN not found (set NEXTFLOW_BIN or install nextflow and re-run)"
  fi
} > "$INSTALL_ENV"
echo "Wrote $INSTALL_ENV"
echo "Source it so executables are on PATH: source $INSTALL_ENV"
