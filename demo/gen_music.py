"""生成一段柔和的背景铺底音乐（纯合成，无版权问题）。"""
import wave
from pathlib import Path

import numpy as np

SR = 44100
DUR = 23.0
HERE = Path(__file__).parent

# 和弦（Hz），每段约 5.75s
CHORDS = [
    [220.00, 277.18, 329.63, 415.30],   # Amaj7
    [185.00, 220.00, 277.18, 329.63],   # F#m7
    [146.83, 185.00, 220.00, 277.18],   # Dmaj7
    [164.81, 207.65, 246.94, 277.18],   # E6
]

n = int(SR * DUR)
t = np.arange(n) / SR
out = np.zeros((n, 2), dtype=np.float64)

seg_len = DUR / len(CHORDS)

out = np.zeros((n, 2), dtype=np.float64)
for ci, chord in enumerate(CHORDS):
    start = ci * seg_len - (0.45 if ci else 0)
    end = (ci + 1) * seg_len + 0.45
    i0 = max(0, int(start * SR))
    i1 = min(n, int(end * SR))
    length = i1 - i0
    x = np.linspace(0, 1, length)
    f = int(1.1 * SR / 2)
    e = np.ones(length)
    f = min(f, length // 2)
    e[:f] = 0.5 - 0.5 * np.cos(np.pi * x[:f])
    e[-f:] = 0.5 - 0.5 * np.cos(np.pi * (1 - x[-f:]))
    for f0 in chord:
        for det in (-0.0012, 0.0012):
            freq = f0 * (1 + det)
            for k, amp in ((1, 1.0), (2, 0.18), (3, 0.06)):
                phase = np.random.rand() * 2 * np.pi
                s = np.sin(2 * np.pi * freq * k * t[i0:i1] + phase) * amp
                lfo = 1 + 0.1 * np.sin(2 * np.pi * 0.06 * t[i0:i1] + phase)
                out[i0:i1, 0] += s * lfo * e
                out[i0:i1, 1] += s * lfo * e * 0.92

# 轻微低通（一阶），去掉刺耳高频
alpha = 0.18
for ch in range(2):
    y = np.empty_like(out[:, ch])
    acc = 0.0
    for i in range(0, n, 1):
        acc += alpha * (out[i, ch] - acc)
        y[i] = acc
    out[:, ch] = y

# 柔和的钟琴点缀，每 2.3s 一下
for i in range(int(1.2 * SR), n, int(2.3 * SR)):
    f0 = CHORDS[(i // int(seg_len * SR)) % len(CHORDS)][2] * 2
    length = int(1.8 * SR)
    length = min(length, n - i)
    tt = np.arange(length) / SR
    tone = np.sin(2 * np.pi * f0 * tt) * np.exp(-tt * 3.2) * 0.06
    out[i:i + length, 0] += tone
    out[i:i + length, 1] += tone * 0.85

# 首尾淡入淡出
fade_n = int(1.2 * SR)
env = np.ones(n)
env[:fade_n] = np.linspace(0, 1, fade_n) ** 1.6
env[-fade_n:] = np.linspace(1, 0, fade_n) ** 1.6
out *= env[:, None]

# 归一化到 -19 dBFS 左右
peak = np.max(np.abs(out))
out = out / peak * 0.11
pcm = (out * 32767).astype(np.int16)

with wave.open(str(HERE / "bgm.wav"), "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print("bgm.wav done")