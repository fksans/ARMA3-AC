#include "..\script_component.hpp"
/*
 * 画图标元素：落下（3 倍缩到 1 倍）→ 闪烁 3 次（每次「滴」一声）→ 标签逐字打出 → 外圈角括号缓慢呼吸。
 * 全部用程序纹理和 drawLine 画，不需要贴图；drawIcon 的尺寸不随地图缩放变化。
 *
 * Arguments:
 * 0: 地图控件 <CONTROL>
 * 1: 数据 <ARRAY> [位置, 图标种类, 标签]
 * 2: 缓存 <ARRAY> [位置(3D), 标签字符码, 已播放的闪烁次数]
 * 3: 颜色 <ARRAY>
 * 4: t0 <NUMBER>
 * 5: 当前时间 <NUMBER>
 * 6: 1 像素 = 多少米 <NUMBER>
 */

params ["_map", "_data", "_cache", "_col", "_t0", "_now", "_mpp"];
_data params ["", ["_kind", "tgt"]];
_cache params ["_pos", "_chars", "_blinks"];

private _age = _now - _t0;

// 落下：尺寸从 3 倍缩到 1 倍
private _drop = ((_age / ICON_DROP_TIME) min 1) max 0;
private _s = ICON_PX * (3 - 2 * (_drop call BRF_fnc_easeOutBack));

// 闪烁：1 秒内透明度在 1 和 0.2 之间切换 3 次
private _c = +_col;
private _blinkAge = _age - ICON_DROP_TIME;
if (_blinkAge >= 0 && {_blinkAge < ICON_BLINK_TIME}) then {
    private _phase = floor (_blinkAge * 6 / ICON_BLINK_TIME);
    if (_phase mod 2 == 0) then {
        _c set [3, (_c select 3) * 0.2];
    };
    // 每次闪烁「滴」一声
    private _n = floor (_phase / 2);
    if (_n > _blinks) then {
        _cache set [2, _n];
        playSoundUI [SOUND_PING, 0.6];
    };
};

// 图形（像素偏移，y 向上）
private _h = _s / 2;
switch (_kind) do {
    case "lz": {
        // 空心方框 + 中心点
        [_map, _pos, [[-_h, -_h], [_h, -_h], [_h, _h], [-_h, _h]], true, _c, 2, _mpp, true] call BRF_fnc_drawPath;
        _map drawIcon [BRF_texWhite, _c, _pos, _s * 0.25, _s * 0.25, 0];
    };
    case "ip": {
        // 空心三角
        [_map, _pos, [[0, _h], [_h * 0.9, -_h * 0.6], [-_h * 0.9, -_h * 0.6]], true, _c, 2, _mpp, true] call BRF_fnc_drawPath;
    };
    case "wp": {
        // 空心菱形 + 中心点
        [_map, _pos, [[0, _h], [_h, 0], [0, -_h], [-_h, 0]], true, _c, 2, _mpp, true] call BRF_fnc_drawPath;
        _map drawIcon [BRF_texWhite, _c, _pos, _s * 0.2, _s * 0.2, 45];
    };
    default {
        // tgt：实心菱形
        _map drawIcon [BRF_texWhite, _c, _pos, _s * 0.7, _s * 0.7, 45];
    };
};

if (_age < ICON_DROP_TIME) exitWith {};

// 常驻：外圈 4 个角括号缓慢呼吸（透明度 0.5 到 1，周期 2 秒）
private _b = +_col;
_b set [3, (_col select 3) * (0.75 + 0.25 * sin (_age * 180))];
private _r = ICON_PX * 0.95;
private _k = ICON_PX * 0.35;
{
    _x params ["_sx", "_sy"];
    [_map, _pos, [[_sx * (_r - _k), _sy * _r], [_sx * _r, _sy * _r], [_sx * _r, _sy * (_r - _k)]], false, _b, 2, _mpp] call BRF_fnc_drawPath;
} forEach [[1, 1], [1, -1], [-1, -1], [-1, 1]];

// 标签打字：每字 0.04 秒
private _count = floor (_blinkAge / ICON_CHAR_TIME);
if (_count <= 0) exitWith {};
private _text = toString (_chars select [0, _count min count _chars]);
private _textPos = _pos vectorAdd [(_r + 4) * _mpp, 0, 0];
_map drawIcon [BRF_texClear, _col, _textPos, 1, 1, 0, _text, 2, 0.045, "PuristaMedium", "right"];
