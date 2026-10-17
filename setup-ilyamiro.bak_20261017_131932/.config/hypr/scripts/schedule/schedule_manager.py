#!/usr/bin/env python3
import sys
import subprocess
import json
from datetime import datetime, timedelta, time

# Get today's and tomorrow's dates
now = datetime.now()
today_str = now.strftime('%Y-%m-%d')
tomorrow_str = (now + timedelta(days=1)).strftime('%Y-%m-%d')

# Call the old gcal_sync.py
python_bin = '/home/juandiego/.local/state/quickshell/.venv/bin/python'
script_path = '/home/juandiego/.config/quickshell/ii/services/gCloud/gcal_sync.py'

cmd = [python_bin, script_path, 'list', '--start', today_str, '--end', tomorrow_str]
try:
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(res.stdout)
except Exception as e:
    print(json.dumps({"header": "Google Calendar", "link": "https://calendar.google.com", "lessons": []}))
    sys.exit(0)

if data.get('status') != 'success':
    print(json.dumps({"header": "Google Calendar", "link": "https://calendar.google.com", "lessons": []}))
    sys.exit(0)

# Process events
events = data.get('events', [])
timed_events = []
all_day_events = []

for e in events:
    if e.get('isAllDay'):
        all_day_events.append(e)
    else:
        try:
            start_dt = datetime.fromisoformat(e['start'])
            end_dt = datetime.fromisoformat(e['end'])
            # Only include today's timed events
            if start_dt.date() == now.date():
                timed_events.append({
                    'start_epoch': int(start_dt.timestamp()),
                    'end_epoch': int(end_dt.timestamp()),
                    'summary': e.get('summary', 'Sin título'),
                    'description': e.get('description', ''),
                    'location': e.get('location', ''),
                    'start_str': start_dt.strftime('%H:%M'),
                    'end_str': end_dt.strftime('%H:%M')
                })
        except Exception:
            pass

# Sort timed events by start time
timed_events.sort(key=lambda x: x['start_epoch'])

# If no timed events, return empty list or show all-day events
if not timed_events:
    if all_day_events:
        start_day = int(datetime.combine(now.date(), time(8, 0)).timestamp())
        end_day = int(datetime.combine(now.date(), time(18, 0)).timestamp())
        lessons = [{
            "type": "class",
            "start": start_day,
            "end": end_day,
            "subject": ", ".join([e.get('summary', 'Todo el día') for e in all_day_events]),
            "time": "Todo el día",
            "room": "Google Calendar",
            "is_compact": False
        }]
        print(json.dumps({
            "header": "Google Calendar",
            "link": "https://calendar.google.com",
            "lessons": lessons
        }))
    else:
        print(json.dumps({"header": "Google Calendar", "link": "https://calendar.google.com", "lessons": []}))
    sys.exit(0)

# Build timeline boundaries
first_event_start = datetime.fromtimestamp(timed_events[0]['start_epoch'])
start_day_dt = datetime.combine(now.date(), time(8, 0))
if first_event_start < start_day_dt:
    start_day_dt = datetime.combine(now.date(), first_event_start.time())

start_day = int(start_day_dt.timestamp())

last_event_end = datetime.fromtimestamp(timed_events[-1]['end_epoch'])
end_day_dt = datetime.combine(now.date(), time(18, 0))
if last_event_end > end_day_dt:
    end_day_dt = datetime.combine(now.date(), last_event_end.time())

end_day = int(end_day_dt.timestamp())

lessons = []
pointer = start_day

for ev in timed_events:
    ev_start = ev['start_epoch']
    ev_end = ev['end_epoch']
    
    # Add a break/gap before this event if necessary
    if ev_start > pointer:
        lessons.append({
            "type": "break",
            "start": pointer,
            "end": ev_start
        })
    
    # Add Google Calendar Event
    lessons.append({
        "type": "class",
        "start": ev_start,
        "end": ev_end,
        "subject": ev['summary'],
        "time": f"{ev['start_str']} - {ev['end_str']}",
        "room": ev['location'] or ev['description'] or "Google Calendar",
        "is_compact": False
    })
    
    pointer = ev_end

# Add a final break at the end of the day timeline
if pointer < end_day:
    lessons.append({
        "type": "break",
        "start": pointer,
        "end": end_day
    })

output = {
    "header": "Google Calendar",
    "link": "https://calendar.google.com",
    "lessons": lessons
}
print(json.dumps(output))
