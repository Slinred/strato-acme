import re

def extract_version_changelog(version: str, changelog_path: str = "CHANGELOG.md") -> str:
    version = version.lstrip('v')
    
    with open(changelog_path, 'r') as f:
        changelog = f.read()
    
    start_index = None
    end_index = None
    header_detected = True
    header_lines = []
    for Index, Line in enumerate(changelog.splitlines()):
        if start_index is None and header_detected:
            if Line.startswith("##"):
                header_detected = False
            else:
                header_lines.append(Line)
        
        if Line.startswith(f"## [{version}]"):
            start_index = Index
        elif start_index is not None and Line.startswith("## ["):
            end_index = Index
            break
    
    if start_index is None:
        raise ValueError(f"Version {version} not found in changelog.")
    if end_index is None:
        end_index = len(changelog.splitlines())
        
    version_changelog = "\n".join([*header_lines, *changelog.splitlines()[start_index:end_index]]).strip()
    return version_changelog

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python released_changelog.py <version>")
        sys.exit(1)
    
    version = sys.argv[1]
    try:
        changelog = extract_version_changelog(version)
        print(changelog)
    except ValueError as e:
        print(e)
        sys.exit(1)