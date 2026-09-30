import sys

path = r'C:\Users\User\.gemini\antigravity-ide\scratch\visualdtb-expo\src\app\index.tsx'

with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

idx = text.find('backgroundMedia.type === \\\'video\\\'')
if idx != -1:
    print(text[idx:idx+800])
