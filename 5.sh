#!/bin/bash

API_KEY="AIzaSyCt2QX8dojbkl5HBzBtGj_tN6U5v0DQ-To"

MEMORY=""

while true
do
read -p "Exam> " prompt
[[ "$prompt" == "exit" ]] && break

TEXT="$prompt"


# ======================
# DIRECTORY VIEW
# ======================

if echo "$prompt" | grep -Eiq \
"see files|show files|list files|directory|dir|folder"
then

FILES=$(find . -maxdepth 2 -type f | sed 's|^\./||')

TEXT="
SYSTEM:
You CAN see these REAL files.

Files:
$FILES

Answer user question.
"

fi


# ======================
# FILE INSPECTION
# ======================

if echo "$prompt" | grep -Eiq \
"inspect|read|open|explain"
then

TARGET=$(echo "$prompt" \
| grep -oE \
'[a-zA-Z0-9._/-]+\.[a-zA-Z0-9]+')

if [ -f "$TARGET" ]
then

if echo "$prompt" | grep -iq "whole file"
then
CONTENT=$(cat "$TARGET")
else
CONTENT=$(sed -n '1,200p' "$TARGET")
fi

MEMORY="

Current inspected file:
$TARGET

Content:
$CONTENT
"

TEXT="
SYSTEM:
This is REAL file content.

$MEMORY

User:
$prompt

Answer using this file.
"

fi

fi


# ======================
# MEMORY
# ======================

TEXT="
Previous context:
$MEMORY

Current request:
$TEXT
"


JSON=$(printf '%s' "$TEXT" \
| python3 -c '
import json,sys
print(json.dumps(sys.stdin.read()))
')

RESPONSE=$(curl -s \
"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$API_KEY" \
-H "Content-Type: application/json" \
-X POST \
-d "{
\"generationConfig\":{
\"maxOutputTokens\":100,
\"temperature\":0
},
\"contents\":[
{
\"parts\":[
{
\"text\":$JSON
}
]
}
]
}")

ANSWER=$(echo "$RESPONSE" \
| python3 -c '
import json,sys

try:
 d=json.load(sys.stdin)
 print(d["candidates"][0]["content"]["parts"][0]["text"])
except:
 print("API Error")
')

echo
echo "$ANSWER"
echo

MEMORY="$MEMORY

User:
$prompt

AI:
$ANSWER
"

done
