import os
import subprocess
import csv
import datetime

def ensure_repo(repo_dir="General", remote="https://github.com/codedownio/General.git"):
    """
    If `repo_dir/` does not exist, do `git clone`. Otherwise, do `git fetch` to get latest commits.
    """
    if not os.path.isdir(repo_dir):
        print(f"Cloning {remote} into {repo_dir}/ …")
        subprocess.run(
            ["git", "clone", "--mirror", remote, repo_dir],
            check=True
        )
    else:
        print(f"Fetching newest commits in {repo_dir}/ …")
        # For a bare/mirrored clone, just do git fetch:
        subprocess.run(
            ["git", "--git-dir", repo_dir, "fetch", "--all"],
            check=True
        )


def commits_on_date_with_message(date_iso: str, repo_dir="General") -> list[str]:
    """
    Return a list of commit hashes from repo `repo_dir` whose commit-date is exactly `date_iso`
    and whose message contains "Automatic update to JuliaRegistries...".

    We do this by calling out to `git log` with --since/--until and --grep=…
    """
    # We want the full day time window:
    #   since = YYYY-MM-DD 00:00:00
    #   until = YYYY-MM-DD 23:59:59
    # (Git’s --since is inclusive, --until is inclusive as well.)
    since = f"{date_iso} 00:00:00"
    until = f"{date_iso} 23:59:59"

    # Base command (bare / mirror repo)
    git_dir_arg = ["--git-dir", repo_dir]
    cmd = [
        "git", *git_dir_arg,
        "log",
          f"--since={since}",
          f"--until={until}",
          "--grep=Automatic update to JuliaRegistries...",
          "--pretty=%H"    # just output hash per line
    ]

    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    return lines


def gather_all_dates(date_list: list[str], output_csv="commits_by_date.csv"):
    """
    - date_list: ["2019-Mar-14", "2019-May-05", …]
    - Convert each to ISO (YYYY-MM-DD).
    - Call commits_on_date_with_message(...) for each.
    - Write rows [iso_date, commit_hash] to CSV.
    """
    # 1) Make sure the repo is cloned/fetched
    ensure_repo(repo_dir="General", remote="https://github.com/codedownio/General.git")

    # 2) Open CSV and write header
    with open(output_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["date", "commit_hash"])

        for raw in date_list:
            # Parse "YYYY-Mon-DD"  → datetime.date
            try:
                dt = datetime.datetime.strptime(raw, "%Y-%b-%d").date()
            except ValueError:
                raise ValueError(f"Cannot parse date {raw!r}. Make sure month is 3-letter English.")
            iso = dt.isoformat()  # "2019-03-14"

            # Grab all matching commits
            hashes = commits_on_date_with_message(iso, repo_dir="General")
            for h in hashes:
                writer.writerow([iso, h])

    print(f"CSV written to {output_csv}")


if __name__ == "__main__":
    raw_dates = [
        "2019-Mar-14", "2019-May-05", "2019-Jul-22", "2019-Dec-19",
        "2020-Mar-12", "2020-Apr-27", "2020-Jun-22", "2020-Aug-20",
        "2020-Oct-30", "2021-Feb-26", "2021-Apr-01", "2021-May-29",
        "2021-Aug-03", "2021-Oct-28", "2022-Jan-16", "2022-Apr-19",
        "2022-Jun-22", "2022-Aug-22", "2022-Oct-20", "2022-Dec-20",
        "2023-Feb-13", "2023-Apr-01", "2023-Jun-15", "2023-Aug-15",
        "2023-Oct-30", "2023-Dec-30", "2024-Feb-29", "2024-Apr-29",
        "2024-Jun-14", "2024-Aug-19", "2024-Oct-01", "2024-Dec-14",
        "2025-Jan-14", "2025-Jan-24", "2025-Jan-27", "2025-Feb-03",
        "2025-Feb-10", "2025-Feb-17", "2025-Feb-24", "2025-Feb-28",
        "2025-Mar-03", "2025-Mar-10", "2025-Mar-17", "2025-Mar-24",
        "2025-Mar-31", "2025-Apr-07", "2025-Apr-11", "2025-Apr-14",
        "2025-Apr-16", "2025-Apr-29", "2025-May-05", "2025-May-16",
    ]

    gather_all_dates(raw_dates, output_csv="commits_by_date.csv")

