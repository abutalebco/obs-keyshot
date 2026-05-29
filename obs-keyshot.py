import time
import obspython as obs
from pynput import keyboard


TEXT_SOURCE_NAME = "keyshot"
UPDATE_INTERVAL_MS = 30
FADE_TIMEOUT = 3.0


pressed_keys = {}
event_buffer = []

history = []


SPECIAL_KEYS = {
    "Key.space": "SPACE",
    "Key.enter": "ENTER",
    "Key.shift": "SHIFT",
    "Key.shift_r": "SHIFT",
    "Key.ctrl_l": "CTRL",
    "Key.ctrl_r": "CTRL",
    "Key.alt_l": "ALT",
    "Key.alt_r": "ALT",
    "Key.tab": "TAB",
    "Key.backspace": "BACKSPACE",
    "Key.esc": "ESC",
}


def map_key(key):
    key_str = str(key)

    if key_str in SPECIAL_KEYS:
        return SPECIAL_KEYS[key_str]

    if hasattr(key, "char") and key.char:
        return key.char.upper()

    return key_str.replace("Key.", "").upper()


def detect_combo(keys):
    keys = set(keys)

    # if "CTRL" in keys:
    #     if "C" in keys:
    #         return "CTRL + C"
    #     if "V" in keys:
    #         return "CTRL + V"
    #     if "X" in keys:
    #         return "CTRL + X"
    #     if "A" in keys:
    #         return "CTRL + A"

    # if "ALT" in keys:
    #     if "TAB" in keys:
    #         return "ALT + TAB"
    #     if "F4" in keys:
    #         return "ALT + F4"

    if "SHIFT" in keys and len(keys) == 2:
        other = [k for k in keys if k != "SHIFT"][0]
        return f"SHIFT + {other}"

    if len(keys) == 1:
        return list(keys)[0]

    return None


def on_press(key):
    now = time.time()

    k = map_key(key)

    pressed_keys[k] = now

    event_buffer.append({
        "key": k,
        "time": now
    })


listener = keyboard.Listener(on_press=on_press)


last_text = ""

def update_obs(text):
    global last_text

    if text == last_text:
        return

    last_text = text

    source = obs.obs_get_source_by_name(TEXT_SOURCE_NAME)

    if source is None:
        return

    settings = obs.obs_data_create()
    obs.obs_data_set_string(settings, "text", text)
    obs.obs_source_update(source, settings)

    obs.obs_data_release(settings)
    obs.obs_source_release(source)


previous_combo = None

def process():
    global history
    global previous_combo

    now = time.time()

    for k, t in list(pressed_keys.items()):
        if now - t > 0.3:
            del pressed_keys[k]

    while event_buffer:

        event = event_buffer.pop(0)

        current_keys = set(pressed_keys.keys())

        combo = detect_combo(current_keys)

        if combo and combo != previous_combo:
            text = combo
            previous_combo = combo
        else:
            text = event["key"]
            previous_combo = None

        if history and history[0]["text"] == text:
            history[0]["count"] += 1
            history[0]["time"] = now

        else:
            history.insert(0, {
                "text": text,
                "count": 1,
                "time": now
            })

    history[:] = [
        h for h in history
        if now - h["time"] < FADE_TIMEOUT
    ]

    lines = []

    for h in history:
        if h["count"] > 1:
            lines.append(f"{h['text']} x{h['count']}")
        else:
            lines.append(h["text"])

    update_obs("\n".join(lines))


def script_description():
    return """
    Keyshot Overlay
    
    How to Use it:
    - Create a Text Source and Name it "keyshot"
    """

def script_load(settings):
    listener.start()
    obs.timer_add(process, UPDATE_INTERVAL_MS)
    print("Keyshot overlay loaded")


def script_unload():
    obs.timer_remove(process)
    print("Keyshot overlay unloaded")