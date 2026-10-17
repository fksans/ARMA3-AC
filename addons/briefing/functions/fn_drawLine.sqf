#include "..\script_component.hpp"
/*
 * 画一条带发光的粗线，只画到 _target（沿线的长度）为止，可选虚线和末端箭头。
 * 发光 = 同一条路径先用 3 倍宽、低透明度画一遍，再画本体。
 *
 * Arguments:
 * 0: 地图控件 <CONTROL>
 * 1: 点 <ARRAY> [[x, y, 0], ...]
 * 2: 累计长度 <ARRAY>（_cum select 0 为 0）
 * 3: 画到多长（米） <NUMBER>
 * 4: 颜色 <ARRAY> RGBA
 * 5: 线宽 <NUMBER>
 * 6: 虚线 <BOOL>（「画 10 像素、空 6 像素」，起点随时间流动）
 * 7: 箭头弹出进度 <NUMBER>（0 = 不画箭头，1 = 14 像素）
 * 8: 当前时间 <NUMBER>
 * 9: 1 像素 = 多少米 <NUMBER>
 *
 * Return Value:
 * [线头位置, 线头处的方向（单位向量）] <ARRAY>
 */

params ["_map", "_pts", "_cum", "_target", "_col", "_w", "_dashed", "_arrowK", "_now", "_mpp"];

private _glow = +_col;
_glow set [3, 0.25 * (_col select 3)];
private _gw = _w * 3;
if (BRF_lightMap) then {
    // 原版白底地图：发光看不见，改成深色描边，线条加粗一点
    _w = _w + 1;
    _glow = [0, 0, 0, 0.6 * (_col select 3)];
    _gw = _w + 3;
};

private _head = _pts select 0;
private _dir = [0, 1, 0];

// 虚线参数（米）。起点偏移量随时间增加，形成流动的「行军蚂蚁」效果。
private _period = 16 * _mpp;
private _dash = 10 * _mpp;
private _phase = ((_now * 24) mod 16) * _mpp;
BRF_viewBox params ["_minX", "_minY", "_maxX", "_maxY"];

for "_i" from 1 to (count _pts - 1) do {
    private _s0 = _cum select (_i - 1);
    if (_s0 >= _target) exitWith {};

    private _a = _pts select (_i - 1);
    private _b = _pts select _i;
    private _segLen = ((_cum select _i) - _s0) max 0.001;
    _dir = (_b vectorDiff _a) vectorMultiply (1 / _segLen);

    // 最后一段：按比例截断
    if ((_cum select _i) > _target) then {
        _b = _a vectorAdd (_dir vectorMultiply (_target - _s0));
    };
    _head = _b;

    if (!_dashed) then {
        _map drawLine [_a, _b, _glow, _gw];
        _map drawLine [_a, _b, _col, _w];
        continue;
    };

    // 虚线：只在可见范围内切段（Liang-Barsky 裁剪），放大很多时也不会画几千段
    private _len = _a distance2D _b;
    private _u0 = 0;
    private _u1 = 1;
    private _dx = (_b select 0) - (_a select 0);
    private _dy = (_b select 1) - (_a select 1);
    {
        _x params ["_pp", "_qq"];
        if (_pp == 0) then {
            if (_qq < 0) then {_u0 = 2};
        } else {
            private _r = _qq / _pp;
            if (_pp < 0) then {_u0 = _u0 max _r} else {_u1 = _u1 min _r};
        };
    } forEach [
        [-_dx, (_a select 0) - _minX],
        [_dx, _maxX - (_a select 0)],
        [-_dy, (_a select 1) - _minY],
        [_dy, _maxY - (_a select 1)]
    ];
    if (_u0 >= _u1) then {continue};

    private _from = _s0 + _u0 * _len;
    private _to = _s0 + _u1 * _len;
    private _ds = (floor ((_from - _phase) / _period)) * _period + _phase;
    while {_ds < _to} do {
        private _p0 = _ds max _from;
        private _p1 = (_ds + _dash) min _to;
        if (_p1 > _p0) then {
            private _q0 = _a vectorAdd (_dir vectorMultiply (_p0 - _s0));
            private _q1 = _a vectorAdd (_dir vectorMultiply (_p1 - _s0));
            _map drawLine [_q0, _q1, _glow, _gw];
            _map drawLine [_q0, _q1, _col, _w];
        };
        _ds = _ds + _period;
    };
};

// 箭头：末段方向转 ±150° 的两条短线，长度按像素换算，任何缩放下都是固定的 14 像素
if (_arrowK > 0) then {
    private _l = ARROW_PX * _arrowK * _mpp;
    _dir params ["_vx", "_vy"];
    {
        private _c = cos _x;
        private _s = sin _x;
        private _tip = _head vectorAdd [(_vx * _c - _vy * _s) * _l, (_vx * _s + _vy * _c) * _l, 0];
        _map drawLine [_head, _tip, _glow, _gw];
        _map drawLine [_head, _tip, _col, _w];
    } forEach [150, -150];
};

[_head, _dir]
