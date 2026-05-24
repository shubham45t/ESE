#!/bin/bash

# Set model
MODEL="openrouter/free"

# Put your OpenRouter key here OR export before running
API_KEY="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"

# Conversation memory
history='[]'

echo "Chat started (type exit to quit)"

while true
do
    read -p "You: " prompt

    [[ "$prompt" == "exit" ]] && break

    # Append new message
    history=$(echo "$history" | jq \
        --arg p "$prompt" \
        '. + [{"role":"user","content":$p}]')

    # Keep only last 10 messages
    history=$(echo "$history" | jq 'if length>10 then .[-10:] else . end')

    response=$(curl -s \
      https://openrouter.ai/api/v1/chat/completions \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
          --arg model "$MODEL" \
          --argjson messages "$history" \
          '{
              model:$model,
              messages:$messages
          }')")

    reply=$(echo "$response" | \
        jq -r '.choices[0].message.content')

    echo
    echo "AI: $reply"
    echo

    # Save assistant response
    history=$(echo "$history" | jq \
        --arg r "$reply" \
        '. + [{"role":"assistant","content":$r}]')

done
