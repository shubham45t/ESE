#!/bin/bash

API_KEY="AIzaSyCgeazwFEFu-3w2gygXGJKGsqdLDmx0C8U"

while true
do
read -p "Ask: " prompt
[[ "$prompt" == "exit" ]] && break

context=$(find . -type f -exec cat {} + 2>/dev/null | head -c 12000)

TEXT=$(printf '%s\n\nProject Files:\n%s' "$prompt" "$context" | python3 -c '
import sys,json
print(json.dumps(sys.stdin.read()))
')

curl -s \
"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$API_KEY" \
-H "Content-Type: application/json" \
-X POST \
-d "{
\"generationConfig\":{
\"maxOutputTokens\":2000,
\"temperature\":0.2
},
\"contents\":[
{
\"parts\":[
{
\"text\": $TEXT
}
]
}
]
}" | python3 -c '
import sys,json
d=json.load(sys.stdin)

if "candidates" in d:
    print(d["candidates"][0]["content"]["parts"][0]["text"])
else:
    print(d)
'

echo
done
