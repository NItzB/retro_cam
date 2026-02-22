import wave
import math
import random
import struct

def generate_shutter_sound(filename):
    sample_rate = 44100
    duration = 0.4  # Slightly longer for a complex mechanical sound
    n_frames = int(sample_rate * duration)
    
    with wave.open(filename, 'w') as obj:
        obj.setnchannels(1) # mono
        obj.setsampwidth(2) # 2 bytes
        obj.setframerate(sample_rate)
        
        for i in range(n_frames):
            t = i / sample_rate
            
            # 1. Mirror Slap Up (start)
            mirror_up = 0
            if 0.0 <= t < 0.05:
                envelope = math.exp(-(t - 0.0) * 50)
                tone = math.sin(2 * math.pi * 100 * t) 
                noise = random.uniform(-1, 1)
                mirror_up = (tone * 0.3 + noise * 0.7) * envelope
                
            # 2. Shutter Open (sharp click at 0.08s)
            open_click = 0
            if 0.08 <= t < 0.15:
                envelope = math.exp(-(t - 0.08) * 100)
                noise = random.uniform(-1, 1)
                open_click = noise * envelope

            # 3. Shutter Close (second click at 0.12s - speed 1/60s approx)
            close_click = 0
            if 0.12 <= t < 0.2:
                envelope = math.exp(-(t - 0.12) * 100)
                noise = random.uniform(-1, 1)
                close_click = noise * envelope

            # 4. Mirror Return (heavy thud at 0.2s)
            mirror_down = 0
            if 0.2 <= t < 0.4:
                envelope = math.exp(-(t - 0.2) * 30)
                tone = math.sin(2 * math.pi * 80 * t) # Lower pitch
                noise = random.uniform(-1, 1)
                mirror_down = (tone * 0.4 + noise * 0.6) * envelope * 0.8
            
            # Mix
            sample = (mirror_up + open_click + close_click + mirror_down) * 0.8
            
            # Clipping
            if sample > 1.0: sample = 1.0
            if sample < -1.0: sample = -1.0
            
            obj.writeframesraw(struct.pack('<h', int(sample * 32767)))

def generate_wetzlar_shutter_sound(filename):
    sample_rate = 44100
    duration = 0.3  # Snappier, shorter mechanical duration
    n_frames = int(sample_rate * duration)
    
    with wave.open(filename, 'w') as obj:
        obj.setnchannels(1) # mono
        obj.setsampwidth(2) # 2 bytes
        obj.setframerate(sample_rate)
        
        for i in range(n_frames):
            t = i / sample_rate
            
            # 1. Extremely sharp initial snap
            snap = 0
            if 0.0 <= t < 0.03:
                envelope = math.exp(-(t - 0.0) * 150)
                noise = random.uniform(-1, 1)
                snap = noise * envelope * 1.2
                
            # 2. Resonant metallic ring (the "Wetzlar" sound)
            ring = 0
            if 0.0 <= t < 0.2:
                envelope = math.exp(-t * 15)
                tone1 = math.sin(2 * math.pi * 3200 * t) 
                tone2 = math.sin(2 * math.pi * 4500 * t)
                ring = (tone1 * 0.6 + tone2 * 0.4) * envelope * 0.6
                
            # 3. Fast mirror return thud
            thud = 0
            if 0.08 <= t < 0.25:
                envelope = math.exp(-(t - 0.08) * 40)
                tone = math.sin(2 * math.pi * 120 * t) # Low thud
                thud = tone * envelope * 0.9

            # Mix
            sample = (snap + ring + thud) * 0.8
            
            # Clipping
            if sample > 1.0: sample = 1.0
            if sample < -1.0: sample = -1.0
            
            obj.writeframesraw(struct.pack('<h', int(sample * 32767)))

