"""AC 风格简报音效生成脚本（立体声 44.1 kHz）。

风格：低调、硬朗、科技感，全部以目标点的「哔」（ping）为基准，不用旋律、滑音、气流声。
用法（需要 numpy、scipy、ffmpeg）：
    python3 tools/make_sounds.py <输出目录>
    for f in open close draw_start ping ring; do
        ffmpeg -y -i <输出目录>/$f.wav -c:a libvorbis -q:a 6 addons/briefing/sounds/$f.ogg
    done
混响用随机脉冲生成，每次重新生成会有极细微的差别。播放音量在 script_component.hpp 的 SOUND_VOLUME* 里调。
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

# ---------------------------------------------------------------------------
# 统一的声音材料：全部以目标点的「哔」为基准，低调、干、硬
# ---------------------------------------------------------------------------
def blip(f, d=0.12):
    """目标点同款 FM「哔」：短、亮、轻微下坠。"""
    b = fm(f, d, 1.5, 2.5, 0.0008, 0.045, 0.02, glide=0.94)
    sq = filt(square(f, 0.06, 5), 'lowpass', 6000) * env_exp(int(0.06 * SR), 0.0008, 0.02)
    out = b * 0.7
    out[: len(sq)] += sq * 0.18
    return out

def thump(f=80, decay=0.035, drive=2.5):
    """很紧的低频「咚」，略微饱和，硬朗。"""
    t = t_of(decay * 6)
    x = np.sin(2 * np.pi * np.cumsum(f * (1 + 0.6 * np.exp(-t / 0.006))) / SR) * env_exp(len(t), 0.0008, decay)
    x = np.tanh(drive * x) / np.tanh(drive)
    click = filt(rng.standard_normal(int(0.003 * SR)), 'highpass', 2500) * env_exp(int(0.003 * SR), 0.0002, 0.0008)
    x[: len(click)] += click * 0.35
    return x

def tick(f=4200):
    """数据「嗒」：极短的带通噪声。"""
    n = int(0.004 * SR)
    return filt(rng.standard_normal(n), 'bandpass', [f * 0.75, min(f * 1.4, 20000)]) * env_exp(n, 0.0003, 0.0012)

def sound(length):
    return np.zeros((2, int(length * SR)))

# ---- ping：目标点（基准）----
buf = sound(0.5)
blip_ = fm(2093, 0.12, 1.5, 2.5, 0.0008, 0.045, 0.02, glide=0.94)
sq = filt(square(2093, 0.06, 5), 'lowpass', 6000) * env_exp(int(0.06 * SR), 0.0008, 0.02)
place(buf, blip_, 0, 0.7)
place(buf, sq, 0, 0.18)
place(buf, fm(1046.5, 0.1, 2.0, 0.5, 0.001, 0.03), 0, 0.3)
save('ping', finish(reverb(buf, 0.12, 0.2, 0.006), 0.7))

# ---- open：系统接入——低频「咚」+ 同款「哔」（叠低八度加厚）+ 三下很轻的数据「嗒」----
buf = sound(0.8)
place(buf, thump(70, 0.05), 0, 0.75)
place(buf, blip(2093), 0.05, 0.5)
place(buf, blip(1046.5), 0.05, 0.22)
for i, at in enumerate([0.15, 0.175, 0.20]):
    place(buf, tick(4800), at, 0.12, 0.4 * (i - 1))
save('open', finish(reverb(buf, 0.15, 0.15, 0.006), 0.7))

# ---- close：断开——只有低八度的「哔」+ 更轻的「咚」----
buf = sound(0.6)
place(buf, thump(60, 0.045), 0, 0.55)
place(buf, blip(1046.5), 0.02, 0.45)
place(buf, blip(523.25), 0.02, 0.15)
save('close', finish(reverb(buf, 0.15, 0.15, 0.006), 0.55))

# ---- draw_start：画线——三下细碎的数据「嗒」+ 若有若无的「哔」----
buf = sound(0.4)
for i, at in enumerate([0, 0.022, 0.044]):
    place(buf, tick(3800 + 400 * i), at, 0.35, 0.25 * (i - 1))
place(buf, filt(blip(2093), 'lowpass', 3500), 0.0, 0.12)
save('draw_start', finish(reverb(buf, 0.1, 0.12, 0.004), 0.45))

# ---- ring：威胁圈——硬「咚」+ 同音高的两下「哔-哔」（比目标点低，更沉）----
buf = sound(0.7)
place(buf, thump(90, 0.04), 0, 0.65)
place(buf, blip(1568), 0.0, 0.5)
place(buf, blip(1568), 0.085, 0.4)
place(buf, blip(784), 0.0, 0.15)
save('ring', finish(reverb(buf, 0.18, 0.15, 0.006), 0.65))
print('ok')

# ---- intro：开始简报——3 声沉闷、拖长、很轻的「嘀……」（数据链建立）→ 展开：从中间向两边散开的数据流 ----
# 时间轴和 script_component.hpp 的 INTRO_* 一致：嘀 0.00 / 0.50 / 1.00（每声 0.30 秒），展开 1.55
BEEP_INTERVAL, BEEPS, BEEP_LEN, UNFOLD = 0.5, 3, 0.30, 1.55

def soft_beep(f, d):
    """沉闷的长「嘀」：近似正弦，柔和起音，持续后慢慢收，低通让它发闷。"""
    t = t_of(d + 0.25)
    tone = np.sin(2 * np.pi * f * t) + 0.18 * np.sin(2 * np.pi * 2 * f * t)
    a = np.clip(t / 0.018, 0, 1)
    rel = np.where(t < d, 1.0, np.exp(-(t - d) / 0.08))
    sus = 1 - 0.25 * np.clip(t / d, 0, 1)
    return filt(tone * a * rel * sus, 'lowpass', 1800)

buf = sound(2.8)
for i in range(BEEPS):
    place(buf, soft_beep(1046.5, BEEP_LEN), BEEP_INTERVAL * i, 0.30)
# 展开：极短的「嗒」越来越密、越来越宽地散向左右，表现「铺开」（没有低频「咚」）
n = 46
for i in range(n):
    k = i / (n - 1)
    at = UNFOLD + 0.02 + 0.42 * k ** 1.4
    side = 1 if i % 2 else -1
    place(buf, filt(tick(3600 + 2200 * rng.random()), 'lowpass', 7000), at, 0.14 * (1 - 0.7 * k), side * min(1, 0.15 + 0.95 * k))
# 很轻的「刷」，左右声道不相关、逐渐变宽
m = int(0.36 * SR)
tt = np.arange(m) / SR
e = env_exp(m, 0.03, 0.10)
nl = filt(rng.standard_normal(m), 'bandpass', [1800, 7000])
nr = filt(rng.standard_normal(m), 'bandpass', [1800, 7000])
width = np.clip(tt / 0.25, 0, 1)
mid = (nl + nr) / 2
i0 = int(UNFOLD * SR)
buf[0, i0:i0 + m] += 0.08 * e * (mid * (1 - width) + nl * width)
buf[1, i0:i0 + m] += 0.08 * e * (mid * (1 - width) + nr * width)
# 展开那一下用同一个「嘀」音色轻轻收尾，和前面呼应
place(buf, soft_beep(1046.5, 0.12), UNFOLD, 0.22)
save('intro', finish(reverb(buf, 0.22, 0.14, 0.02), 0.6))

# ---- outro：结束简报——和开场成对：数据流从两边向中间收拢 → 合上时一声闷「嘀」→ 两声渐弱的「嘀……」----
# 时间轴和 script_component.hpp 的 OUTRO_* 一致：黑幕 0.10 – 0.50 合拢，0.50 合上，嘀 0.80 / 1.30
CLOSE_START, CLOSE_AT, TAIL_BEEPS = 0.10, 0.50, (0.80, 1.30)
buf = sound(2.6)
n = 40
for i in range(n):
    k = i / (n - 1)
    at = CLOSE_START + (CLOSE_AT - CLOSE_START - 0.02) * k ** 0.8
    side = 1 if i % 2 else -1
    place(buf, filt(tick(3600 + 2200 * rng.random()), 'lowpass', 7000), at, 0.08 + 0.08 * k, side * max(0.05, 1 - 0.95 * k))
# 很轻的「刷」，从宽到窄（和开场相反）
m = int((CLOSE_AT - CLOSE_START + 0.05) * SR)
tt = np.arange(m) / SR
e = np.clip(tt / (m / SR), 0, 1) ** 2 * np.exp(-np.maximum(tt - (m / SR - 0.05), 0) / 0.03)
nl = filt(rng.standard_normal(m), 'bandpass', [1800, 7000])
nr = filt(rng.standard_normal(m), 'bandpass', [1800, 7000])
width = 1 - np.clip(tt / (m / SR), 0, 1)
mid = (nl + nr) / 2
i0 = int(CLOSE_START * SR)
buf[0, i0:i0 + m] += 0.07 * e * (mid * (1 - width) + nl * width)
buf[1, i0:i0 + m] += 0.07 * e * (mid * (1 - width) + nr * width)
place(buf, soft_beep(1046.5, 0.12), CLOSE_AT, 0.26)
for j, at in enumerate(TAIL_BEEPS):
    place(buf, soft_beep(1046.5, 0.30), at, 0.24 * (1 - 0.45 * j))
save('outro', finish(reverb(buf, 0.22, 0.14, 0.02), 0.55))
