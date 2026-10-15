#include "..\script_component.hpp"
/*
 * 画一个元素记录（实时简报的元素和编排模式里预案的元素共用）。
 *
 * Arguments:
 * 0: 地图控件 <CONTROL>
 * 1: 元素记录 <ARRAY> [id, 类型, 颜色序号, 数据, t0, t1, 缓存]
 * 2: 透明度系数 <NUMBER>
 * 3: 是否主持端 <BOOL>（橡皮悬停闪烁只在主持端）
 * 4: 当前时间 <NUMBER>
 * 5: 1 像素 = 多少米 <NUMBER>
 *
 * Return Value:
 * 删除淡出已经结束、可以从表里移除 <BOOL>
 */

params ["_map", "_record", "_alphaMul", "_presenter", "_now", "_mpp"];
_record params ["_id", "_type", "_colorIndex", "_data", "_t0", "_t1", "_cache"];

private _purge = false;
call {
    private _alpha = _alphaMul;
    if (_t1 >= 0) then {
        // 删除：0.4 秒线性淡出，淡完再从表里移除
        private _k = (_now - _t1) / FADE_OUT_TIME;
        if (_k >= 1) then {
            _purge = true;
            _alpha = 0;
        } else {
            _alpha = _alpha * (1 - _k);
        };
    };
    if (_alpha <= 0) exitWith {};

    // 橡皮悬停：闪一闪提示会删掉哪个
    if (_presenter && {_id == BRF_hoverId}) then {
        _alpha = _alpha * (0.35 + 0.3 * sin (_now * 720));
    };

    private _col = +(BRF_palette select _colorIndex);
    _col set [3, (_col select 3) * _alpha];

    switch (_type) do {
        case "line": {
            _data params ["", ["_arrow", false], ["_dashed", false], ["_width", LINE_WIDTH]];
            _cache params ["_pts", "_cum", "_len", "_dur"];

            // 屏幕上越长的线画得越久，但不超过 2 秒。第一次渲染时按当时的缩放算好存起来。
            if (_dur < 0) then {
                _dur = (0.5 + (_len / _mpp) / 1200) min 2;
                _cache set [3, _dur];
            };

            private _f = (((_now - _t0) / _dur) min 1) max 0;
            private _arrowK = 0;
            if (_arrow && {_f >= 1}) then {
                _arrowK = ((((_now - _t0 - _dur) / ARROW_TIME) min 1) max 0) call BRF_fnc_easeOutBack;
            };

            ([_map, _pts, _cum, _len * (_f call BRF_fnc_easeOutCubic), _col, _width, _dashed, _arrowK, _now, _mpp] call BRF_fnc_drawLine) params ["_head"];

            // 线头发光点：只在动画进行中画
            if (_f < 1) then {
                _map drawIcon [BRF_texWhite, _col, _head, 10, 10, 45];
            };
        };
        case "icon": {
            [_map, _data, _cache, _col, _t0, _now, _mpp] call BRF_fnc_renderIcon;
        };
        case "ring": {
            [_map, _data, _cache, _col, _t0, _now, _mpp] call BRF_fnc_renderRing;
        };
        case "area": {
            [_map, _cache, _col, _t0, _now, _mpp] call BRF_fnc_renderArea;
        };
    };
};

_purge