def generate_portra_shutter_sound(filename):
    sample_rate = 44100
    duration = 0.4 
    n_frames = int(sample_rate * duration)
    with wave.open(filename, 'w') as obj:
        obj.setnchannels(1) 
        obj.setsampwidth(2) 
        obj.setframerate(sample_rate)
        for i in range(n_frames):
            t = i / sample_rate
            snap = 0
            if 0.0 <= t < 0.05:
                envelope = math.exp(-(t - 0.0) * 80)
                noise = random.uniform(-1, 1)
                snap = noise * envelope * 0.8
            clack = 0
            if 0.1 <= t < 0.2:
                envelope = math.exp(-(t - 0.1) * 50)
                tone = math.sin(2 * math.pi * 300 * t)
                clack = tone * envelope * 1.0
            sample = (snap + clack) * 0.8
            if sample > 1.0: sample = 1.0
            if sample < -1.0: sample = -1.0
            obj.writeframesraw(struct.pack('<h', int(sample * 32767)))

def generate_kchrome_shutter_sound(filename):
    sample_rate = 44100
    duration = 0.25 
    n_frames = int(sample_rate * duration)
    with wave.open(filename, 'w') as obj:
        obj.setnchannels(1) 
        obj.setsampwidth(2) 
        obj.setframerate(sample_rate)
        for i in range(n_frames):
            t = i / sample_rate
            snap = 0
            if 0.0 <= t < 0.08:
                envelope = math.exp(-(t - 0.0) * 100)
                tone = math.sin(2 * math.pi * 1500 * t) 
                noise = random.uniform(-1, 1)
                snap = (tone * 0.4 + noise * 0.6) * envelope * 1.2
            sample = snap * 0.8
            if sample > 1.0: sample = 1.0
            if sample < -1.0: sample = -1.0
            obj.writeframesraw(struct.pack('<h', int(sample * 32767)))

def generate_superia_shutter_sound(filename):
    sample_rate = 44100
    duration = 0.5 
    n_frames = int(sample_rate * duration)
    with wave.open(filename, 'w') as obj:
        obj.setnchannels(1) 
        obj.setsampwidth(2) 
        obj.setframerate(sample_rate)
        for i in range(n_frames):
            t = i / sample_rate
            snap = 0
            if 0.0 <= t < 0.05:
                envelope = math.exp(-(t - 0.0) * 120)
                noise = random.uniform(-1, 1)
                snap = noise * envelope * 0.9
            motor = 0
            if 0.05 <= t < 0.4:
                envelope = math.exp(-(t - 0.05) * 5)
                tone = math.sin(2 * math.pi * 600 * t)
                motor = tone * envelope * 0.6
            sample = (snap + motor) * 0.8
            if sample > 1.0: sample = 1.0
            if sample < -1.0: sample = -1.0
            obj.writeframesraw(struct.pack('<h', int(sample * 32767)))

def generate_nightcine_shutter_sound(filename):
    sample_rate = 44100
    duration = 0.6 
    n_frames = int(sample_rate * duration)
    with wave.open(filename, 'w') as obj:
        obj.setnchannels(1) 
        obj.setsampwidth(2) 
        obj.setframerate(sample_rate)
        for i in range(n_frames):
            t = i / sample_rate
            snap = 0
            if 0.0 <= t < 0.1:
                envelope = math.exp(-(t - 0.0) * 40)
                tone = math.sin(2 * math.pi * 80 * t)
                noise = random.uniform(-1, 1)
                snap = (tone * 0.8 + noise * 0.2) * envelope * 1.2
            thud = 0
            if 0.3 <= t < 0.5:
                envelope = math.exp(-(t - 0.3) * 30)
                tone = math.sin(2 * math.pi * 60 * t)
                thud = tone * envelope * 1.2
            sample = (snap + thud) * 0.8
            if sample > 1.0: sample = 1.0
            if sample < -1.0: sample = -1.0
            obj.writeframesraw(struct.pack('<h', int(sample * 32767)))

