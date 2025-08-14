#!/bin/bash
STACK_NAME="minecraft_stack"
echo "--- Deteniendo stack: $STACK_NAME..."
docker-compose -p "$STACK_NAME" down
echo "--- Stack '$STACK_NAME' detenido con exito."