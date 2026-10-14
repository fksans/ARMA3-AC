#include "..\script_component.hpp"
/*
 * 音乐联动：结束简报时淡出由简报启动的音乐（通过 zmp_fnc_stop）。
 *
 * Return Value:
 * 是否发出 <BOOL>
 */

if (!BRF_bgmPlaying || {isNil "zmp_fnc_stop"}) exitWith {false};

// [模式, 淡出秒, 停止后复位的音量]
["fadeOut", 3, 1] call zmp_fnc_stop;
BRF_bgmPlaying = false;
true
