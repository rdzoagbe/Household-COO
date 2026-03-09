# Read the files
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    lines = f.readlines()

with open('IntegrationConnectors-Clean.jsx', 'r', encoding='utf-8') as f:
    new_component = f.read()

# Replace lines 4527-4914 (indices 4526-4913)
new_lines = lines[:4526] + [new_component + '\n'] + lines[4914:]

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("✅ IntegrationConnectors replaced!")
print(f"   Removed: {4914-4526} lines")
print(f"   Added: {len(new_component.splitlines())} lines")
