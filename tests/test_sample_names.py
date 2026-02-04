"""Tests for sample name extraction (mirror of lib/sample_name.nf logic)."""
import re
import pytest


def get_sample_id_illumina(path: str) -> str:
    name = path.split("/")[-1]
    m = re.match(r"^(.+?)_S\d+_L\d+", name)
    if m:
        return m.group(1)
    return re.sub(r"\.(fastq|fq)(\.gz)?$", "", name)


def get_sample_id_generic(path: str) -> str:
    name = path.split("/")[-1]
    no_ext = re.sub(r"\.(fastq|fq)(\.gz)?$", "", name)
    no_ext = re.sub(r"_L\d+_R\d+_\d+$", "", no_ext)
    no_ext = re.sub(r"_L\d+_R\d+$", "", no_ext)
    return no_ext


def get_sample_id_first_token(path: str) -> str:
    name = path.split("/")[-1]
    no_ext = re.sub(r"\.(fastq|fq)(\.gz)?$", "", name)
    return no_ext.split("_")[0] if no_ext.split("_")[0] else no_ext


def get_sample_id(path: str, convention: str) -> str:
    c = (convention or "illumina").lower()
    if c == "generic":
        return get_sample_id_generic(path)
    if c == "first_token":
        return get_sample_id_first_token(path)
    return get_sample_id_illumina(path)


@pytest.mark.parametrize(
    "path,expected",
    [
        ("/data/Sample1_S1_L001_R1_001.fastq.gz", "Sample1"),
        ("SampleName_S1_L001_R1_001.fastq.gz", "SampleName"),
        ("/a/b/MySample_S2_L002_R2_001.fq.gz", "MySample"),
        ("single.fastq.gz", "single"),
    ],
)
def test_illumina(path: str, expected: str) -> None:
    assert get_sample_id(path, "illumina") == expected


@pytest.mark.parametrize(
    "path,expected",
    [
        ("/data/Sample1_S1_L001_R1_001.fastq.gz", "Sample1_S1"),
        ("/a/My_Lib_L001_R1_001.fastq.gz", "My_Lib"),
    ],
)
def test_generic(path: str, expected: str) -> None:
    # generic strips _L*_R*_* from end
    assert get_sample_id(path, "generic") == expected


@pytest.mark.parametrize(
    "path,expected",
    [
        ("/data/sample_lane1_R1.fq.gz", "sample"),
        ("prefix_other_here.fastq.gz", "prefix"),
    ],
)
def test_first_token(path: str, expected: str) -> None:
    assert get_sample_id(path, "first_token") == expected
