import re
import json
import os

def find_keys(directory):
    keys = set()
    # 匹配 context.tr('...') 和 _tr('...')
    # 兼容单引号和双引号
    pattern = re.compile(r"(?:context\.tr|_tr)\(['\"](.+?)['\"]")
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                    content = f.read()
                    matches = pattern.findall(content)
                    for match in matches:
                        keys.add(match)
    return keys

def load_json(path):
    if not os.path.exists(path):
        return {}
    with open(path, 'r', encoding='utf-8') as f:
        try:
            return json.load(f)
        except Exception as e:
            print(f"Error loading {path}: {e}")
            return {}

code_keys = find_keys('lib')
en_us = load_json('assets/i18n/en-US.json')
zh_cn = load_json('assets/i18n/zh-CN.json')

en_keys = set(en_us.keys())
zh_keys = set(zh_cn.keys())

# 重新计算，因为之前的代码可能因为 key 包含中文而匹配不准
# 实际上 JSON 里的 key 很多就是中文

print(f"Code unique keys: {len(code_keys)}")
print(f"en-US.json keys: {len(en_keys)}")
print(f"zh-CN.json keys: {len(zh_keys)}")

# 1. Code used but missing in en-US
missing_in_en = list(code_keys - en_keys)
print("\n--- Code used but missing in en-US ---")
for k in sorted(missing_in_en)[:20]:
    print(k)

# 2. en-US has but code not used
unused_in_en = list(en_keys - code_keys)
print("\n--- en-US has but code not used ---")
for k in sorted(unused_in_en)[:20]:
    print(k)

# 3. en-US and zh-CN mismatch
mismatch = list(en_keys.symmetric_difference(zh_keys))
print("\n--- en-US and zh-CN mismatch ---")
if not mismatch:
    print("No mismatch found.")
else:
    for k in sorted(mismatch)[:20]:
        status = "(only in en-US)" if k in en_keys else "(only in zh-CN)"
        print(f"{k} {status}")

