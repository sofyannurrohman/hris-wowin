import os

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    replacements = {
        'text-blue-600': 'text-primary',
        'text-blue-700': 'text-primary',
        'hover:text-blue-700': 'hover:text-primary',
        'bg-blue-50': 'bg-primary/5',
        'bg-blue-600': 'bg-primary',
        'border-blue-600': 'border-primary',
        'focus:ring-blue-600': 'focus:ring-primary',
        'ring-blue-500': 'ring-primary',
        'from-blue-600': 'from-primary',
        'to-indigo-600': 'to-primary/80',
        'bg-emerald-50': 'bg-emerald-500/10', # Refining other colors too
    }
    
    new_content = content
    for old, new in replacements.items():
        new_content = new_content.replace(old, new)
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated: {filepath}")

def main():
    root_dir = "/home/sofyan/Developments/hris_wowin/frontend-web/src"
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith(('.vue', '.ts', '.css')):
                replace_in_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
