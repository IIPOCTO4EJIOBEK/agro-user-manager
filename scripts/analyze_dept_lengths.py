import json

def get_depts(node, current_path=""):
    name = node['name']
    path = f"{current_path} / {name}" if current_path else name
    results = [path]
    if 'sub' in node:
        for sub in node['sub']:
            results.extend(get_depts(sub, path))
    return results

def main():
    with open('final_structure_mapped.json', 'r', encoding='utf-8') as f:
        structure = json.load(f)
    
    depts = get_depts(structure)
    long_depts = [d for d in depts if len(d) > 64]
    
    print(f"Total departments: {len(depts)}")
    print(f"Departments longer than 64 chars: {len(long_depts)}")
    for d in sorted(long_depts, key=len, reverse=True)[:10]:
        print(f"  ({len(d)}) {d}")

if __name__ == '__main__':
    main()
