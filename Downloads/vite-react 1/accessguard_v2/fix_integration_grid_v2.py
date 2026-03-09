with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace the entire category loop structure
old_pattern = '''          {categories.filter(cat => cat !== 'all').map(category => {
            const categoryIntegrations = filteredIntegrations.filter(i => i.category === category);
            if (categoryIntegrations.length === 0) return null;

            return (
              <div key={category}>
                <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
                  <Zap className="h-5 w-5 text-blue-400" />
                  {category}
                </h3>
                <div className="grid gap-6" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))", gridAutoRows: "1fr" }}>
                  {categoryIntegrations.map(integration => {'''

new_pattern = '''          <div className="grid gap-6" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))", gridAutoRows: "1fr" }}>
            {filteredIntegrations.map(integration => {'''

if old_pattern in content:
    content = content.replace(old_pattern, new_pattern)
    print("✅ Replaced category loop with unified grid")
    
    # Also remove the closing braces of the category loop
    # Find and remove the extra closing div and braces
    content = content.replace('''                </div>
              </div>
            );
          })}''', '''          })}''')
    print("✅ Removed category closing tags")
else:
    print("❌ Pattern not found!")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Integration grid fixed!")
