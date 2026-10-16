#include "..\script_component.hpp"
/*
 * 画图标元素：落下（3 倍缩到 1 倍）→ 闪烁 3 次（每次「滴」一声）→ 标签逐字打出 → 外圈角括号缓慢呼吸。
 * 程序图形（基础 4 种和通用标记）按形状表 BRF_shapeDefs 用程序纹理和 drawLine 画；图标库里的用 ui\icons 里的白色贴图，
 * 按元素颜色着色。drawIcon 的尺寸不随地图缩放变化。
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
        playSoundUI [(BRF_iconDefs getOrDefault [_kind, []]) param [8, SOUND_PING], SOUND_VOLUME_PING];
    };
};

// 图形（像素偏移，y 向上）
private _h = _s / 2;
(BRF_iconDefs getOrDefault [_kind, []]) params ["", "", "", ["_texture", ""], "", "", "", ["_shape", "diamond"]];
if (_texture != "") then {
    if (BRF_lightMap) then {
        // 原版白底地图：先用深色在上下左右各偏 1.5 像素画 4 遍，形成描边
        private _outline = [0, 0, 0, 0.6 * (_c select 3)];
        private _o = 1.5 * _mpp;
        {
            _map drawIcon [_texture, _outline, _pos vectorAdd _x, _s * 1.4, _s * 1.4, 0];
        } forEach [[_o, 0, 0], [-_o, 0, 0], [0, _o, 0], [0, -_o, 0]];
    };
    _map drawIcon [_texture, _c, _pos, _s * 1.4, _s * 1.4, 0];
} else {
    // 程序图形：形状表 BRF_shapeDefs（CfgShapes.hpp），单位是半边长 _h
    // 线段带发光（原版白底地图上是深色描边，见 BRF_fnc_drawPath）；实心块是旋转的方块，白底地图上先垫一个大一圈的深色块当描边
    (BRF_shapeDefs getOrDefault [_shape, [[], []]]) params ["_lines", "_fills"];
    {
        _x params ["_closed", "_pts"];
        [_map, _pos, _pts apply {[(_x select 0) * _h, (_x select 1) * _h]}, _closed, _c, 2, _mpp, true] call BRF_fnc_drawPath;
    } forEach _lines;
    {
        _x params ["_fx", "_fy", "_size", "_angle"];
        private _at = _pos vectorAdd [_fx * _h * _mpp, _fy * _h * _mpp, 0];
        if (BRF_lightMap) then {
            _map drawIcon [BRF_texWhite, [0, 0, 0, 0.6 * (_c select 3)], _at, _size * _h + 4, _size * _h + 4, _angle];
        };
        _map drawIcon [BRF_texWhite, _c, _at, _size * _h, _size * _h, _angle];
    } forEach _fills;
};

if (_age < ICON_DROP_TIME) exitWith {};

// 常驻：外圈 4 个角括号缓慢呼吸（透明度 0.5 到 1，周期 2 秒；纯文字图标没有）
private _r = ICON_PX * 0.95;
if (_shape != "none") then {
    private _b = +_col;
    _b set [3, (_col select 3) * (0.75 + 0.25 * sin (_age * 180))];
    private _k = ICON_PX * 0.35;
    {
        _x params ["_sx", "_sy"];
        [_map, _pos, [[_sx * (_r - _k), _sy * _r], [_sx * _r, _sy * _r], [_sx * _r, _sy * (_r - _k)]], false, _b, 2, _mpp] call BRF_fnc_drawPath;
    } forEach [[1, 1], [1, -1], [-1, -1], [-1, 1]];
};

// 标签打字：每字 0.04 秒
private _count = floor (_blinkAge / ICON_CHAR_TIME);
if (_count <= 0) exitWith {};
private _text = toString (_chars select [0, _count min count _chars]);
private _textPos = [_pos vectorAdd [(_r + 4) * _mpp, 0, 0], _pos] select (_shape == "none");
_map drawIcon [BRF_texClear, _col, _textPos, 1, 1, 0, _text, 2, 0.045, "PuristaMedium", ["right", "center"] select (_shape == "none")];
