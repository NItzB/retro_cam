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
    generate_wind_sound("assets/sounds/wind.wav")
    generate_click_sound("assets/sounds/click.wav")
    print("Vintage sounds generated.")
