"""AC 风格简报音效生成脚本（立体声 44.1 kHz）。

用法（需要 numpy、scipy、ffmpeg）：
    python3 tools/make_sounds.py <输出目录>
    for f in open close draw_start ping ring; do
        ffmpeg -y -i <输出目录>/$f.wav -c:a libvorbis -q:a 6 addons/briefing/sounds/$f.ogg
    done
"""
import sys, numpy as np, wave
from scipy.signal import butter, sosfilt, fftconvolve

SR = 44100
rng = np.random.default_rng(1995)
out_dir = sys.argv[1]

def t_of(d): return np.arange(int(d * SR)) / SR
def silence(d): return np.zeros(int(d * SR))

def env_exp(n, attack, decay):
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    return a * np.exp(-np.maximum(t - attack, 0) / decay)

def filt(x, kind, f):
    sos = butter(4, f, btype=kind, fs=SR, output='sos')
    return sosfilt(sos, x)

def fm(f, d, ratio, index, attack, decay, idecay=None, glide=None):
    t = t_of(d)
    fc = f if glide is None else f * np.exp(np.log(glide) * t / d)
    phase = 2 * np.pi * np.cumsum(fc) / SR
    ienv = index * np.exp(-t / (idecay or decay))
    s = np.sin(phase + ienv * np.sin(phase * ratio))
    return s * env_exp(len(t), attack, decay)

def square(f, d, harmonics=9):
    t = t_of(d)
    return sum(np.sin(2 * np.pi * f * k * t) / k for k in range(1, 2 * harmonics, 2))

def place(buf, sig, at, gain=1.0, pan=0.0):
    # 结尾 8 ms 淡出，避免截断产生「咔哒」声
    sig = sig.copy()
    f = min(len(sig), int(0.008 * SR))
    sig[-f:] *= np.linspace(1, 0, f)
    i = int(at * SR)
    n = min(len(sig), buf.shape[1] - i)
    l = np.cos((pan + 1) * np.pi / 4); r = np.sin((pan + 1) * np.pi / 4)
    buf[0, i:i + n] += sig[:n] * gain * l * 1.414
    buf[1, i:i + n] += sig[:n] * gain * r * 1.414

def reverb(buf, decay, wet, predelay=0.012):
    n = int(decay * 4 * SR)
    t = np.arange(n) / SR
    out = np.zeros((2, buf.shape[1] + n))
    for ch in range(2):
        ir = rng.standard_normal(n) * np.exp(-t / decay)
        ir = filt(ir, 'lowpass', 6500)
        ir[: int(predelay * SR)] = 0
        ir /= np.sqrt(np.sum(ir ** 2))
        out[ch, : buf.shape[1]] += buf[ch]
        conv = fftconvolve(buf[ch], ir)[: out.shape[1]]
        out[ch, : len(conv)] += wet * conv
    return out

def finish(buf, peak, tail_fade=0.05):
    # trim trailing near-silence, short fade, normalise
    mag = np.max(np.abs(buf), axis=0)
    last = np.nonzero(mag > 2e-3 * mag.max())[0][-1] + 1
    buf = buf[:, :last]
    f = int(tail_fade * SR)
    buf[:, -f:] *= np.linspace(1, 0, f)
    buf = buf - np.mean(buf, axis=1, keepdims=True)
    return buf / np.max(np.abs(buf)) * peak

def save(name, buf):
    data = (np.clip(buf.T, -1, 1) * 32767).astype('<i2')
    with wave.open(f'{out_dir}/{name}.wav', 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data.tobytes())

def chatter(buf, start, end, count, gain):
    # 数据流：随机的高频短 blip
    for at in np.sort(rng.uniform(start, end, count)):
        f = rng.choice([2637, 3136, 3520, 4186, 4699])
        b = filt(square(f, 0.012, 4), 'lowpass', 7000) * env_exp(int(0.012 * SR), 0.001, 0.004)
        place(buf, b, at, gain * rng.uniform(0.5, 1), rng.uniform(-0.7, 0.7))

def whoosh(d, f0, f1, gain=1.0):
    # 带通噪声扫频
    n = int(d * SR); x = rng.standard_normal(n); out = np.zeros(n)
    edges = np.linspace(0, n, 25).astype(int)
    for a, b in zip(edges[:-1], edges[1:]):
        fc = f0 * (f1 / f0) ** (((a + b) / 2) / n)
        seg = filt(x, 'bandpass', [fc / 1.5, min(fc * 1.5, SR / 2 - 100)])[a:b]
        out[a:b] = seg
    return out * np.sin(np.pi * np.arange(n) / n) ** 2 * gain

