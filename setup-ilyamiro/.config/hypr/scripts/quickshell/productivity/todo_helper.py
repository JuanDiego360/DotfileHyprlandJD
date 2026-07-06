#!/usr/bin/env python3
import sys
import os
import json

TODO_FILE = os.path.expanduser("~/.config/hypr/scripts/quickshell/productivity/todo_list.json")

def load_todos():
    if not os.path.exists(TODO_FILE):
        return []
    try:
        with open(TODO_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return []

def save_todos(todos):
    os.makedirs(os.path.dirname(TODO_FILE), exist_ok=True)
    with open(TODO_FILE, "w", encoding="utf-8") as f:
        json.dump(todos, f, ensure_ascii=False, indent=2)

def main():
    if len(sys.argv) < 2:
        print(json.dumps(load_todos()))
        return

    cmd = sys.argv[1]
    todos = load_todos()

    if cmd == "list":
        print(json.dumps(todos))
    elif cmd == "add" and len(sys.argv) > 2:
        text = " ".join(sys.argv[2:])
        todos.append({"text": text, "done": False})
        save_todos(todos)
        print(json.dumps(todos))
    elif cmd == "toggle" and len(sys.argv) > 2:
        try:
            idx = int(sys.argv[2])
            if 0 <= idx < len(todos):
                todos[idx]["done"] = not todos[idx]["done"]
                save_todos(todos)
        except ValueError:
            pass
        print(json.dumps(todos))
    elif cmd == "delete" and len(sys.argv) > 2:
        try:
            idx = int(sys.argv[2])
            if 0 <= idx < len(todos):
                todos.pop(idx)
                save_todos(todos)
        except ValueError:
            pass
        print(json.dumps(todos))
    else:
        print(json.dumps(todos))

if __name__ == "__main__":
    main()
