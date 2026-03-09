with open('src/App.jsx', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the category loop start (around line 4769)
# Replace categories.filter().map() with filteredIntegrations.map()
for i in range(len(lines)):
    if 'categories.filter(cat => cat !== \'all\').map(category =>' in lines[i]:
        # Replace the line
        lines[i] = '          {filteredIntegrations.map(integration => {\n'
        # Remove the next 5 lines (category filtering logic and header)
        del lines[i+1:i+6]
        print(f"✅ Replaced category loop at line {i+1}")
        break

# Remove the extra closing brace at the end of the category loop
for i in range(len(lines)-1, 0, -1):
    if '          })}' in lines[i] and 'filteredIntegrations.map' in ''.join(lines[max(0, i-200):i]):
        lines[i] = '          })}\n'
        print(f"✅ Fixed closing brace at line {i+1}")
        break

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ Integration grid fixed!")
