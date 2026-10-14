#include "..\script_component.hpp"
/*
 * 音乐联动：开始简报时让 Zeus 音乐播放器（Zeus Music Player）全队淡入播放。
 * 只通过播放器的公开函数 zmp_fnc_play 交互，不碰播放器的内部变量。
 * 没加载音乐播放器时什么都不做。
 *
 * Arguments:
 * 0: CfgMusic 类名 <STRING>
 *
 * Return Value:
 * 是否发出 <BOOL>
 */

params [["_class", "", [""]]];

if (_class == "" || {isNil "zmp_fnc_play"}) exitWith {false};

// [类名, 模式, 起始秒, 音量, 淡入秒, 播放对象(全体玩家), 显示名]
[_class, "fadeIn", 0, 1, 3, [["all"], objNull], "BRIEFING"] call zmp_fnc_play;
BRF_bgmPlaying = true;
true
