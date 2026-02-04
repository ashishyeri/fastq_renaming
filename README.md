# Nextflow FASTQ pipeline

Pipeline that (1) extracts sample names from FASTQ filenames (multiple conventions), (2) merges FASTQs from multiple lanes per sample, and (3) runs FastQC. Uses a user-provided parent path for all large files, work dir, and Conda/uv caches.

## Prerequisites

The setup script can install these for you under `FASTQ_PIPELINE_ROOT` (see Quick start). Or install manually:

- **Java 17+:** `java -version` (macOS: `brew install openjdk@17`; Linux: e.g. `apt-get install openjdk-17-jdk`)
- **Conda or Miniconda:** for FastQC; script can install Miniconda to `$ROOT/miniconda3`
- **uv:** [Install](https://docs.astral.sh/uv/getting-started/installation/) — script can install to `$ROOT/bin`
- **Nextflow:** script can install to `$ROOT/bin` (requires Java 17+)

Set `SKIP_INSTALLS=1` when running `setup_dirs.sh` to only create dirs and write config (use your existing tools).

## Quick start

1. **Set storage path and run setup (creates dirs and installs prerequisites)**
   ```bash
   export FASTQ_PIPELINE_ROOT=/path/to/your/storage
   ./scripts/setup_dirs.sh
   ```
   This creates `large_files`, `work`, `conda_env`, `conda_packages`, `tmp`, `bin` under that path; installs uv, Miniconda, and Nextflow (and attempts Java on macOS/Linux); and writes `config/paths.config` and `config/install_paths.env`.

2. **Source install paths (so conda, uv, nextflow are on PATH from anywhere)**
   ```bash
   source config/install_paths.env
   ```
   This also sets `UV_PROJECT_ENVIRONMENT` so the project venv is created in your storage path (e.g. `$FASTQ_PIPELINE_ROOT/.venv`), not in the project dir. Optional: add the `source` line to `~/.bashrc`. Verify: `which conda`, `which uv`, `which nextflow`.

3. **Install project (uv) dependencies**
   ```bash
   uv sync
   ```
   The virtual environment is created at `$FASTQ_PIPELINE_ROOT/.venv` (or `$ROOT/.venv`) when you have sourced `config/install_paths.env`.

4. **Test run**
   ```bash
   nextflow run main.nf -c config/paths.config -profile test,conda
   ```
   Uses `tests/testdata/*.fastq.gz`. Check that `$FASTQ_PIPELINE_ROOT/work` and `$FASTQ_PIPELINE_ROOT/large_files` contain task dirs and merged/FastQC outputs.

5. **Full run**
   ```bash
   nextflow run main.nf -c config/paths.config -profile conda --input_fastq_glob '/path/to/*.fastq.gz'
   ```
   Optionally set `--sample_naming_convention illumina|generic|first_token`.

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `input_fastq_glob` | Glob for input FASTQ files | (required) |
| `sample_naming_convention` | `illumina`, `generic`, or `first_token` | `illumina` |
| `storage_root` | Parent path for work/large_files/conda (set via `FASTQ_PIPELINE_ROOT` and setup script) | `./storage` |

## Verification

- **Sample name tests:** `uv run pytest tests/test_sample_names.py -v`
- **Pipeline test:** `nextflow run main.nf -c config/paths.config -profile test,conda` (no failed processes; outputs under `large_files/` and `work/` in storage path)

## Commit messages

Use the prefixes and format in [docs/git_usage.md](docs/git_usage.md): `fix`, `feat`, `perf`, `docs`, `style`, `refactor`, `test`, `chore` (lower case; add a body listing changes when not self-explanatory).

## GitHub: connect, branches, merge

### Connect to a GitHub repo

**Option A — New repo, then connect local project**

1. On GitHub: **Repositories → New** (e.g. `fastq_naming`); do not add a README if you already have one locally.
2. Locally:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: Nextflow FASTQ pipeline"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/fastq_naming.git
   git push -u origin main
   ```

**Option B — Clone existing repo**

```bash
git clone https://github.com/YOUR_USERNAME/fastq_naming.git
cd fastq_naming
```
(Use `git@github.com:YOUR_USERNAME/fastq_naming.git` for SSH.)

**Option C — Add remote to existing repo**

```bash
git remote add origin https://github.com/YOUR_USERNAME/fastq_naming.git
git push -u origin main
```

Use a [Personal Access Token](https://github.com/settings/tokens) for HTTPS; for SSH, add your key in **Settings → SSH and GPG keys** and test with `ssh -T git@github.com`.

### Create a branch

**Command line**
```bash
git checkout main && git pull origin main
git checkout -b feature/my-feature
# or: git switch -c feature/my-feature
```
Push: `git push -u origin feature/my-feature`

**Cursor**
- Click the branch name in the status bar (bottom left) → **+ Create new branch...** → enter name (e.g. `feature/sample-name-illumina`). After committing, use **Publish Branch** or **Sync** to push.

### Merge into main

**Command line**
```bash
git checkout main
git pull origin main
git merge feature/my-feature -m "Add my feature"
git push origin main
```
Or open a Pull Request on GitHub and merge there; then locally: `git checkout main && git pull origin main`.

**Cursor**
- Switch to `main` (branch dropdown) → **Pull** → **⋯** → **Branch** → **Merge Branch...** → choose the feature branch → **Sync** / **Push**.

## Project layout

- `main.nf` — workflow entry; `nextflow.config` — base config (workDir, conda, params).
- `config/paths.config` — generated by setup (storage paths); `config/install_paths.env` — sourceable PATH for conda/uv/nextflow.
- `lib/sample_name.nf` — sample ID and read extraction; `modules/input.nf`, `merge_fastq.nf`, `fastqc.nf` — pipeline steps.
- `scripts/setup_dirs.sh` — create dirs and write paths.config + install_paths.env.
- `tests/test_sample_names.py` — sample-name unit tests; `tests/testdata/` — minimal FASTQs for `-profile test`.
