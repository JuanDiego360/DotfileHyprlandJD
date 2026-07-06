#!/usr/bin/env python3
import sys
import os
import json
import subprocess

STATE_FILE = os.path.expanduser("~/.config/hypr/scripts/quickshell/productivity/timer_state.json")

def load_state():
    if not os.path.exists(STATE_FILE):
        return {"timeLeft": 1500, "running": False, "focusTimeSeconds": 1500}
    try:
        with open(STATE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {"timeLeft": 1500, "running": False, "focusTimeSeconds": 1500}

def save_state(state):
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)

def main():
    if len(sys.argv) < 2:
        print(json.dumps(load_state()))
        return

    cmd = sys.argv[1]
    state = load_state()

    if cmd == "get":
        print(json.dumps(state))
    elif cmd == "set" and len(sys.argv) > 4:
        try:
            state["timeLeft"] = int(sys.argv[2])
            state["running"] = sys.argv[3].lower() == "true"
            state["focusTimeSeconds"] = int(sys.argv[4])
            save_state(state)
        except ValueError:
            pass
        print(json.dumps(state))
    elif cmd == "tick":
        if state["running"]:
            if state["timeLeft"] > 0:
                state["timeLeft"] -= 1
            else:
                state["running"] = False
                subprocess.Popen(["notify-send", "-u", "critical", "Enfoque Completado", "¡Buen trabajo! El temporizador de enfoque ha concluido."])
            save_state(state)
        print(json.dumps(state))
    else:
        print(json.dumps(state))

if __name__ == "__main__":
    main()
