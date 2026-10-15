"""把 game-icons.net 的 SVG 图标转成模组用的白色透明贴图（128x128 PNG），再用 hemtt 转 PAA。

图标来自 https://game-icons.net（CC BY 3.0，作者见 docs/CREDITS.md）。

用法（需要 resvg-py、Pillow、hemtt）：
    git clone --depth 1 https://github.com/game-icons/icons <game-icons 目录>
    python3 tools/fetch_icons.py <game-icons 目录> <png 输出目录>
    for f in <png 输出目录>/*.png; do
        hemtt utils paa convert "$f" addons/briefing/ui/icons/$(basename "${f%.png}").paa
    done

图标 id 和 addons/briefing/CfgIcons.hpp 里的类名一致。
"""
import io, os, re, sys
import resvg_py
from PIL import Image

SRC = {
    'inf': 'skoll/winchester-rifle', 'armor': 'lorc/tank', 'mech': 'skoll/apc', 'motor': 'delapouite/jeep',
    'art': 'quoting/field-gun', 'mortar': 'delapouite/mortar', 'aa': 'pierre-leducq/anti-aircraft-gun',
    'recon': 'delapouite/binoculars', 'sniper': 'delapouite/crosshair',
    'heli': 'delapouite/helicopter', 'plane': 'delapouite/jet-fighter', 'uav': 'delapouite/delivery-drone',
    'ship': 'cathelineau/battleship', 'landing': 'delapouite/speed-boat',
    'hq': 'delapouite/military-fort', 'supply': 'delapouite/cargo-crate', 'med': 'sbed/medical-pack',
    'radar': 'lorc/radar-dish', 'bridge': 'delapouite/stone-bridge', 'airfield': 'delapouite/control-tower',
    'fuel': 'skoll/oil-drum', 'comms': 'delapouite/radio-tower',
    'rally': 'lorc/rally-the-troops', 'extract': 'delapouite/exit-door', 'danger': 'lorc/hazard-sign',
    'op': 'lorc/spyglass', 'checkpoint': 'delapouite/stop-sign', 'vip': 'delapouite/prisoner',
    'ied': 'lorc/unlit-bomb', 'ambush': 'lorc/hidden',
}
SIZE = 128

src_dir, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
for icon_id, path in SRC.items():
    svg = open(os.path.join(src_dir, path + '.svg'), encoding='utf-8').read()
    # 去掉黑色背景方块，图形改成纯白
    svg = re.sub(r'<path d="M0 0h512v512H0z"\s*/>', '', svg)
    svg = svg.replace('fill="#000"', 'fill="#fff"')
    png = bytes(resvg_py.svg_to_bytes(svg_string=svg, width=SIZE, height=SIZE))
    alpha = Image.open(io.BytesIO(png)).convert('RGBA').getchannel('A')
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    img.putalpha(alpha)
    img.save(os.path.join(out, f'{icon_id}_ca.png'))
print(len(SRC), 'icons')