def generate_magic_shutter_sound(filename):
    sample_rate = 44100
    duration = 1.5 
    n_frames = int(sample_rate * duration)
    with wave.open(filename, 'w') as obj:
        obj.setnchannels(1) 
        obj.setsampwidth(2) 
        obj.setframerate(sample_rate)
        for i in range(n_frames):
            t = i / sample_rate
            snap = 0
            if 0.0 <= t < 0.1:
                envelope = math.exp(-(t - 0.0) * 80)
                noise = random.uniform(-1, 1)
                snap = noise * envelope * 0.8
            whir = 0
            if 0.2 <= t < 1.4:
                envelope = 1.0 if 0.2 <= t < 1.2 else math.exp(-(t - 1.2) * 10)
                tone1 = math.sin(2 * math.pi * 400 * t)
                tone2 = math.sin(2 * math.pi * 410 * t)
                whir = (tone1 * 0.5 + tone2 * 0.5) * envelope * 0.5
            sample = (snap + whir) * 0.8
            if sample > 1.0: sample = 1.0
            if sample < -1.0: sample = -1.0
            obj.writeframesraw(struct.pack('<h', int(sample * 32767)))

def generate_wind_sound(filename):
    sample_rate = 44100
    duration = 1.2  # Longer winding action
    n_frames = int(sample_rate * duration)
    
    with wave.open(filename, 'w') as obj:
        obj.setnchannels(1) # mono
        obj.setsampwidth(2) # 2 bytes
        obj.setframerate(sample_rate)
        
        for i in range(n_frames):
            t = i / sample_rate
            
            # Plastic Ratchet Sound
            # A series of clicks consisting of high frequency noise bursts
            
            # Ratchet frequency varies slightly to sound human
            ratchet_period = 0.06 + math.sin(t * 5) * 0.01 
            cycle = (t % ratchet_period) / ratchet_period
            
            click = 0
            if cycle < 0.3:
                # Sharp decay matching plastic high pitch
                envelope = (1.0 - (cycle / 0.3)) ** 2
                # High pass noise simulation
                noise = random.uniform(-1, 1)
                # Add a resonant plastic "tonk"
                resonance = math.sin(2 * math.pi * 800 * t) * math.exp(-cycle * 10)
                click = (noise * 0.8 + resonance * 0.2) * envelope
            
            # Underlying Gear Friction (constant grinding)
            friction = random.uniform(-0.1, 0.1) * 0.3
            
            sample = (click + friction) * 0.8
             
            obj.writeframesraw(struct.pack('<h', int(sample * 32767)))

def generate_click_sound(filename):
    sample_rate = 44100
    duration = 0.05  # Very short click
    n_frames = int(sample_rate * duration)
    
    with wave.open(filename, 'w') as obj:
        obj.setnchannels(1) # mono
        obj.setsampwidth(2) # 2 bytes
        obj.setframerate(sample_rate)
        
        for i in range(n_frames):
            t = i / sample_rate
            
            # Sharp click, fast decay
            envelope = math.exp(-t * 150)
            noise = random.uniform(-1, 1)
            # Add a slight metallic ping
            ping = math.sin(2 * math.pi * 1200 * t) * math.exp(-t * 200)
            
            sample = (noise * 0.4 + ping * 0.6) * envelope * 0.8
             
            obj.writeframesraw(struct.pack('<h', int(sample * 32767)))

if __name__ == "__main__":
    generate_shutter_sound("assets/sounds/shutter.wav")
    generate_wetzlar_shutter_sound("assets/sounds/wetzlar_shutter.wav")
    generate_portra_shutter_sound("assets/sounds/portra_shutter.wav")
    generate_kchrome_shutter_sound("assets/sounds/kchrome_shutter.wav")
    generate_superia_shutter_sound("assets/sounds/superia_shutter.wav")
    generate_nightcine_shutter_sound("assets/sounds/nightcine_shutter.wav")
    generate_magic_shutter_sound("assets/sounds/magic_shutter.wav")
    generate_wind_sound("assets/sounds/wind.wav")
    generate_click_sound("assets/sounds/click.wav")
    print("Vintage sounds generated.")
