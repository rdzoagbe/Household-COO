# Read the file
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find AccessPage function
for i, line in enumerate(lines):
    if line.strip().startswith('function AccessPage()'):
        # Insert translation hook after the function declaration and initial state
        # Find a good insertion point (after the last useState before useMemo)
        insert_at = i + 10  # After the initial useState declarations
        
        hook_code = '''  const [language, setLanguage] = useState(() => localStorage.getItem('language') || 'en');
  const t = useTranslation(language);

  // Listen for language changes
  useEffect(() => {
    const handleLangChange = (e) => {
      const newLang = e.detail || localStorage.getItem('language') || 'en';
      setLanguage(newLang);
    };
    window.addEventListener('languagechange', handleLangChange);
    return () => window.removeEventListener('languagechange', handleLangChange);
  }, []);

'''
        lines.insert(insert_at, hook_code)
        break

# Write back
with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ Translation hook added to AccessPage!")
