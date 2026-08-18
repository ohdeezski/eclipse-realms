
#!/usr/bin/env python3
# Test script for visual resolver asset paths

import os
import sys
import json

def parse_visual_resolver(file_path: str) -> dict:
    """Parse the visual resolver.gd file to extract asset mappings"""
    with open(file_path, 'r') as f:
        content = f.read()

    # Find the avatar_map dictionary
    avatar_map = {}
    in_avatar_map = False
    brace_count = 0
    current_indent = 0

    for line in content.split('\n'):
        line = line.strip()

        if line.startswith('var avatar_map = {'):
            in_avatar_map = True
            continue

        if in_avatar_map:
            if '{' in line:
                brace_count += line.count('{')
            if '}' in line:
                brace_count -= line.count('}')

            if brace_count == 0:
                break

            # Parse JSON-like structure (simplified parsing)
            if ':' in line and ('"' in line or "'" in line):
                # Extract key-value pairs
                parts = line.split(':')
                if len(parts) >= 2:
                    key = parts[0].strip()
                    if key.startswith('"') or key.startswith("'"):
                        key = key[1:-1]  # Remove quotes

                    # Skip methods and function definitions
                    if '=' in key:
                        continue

                    avatar_map[key] = parts[1].strip()

    return avatar_map

def validate_avatar_path(avatar_map: dict, race: str, gender: str, class_name: str) -> bool:
    """Check if an avatar path exists in the map"""
    try:
        path = avatar_map[race][gender][class_name]
        print(f"✓ Found path for {race}/{gender}/{class_name}: {path}")
        return True
    except KeyError as e:
        print(f"✗ Missing path for {race}/{gender}/{class_name}: {e}")
        return False

def main():
    # Find visual resolver
    visual_resolver_path = os.path.join(
        os.getcwd(),
        'client', 'scripts', 'visual_resolver.gd'
    )

    print(f"Looking for visual resolver at: {visual_resolver_path}")

    if not os.path.exists(visual_resolver_path):
        print("ERROR: visual_resolver.gd not found!")
        return 1

    # Parse the visual resolver
    avatar_map = parse_visual_resolver(visual_resolver_path)

    print("=== Validating Avatar Paths ===")

    # Test cases for baseline avatars
    test_cases = [
        ("human", "male", "adept"),
        ("human", "female", "adept"),
        ("elder_mira", "female", "adyta_guide"),
        ("moss_slime", "amorphous", "default"),
    ]

    all_valid = True
    for race, gender, class_name in test_cases:
        if not validate_avatar_path(avatar_map, race, gender, class_name):
            all_valid = False

    if all_valid:
        print("\n✓ All avatar paths are properly configured!")
    else:
        print("\n✗ Some avatar paths are missing or invalid")

    # Show complete avatar map structure
    print("\n=== Complete Avatar Map Structure ===")
    print(json.dumps(avatar_map, indent=2))

    return 0 if all_valid else 1

if __name__ == "__main__":
    sys.exit(main())
