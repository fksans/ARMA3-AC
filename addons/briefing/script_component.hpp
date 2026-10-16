// AC Briefing - shared macros (config + SQF)
// 不依赖 CBA 的宏头文件，保持构建时无需额外 include。

#include "script_version.hpp"

#define PREFIX brf
#define COMPONENT briefing
#define ADDON brf_briefing

#define QUOTE(var) #var

// 元素记录 BRF_els 的下标：[id, 类型, 颜色序号, 数据, t0, t1, 缓存]
// 前 4 项就是网络上传的元素（见 DESIGN.md「数据模型」），后 3 项只在本机
#define E_ID 0
#define E_TYPE 1
#define E_COLOR 2
#define E_DATA 3
#define E_T0 4
#define E_T1 5
#define E_CACHE 6
#define E_AUTHOR 7

// 原版标记镜像：名字前缀（只动这个前缀的标记）、旧版「转标记」的前缀、补建间隔
#define MARKER_PREFIX "acb_"
#define MARKER_PREFIX_OLD "brf_mk_"
#define MIRROR_SWEEP_INTERVAL 1
#define MIRROR_HEAL_TICKS 10

// 上限（DESIGN.md「性能」）
#define MAX_ELEMENTS 120
#define MAX_LINE_POINTS 200

// 网络节流（秒）
#define VIEW_INTERVAL 0.2
#define PTR_INTERVAL 0.1

// 动画时长（秒），见 DESIGN.md「各元素的动画参数」
#define FADE_OUT_TIME 0.4
#define ARROW_TIME 0.15
#define ICON_DROP_TIME 0.25
#define ICON_BLINK_TIME 1
#define ICON_CHAR_TIME 0.04
#define RING_EXPAND_TIME 0.4
#define RING_PULSE_PERIOD 2
#define AREA_STROKE_TIME 0.6
#define AREA_FILL_TIME 0.4

// 开场动画（只在开始简报时播放），和 intro.ogg 对齐（tools/make_sounds.py 里同名的常量）：
// 0 – 1.5 秒三声拖长的「嘀……」→ 1.55 秒中线从中心拉开 → 上下张开露出地图 → 标题淡入
#define INTRO_BEEP_INTERVAL 0.5
#define INTRO_BEEP_LEN 0.3
#define INTRO_BEEPS 3
#define INTRO_UNFOLD_AT 1.55
#define INTRO_LINE_TIME 0.22
#define INTRO_OPEN_TIME 0.4
#define INTRO_EDGE_FADE 0.6
#define INTRO_TITLE_TIME 0.3

// 结束动画（结束简报时播放），和 outro.ogg 对齐（tools/make_sounds.py 里的 CLOSE_START / CLOSE_AT / TAIL_BEEPS）：
// 标题淡出 → 0.1 – 0.5 秒黑幕从上下合拢 → 亮线收向中心 → DATA LINK TERMINATED + 两声「嘀……」→ 关闭
#define OUTRO_FADE_TIME 0.3
#define OUTRO_CLOSE_START 0.1
#define OUTRO_CLOSE_TIME 0.4
#define OUTRO_LINE_TIME 0.22
#define OUTRO_BEEP_1 0.8
#define OUTRO_BEEP_2 1.3
#define OUTRO_BEEP_LEN 0.3
#define OUTRO_END 1.9

// 固定屏幕尺寸（像素）
#define LINE_WIDTH 3
#define ARROW_PX 14
#define ICON_PX 20
#define HIT_PX 8
#define MIN_STEP_PX 4
#define SIMPLIFY_PX 3

// 预案播放：镜头飞行时间、同一步里元素之间的间隔（秒）
#define PLAN_FLY_TIME 0.8
#define PLAN_ELEMENT_GAP 0.15

// 地图叠加（BRF_fnc_renderOverlay）
#define HOUSE_MAX_MPP 1.6
#define HOUSE_MAX_RADIUS 1500
#define HOUSE_TYPES ["HOUSE", "BUILDING", "CHURCH", "CHAPEL", "FUELSTATION", "HOSPITAL", "BUNKER", "FORTRESS", "VIEW-TOWER", "LIGHTHOUSE", "WATERTOWER", "TRANSMITTER", "RUIN"]
#define SCALE_BAR_PX 150

// 工具序号（数字键 1-6）
#define TOOL_LINE 1
#define TOOL_ICON 2
#define TOOL_RING 3
#define TOOL_AREA 4
#define TOOL_POINTER 5
#define TOOL_ERASER 6

// 音效（playSoundUI 用文件路径时必须带扩展名）
#define SOUND_OPEN "\z\brf\addons\briefing\sounds\open.ogg"
// 开始简报时的开场：5 声「嘀」+ 展开（时间轴和 BRF_fnc_viewerIntro 一致）
#define SOUND_INTRO "\z\brf\addons\briefing\sounds\intro.ogg"
// 结束简报时的结束动画音效（和开场成对）
#define SOUND_OUTRO "\z\brf\addons\briefing\sounds\outro.ogg"
#define SOUND_CLOSE "\z\brf\addons\briefing\sounds\close.ogg"
#define SOUND_DRAW "\z\brf\addons\briefing\sounds\draw_start.ogg"
#define SOUND_PING "\z\brf\addons\briefing\sounds\ping.ogg"
#define SOUND_RING "\z\brf\addons\briefing\sounds\ring.ogg"
// 播放音量：比最初版本低 25%，在背景音乐里能听出来、又不抢音乐（playSoundUI 不受游戏音量滑块影响）
#define SOUND_VOLUME 0.6
// 目标点的「哔」每个图标会响 3 次，再低一点
#define SOUND_VOLUME_PING 0.45

#include "ui_defines.hpp"
