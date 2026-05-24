#!/bin/bash

API_KEY="AIzaSyDNJEWpHpR18WnoxTKOwR_cDcd9rfyi1Bs"

while true
do
read -p "Exam> " prompt
[[ "$prompt" == "exit" ]] && break

TEXT="$prompt"


# ======================
# SEE FILES
# ======================

if echo "$prompt" | grep -Eiq \
"see files|show files|list files|directory|dir|folder"
then

FILES=$(find . \
-maxdepth 2 \
-type f \
| sed 's|^\./||')

TEXT="
SYSTEM:
These files actually exist.

Files:
$FILES

User:
$prompt

Answer only from file names.
Do not inspect contents.
"

fi


# ======================
# INSPECT FILE
# ======================

if echo "$prompt" | grep -Eiq \
"inspect|open|read|explain"
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

TEXT="
SYSTEM:
This file content is real.

File:
$TARGET

Content:
$CONTENT

User:
$prompt

Answer using this file only.
"

else

TEXT="
File not found.

Question:
$prompt
"

fi

fi


# ======================
# JSON
# ======================

JSON=$(
printf '%s' "$TEXT" \
| python3 -c '
import json,sys
print(json.dumps(sys.stdin.read()))
'
)


# ======================
# API
# ======================

curl -s \
"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$API_KEY" \
-H "Content-Type: application/json" \
-X POST \
-d "{
\"generationConfig\":{
\"maxOutputTokens\":300,
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
}" \
| python3 -c '
import json,sys

try:
 d=json.load(sys.stdin)
 print("\n"+d["candidates"][0]["content"]["parts"][0]["text"]+"\n")
except:
 print("API Error")
'

done
