#!/usr/bin/env python3
import os
import subprocess
import csv
import sys

def run_cmd(cmd, cwd=None, capture_output=False, text=False, check=False):
    """
    Helper to run a subprocess command.
    """
    return subprocess.run(cmd, cwd=cwd, capture_output=capture_output, text=text, check=check)

def update_registry_nix(nixpkgs_dir, general_commit):
    """
    In nixpkgs_dir, replace rev and sha256 in
    pkgs/development/julia-modules/registry.nix to point to `general_commit`.
    Returns True if file existed and was updated; False if registry.nix not found.
    """
    registry_path = os.path.join(
        nixpkgs_dir,
        "pkgs", "development", "julia-modules", "registry.nix"
    )
    if not os.path.isfile(registry_path):
        return False

    # Read original lines
    with open(registry_path, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    new_lines = []
    for line in lines:
        stripped = line.lstrip()
        indent = line[: len(line) - len(stripped)]

        if stripped.startswith("rev ="):
            new_lines.append(f'{indent}rev = "{general_commit}";')
        elif stripped.startswith("sha256 ="):
            url = f"https://github.com/CodeDownIO/General/archive/{general_commit}.zip"
            prefetch_cmd = ["nix-prefetch-url", "--unpack", url]
            pf = run_cmd(prefetch_cmd, cwd=nixpkgs_dir, capture_output=True, text=True, check=True)
            raw_hash = pf.stdout.strip()
            new_lines.append(f'{indent}sha256 = "sha256-{raw_hash}";')
        else:
            new_lines.append(line)

    # Write updated file
    with open(registry_path, "w", encoding="utf-8") as f:
        f.write("\n".join(new_lines) + "\n")

    # Stage changes
    rel_path = os.path.relpath(registry_path, nixpkgs_dir)
    run_cmd(["git", "add", rel_path], cwd=nixpkgs_dir, check=True)
    return True

def main():
    # Assume this script is run from the rstats-on-nix folder, which contains 'nixpkgs/'.
    root_dir = os.getcwd()
    nixpkgs_dir = os.path.join(root_dir, "nixpkgs")
    csv_path = os.path.join(root_dir, "commits_by_date.csv")
    report_path = os.path.join(root_dir, "report.txt")

    if not os.path.isdir(nixpkgs_dir):
        print("Error: 'nixpkgs' directory not found in the current folder.", file=sys.stderr)
        sys.exit(1)
    if not os.path.isfile(csv_path):
        print("Error: 'commits_by_date.csv' not found in the current folder.", file=sys.stderr)
        sys.exit(1)

    report_lines = []

    # Start on master
    run_cmd(["git", "checkout", "master"], cwd=nixpkgs_dir, check=True)
    run_cmd(["git", "pull", "origin", "master"], cwd=nixpkgs_dir, check=True)

    with open(csv_path, newline="", encoding="utf-8") as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            date_iso = row["date"]         # e.g. "2025-05-16"
            general_commit = row["commit_hash"]

            # Checkout the branch named after the date
            try:
                run_cmd(["git", "checkout", date_iso], cwd=nixpkgs_dir, check=True)
            except subprocess.CalledProcessError:
                report_lines.append(f"{date_iso}: skip (branch '{date_iso}' not found)")
                # Return to master before continuing
                run_cmd(["git", "checkout", "master"], cwd=nixpkgs_dir, check=True)
                continue

            # Update registry.nix if it exists
            updated = update_registry_nix(nixpkgs_dir, general_commit)
            if not updated:
                report_lines.append(f"{date_iso}: skip (registry.nix not found)")
                run_cmd(["git", "checkout", "master"], cwd=nixpkgs_dir, check=True)
                continue

            # Commit changes on this branch
            commit_msg = f"Added Julia Registry at {date_iso}"
            run_cmd(["git", "commit", "-m", commit_msg], cwd=nixpkgs_dir, check=True)
            report_lines.append(f"{date_iso}: committed on branch '{date_iso}'")

            # Return to master for next iteration
            run_cmd(["git", "checkout", "master"], cwd=nixpkgs_dir, check=True)

    with open(report_path, "w", encoding="utf-8") as rpt:
        rpt.write("\n".join(report_lines) + "\n")

    print(f"Done. See '{report_path}' for details.")

if __name__ == "__main__":
    main()

