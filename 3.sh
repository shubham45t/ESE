#!/bin/bash

#API_KEY="AIzaSyAHSNya8LslfCOGDANL4yvOVTHRABzHg0Y"
API_KEY="AIzaSyC2cnq9zUKNou9IEY_q0kF9eWoJSk9nnDs"
while true
do
read -p "Exam> " prompt

[[ "$prompt" == "exit" ]] && break

ROOT=$(pwd)

FILES=$(
find "$ROOT" \
-maxdepth 2 \
-type f \
\( \
-name "*.txt" -o \
-name "*.md" -o \
-name "*.sh" -o \
-name "*.yaml" -o \
-name "*.yml" -o \
-name "*.json" -o \
-name "*.xml" -o \
-name "*.rego" \
\) \
2>/dev/null \
| head -20
)

DATA=""

for f in $FILES
do
DATA="$DATA

FILE: $f
--------------------------------
$(head -80 "$f" 2>/dev/null)
"
done

STRUCTURE=$(ls -la)

QUESTION="
You are solving HackerEarth DevOps/Linux/Git/CI-CD questions.

Rules:
- Inspect provided files.
- Prefer terminal commands.
- Keep answer short.
- Mention exact files to edit.
- Mention exact commands.
- If not enough data say: inspect more files.

Directory:
$STRUCTURE

Files:
$DATA

Question:
$prompt
"

JSON=$(printf '%s' "$QUESTION" | python3 -c '
import json,sys
print(json.dumps(sys.stdin.read()))
')

curl -s \
"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$API_KEY" \
-H "Content-Type: application/json" \
-X POST \
-d "{\"generationConfig\":{\"maxOutputTokens\":300,\"temperature\":0.2},\"contents\":[{\"parts\":[{\"text\":$JSON}]}]}" \
| python3 -c '
import json,sys
d=json.load(sys.stdin)

try:
 print("\n"+d["candidates"][0]["content"]["parts"][0]["text"]+"\n")
except:
 print(d)
'

done