# ---- open：系统启动——低频涌起 + 上扫气流 + 数据流 + 两声玻璃质感确认音 ----
buf = np.zeros((2, int(1.6 * SR)))
t = t_of(0.9)
sub = np.sin(2 * np.pi * np.cumsum(np.linspace(48, 72, len(t))) / SR) * np.minimum(t / 0.3, 1) * np.exp(-np.maximum(t - 0.3, 0) / 0.25)
place(buf, sub, 0, 0.9)
place(buf, whoosh(0.42, 250, 4200), 0, 0.35)
chatter(buf, 0.05, 0.36, 14, 0.18)
place(buf, fm(1318.5, 0.9, 3.5, 2.2, 0.003, 0.32, 0.08), 0.34, 0.55, -0.25)
place(buf, fm(1975.5, 1.0, 3.5, 2.2, 0.003, 0.40, 0.08), 0.46, 0.55, 0.25)
place(buf, fm(659.3, 1.0, 2.0, 0.8, 0.005, 0.45), 0.34, 0.25)
save('open', finish(reverb(buf, 0.45, 0.35), 0.85))

# ---- close：确认音下行 + 断电下沉 ----
buf = np.zeros((2, int(1.3 * SR)))
place(buf, fm(1975.5, 0.7, 3.5, 2.0, 0.003, 0.22, 0.06), 0.0, 0.45, 0.25)
place(buf, fm(1318.5, 0.8, 3.5, 2.0, 0.003, 0.28, 0.06), 0.10, 0.45, -0.25)
t = t_of(0.7)
down = np.sin(2 * np.pi * np.cumsum(420 * np.exp(np.log(55 / 420) * t / 0.7)) / SR) * np.exp(-t / 0.22) * np.minimum(t / 0.01, 1)
place(buf, filt(down, 'lowpass', 1200), 0.18, 0.7)
place(buf, whoosh(0.45, 3500, 200), 0.12, 0.25)
save('close', finish(reverb(buf, 0.4, 0.3), 0.75))

# ---- draw_start：航线计算——加速的数字嘀嗒 + 很轻的上扬底音 ----
buf = np.zeros((2, int(0.9 * SR)))
at, gap, k = 0.0, 0.05, 0
while at < 0.46:
    f = 2600 * (1 + 0.6 * at / 0.46)
    tick = filt(rng.standard_normal(int(0.006 * SR)), 'bandpass', [f * 0.8, f * 1.4]) * env_exp(int(0.006 * SR), 0.0005, 0.0015)
    tone = np.sin(2 * np.pi * f * t_of(0.02)) * env_exp(int(0.02 * SR), 0.001, 0.006)
    g = min(1, 0.4 + at * 2) * (1 if at < 0.38 else (0.46 - at) / 0.08)
    pan = 0.35 * np.sin(k * 1.7)
    place(buf, tick * 2.5, at, 0.5 * g, pan)
    place(buf, tone * 0.5, at, 0.5 * g, pan)
    at += gap; gap = max(0.016, gap * 0.86); k += 1
t = t_of(0.5)
glide = np.sin(2 * np.pi * np.cumsum(np.linspace(520, 1040, len(t))) / SR) * np.sin(np.pi * t / 0.5) ** 2
place(buf, filt(glide, 'lowpass', 1500), 0, 0.18)
save('draw_start', finish(reverb(buf, 0.2, 0.18), 0.8))

# ---- ping：目标指定——清脆短促的数字「哔」 ----
buf = np.zeros((2, int(0.5 * SR)))
blip = fm(2093, 0.12, 1.5, 2.5, 0.0008, 0.045, 0.02, glide=0.94)
sq = filt(square(2093, 0.06, 5), 'lowpass', 6000) * env_exp(int(0.06 * SR), 0.0008, 0.02)
place(buf, blip, 0, 0.7)
place(buf, sq, 0, 0.18)
place(buf, fm(1046.5, 0.1, 2.0, 0.5, 0.001, 0.03), 0, 0.3)
save('ping', finish(reverb(buf, 0.12, 0.2, 0.006), 0.7))

# ---- ring：威胁圈——声纳般的低沉「嗡」 + 三下锁定警告 ----
buf = np.zeros((2, int(1.6 * SR)))
place(buf, fm(880, 1.2, 1.41, 1.6, 0.004, 0.42, 0.15, glide=0.93), 0, 0.55)
t = t_of(0.35)
thump = np.sin(2 * np.pi * np.cumsum(np.linspace(110, 60, len(t))) / SR) * env_exp(len(t), 0.002, 0.08)
place(buf, thump, 0, 0.8)
for i, at in enumerate([0.14, 0.24, 0.34]):
    b = filt(square(1568, 0.055, 6), 'lowpass', 5000) * env_exp(int(0.055 * SR), 0.002, 0.05) * np.minimum(np.linspace(1, 0, int(0.055 * SR)) * 8, 1)
    place(buf, b, at, 0.32 * (1 - 0.22 * i), 0.2 * (i - 1))
save('ring', finish(reverb(buf, 0.5, 0.38), 0.8))
print('ok')
