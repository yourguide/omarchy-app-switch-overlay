#!/usr/bin/env python3
# Generates the Hulk Smash overlay sounds (pure python, no numpy). Peaks match swoosh.wav (0.35).
import wave, struct, random, math, os
SR = 44100
D = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'sounds')

def save(name, s, peak=0.35):
    pk = max(abs(v) for v in s) or 1
    s = [v / pk * peak for v in s]
    w = wave.open(os.path.join(D, name), 'wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, v)) * 32767)) for v in s)); w.close()
    print(name, round(len(s) / SR * 1000), 'ms')

def fade_tail(s, n=300):
    for i in range(min(n, len(s))): s[-1 - i] *= i / n
    return s

def thud(ms, f0, f1, decay, crack, seed, body=1.0):
    random.seed(seed); n = int(SR * ms / 1000); out = []; ph = 0.0; hp_prev = 0.0; lp = 0.0
    for i in range(n):
        t = i / SR
        f = f1 + (f0 - f1) * math.exp(-t / 0.03)          # pitch drop
        ph += 2 * math.pi * f / SR
        att = min(1.0, t / 0.0008)                         # <1 ms attack, starts at sample 0
        low = math.sin(ph) * math.exp(-t / decay) * att
        mid = math.sin(ph * 2.3) * math.exp(-t / (decay * 0.35)) * 0.45 * body
        x = random.uniform(-1, 1); hp = x - hp_prev; hp_prev = x   # crack transient (bright)
        cr = hp * math.exp(-t / 0.006) * crack
        lp += 0.08 * (x - lp)                                         # dusty rumble
        rum = lp * math.exp(-t / (decay * 1.6)) * 0.9
        v = low + mid + cr + rum
        out.append(math.tanh(v * 1.6))                     # soft clip = punchier
    return fade_tail(out)

def crumble(ms, seed):
    random.seed(seed); n = int(SR * ms / 1000); out = [0.0] * n
    def grain(start, length, bright, amp):
        lp = 0.0; prev = 0.0
        for k in range(length):
            i = start + k
            if i >= n: break
            x = random.uniform(-1, 1); lp += bright * (x - lp); bp = lp - prev; prev = lp
            out[i] += bp * amp * math.exp(-k / (length * 0.3))
    def tink(start, f, amp):
        for k in range(int(SR * 0.03)):
            i = start + k
            if i >= n: break
            t = k / SR; out[i] += math.sin(2 * math.pi * f * t) * amp * math.exp(-t / 0.008)
    grain(0, int(SR * 0.02), 0.9, 2.2)                     # initial crack at sample 0
    t = 0.004
    while t < ms / 1000 - 0.03:
        rate = 0.004 + 0.03 * (t / (ms / 1000))            # grains thin out
        amp = 1.4 * math.exp(-t / 0.16)
        grain(int(t * SR), int(SR * random.uniform(0.004, 0.014)), random.uniform(0.3, 0.9), amp)
        if random.random() < 0.35: tink(int(t * SR), random.uniform(2600, 5200), amp * 0.35)
        t += rate * random.uniform(0.5, 1.5)
    return fade_tail(out, 600)

save('hulk-slam.wav', thud(210, 95, 42, 0.075, 1.4, 3))
save('hulk-punch.wav', thud(120, 140, 70, 0.035, 0.9, 5, body=0.7), peak=0.3)
save('hulk-shatter.wav', crumble(380, 9), peak=0.3)
