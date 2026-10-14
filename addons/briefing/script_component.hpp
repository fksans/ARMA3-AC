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

// 上限（DESIGN.md「性能」）
#define MAX_ELEMENTS 60
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
#define VIEWER_FADE_TIME 1

// 固定屏幕尺寸（像素）
#define LINE_WIDTH 3
#define ARROW_PX 14
#define ICON_PX 20
#define HIT_PX 8
#define MIN_STEP_PX 4
#define SIMPLIFY_PX 3

// 工具序号（数字键 1-6）
#define TOOL_LINE 1
#define TOOL_ICON 2
#define TOOL_RING 3
#define TOOL_AREA 4
#define TOOL_POINTER 5
#define TOOL_ERASER 6

// 音效（playSoundUI 用文件路径时必须带扩展名）
#define SOUND_OPEN "\z\brf\addons\briefing\sounds\open.ogg"
#define SOUND_CLOSE "\z\brf\addons\briefing\sounds\close.ogg"
#define SOUND_DRAW "\z\brf\addons\briefing\sounds\draw_start.ogg"
#define SOUND_PING "\z\brf\addons\briefing\sounds\ping.ogg"
#define SOUND_RING "\z\brf\addons\briefing\sounds\ring.ogg"

#include "ui_defines.hpp"
