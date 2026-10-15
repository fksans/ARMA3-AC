#include "..\script_component.hpp"
/*
 * 地图控件 Draw 事件主体，主持端和观看端共用（所以 Zeus 看到的动画和玩家看到的完全一致）。
 * 每帧遍历 BRF_els，按「收到事件的本机时刻」计算每个元素的动画进度。
 *
 * Arguments:
 * 0: 地图控件 <CONTROL>
 * 1: 是否主持端 <BOOL>（主持端额外画正在画的笔画预览）
 */

params ["_map", ["_presenter", false]];

private _now = diag_tickTime;

// 屏幕 1 像素对应多少米：箭头、图标、标签偏移这类「固定屏幕大小」的东西都靠它换算
private _mpp = ((_map ctrlMapScreenToWorld [0.5, 0.5]) distance2D (_map ctrlMapScreenToWorld [0.5 + 100 * pixelW, 0.5])) / 100;
if (_mpp <= 0) exitWith {};
BRF_mpp = _mpp;

// 可见范围（虚线裁剪用），四周多留 20 像素
ctrlPosition _map params ["_cx", "_cy", "_cw", "_ch"];
private _tl = _map ctrlMapScreenToWorld [_cx, _cy];
private _br = _map ctrlMapScreenToWorld [_cx + _cw, _cy + _ch];
private _pad = 20 * _mpp;
BRF_viewBox = [
    ((_tl select 0) min (_br select 0)) - _pad,
    ((_tl select 1) min (_br select 1)) - _pad,
    ((_tl select 0) max (_br select 0)) + _pad,
    ((_tl select 1) max (_br select 1)) + _pad
];

// 整体透明度（目前恒为 1；结束简报时由结束动画的黑幕盖住画面，不再淡出地图内容）
private _globalAlpha = 1;

// 底层：房屋、地名、比例尺（简报元素画在它上面）
[_map, _mpp, _globalAlpha] call BRF_fnc_renderOverlay;

private _purge = false;
{
    _x params ["_id", "_type", "_colorIndex", "_data", "_t0", "_t1", "_cache"];

    private _alpha = _globalAlpha;
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
    if (_alpha <= 0) then {continue};

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
} forEach BRF_els;

if (_purge) then {
    [] call BRF_fnc_purge;
};

// ---- 激光笔：显示位置每帧向目标移动差距的 30% ----
if (BRF_ptrTarget isNotEqualTo []) then {
    if (BRF_ptrPos isEqualTo []) then {
        BRF_ptrPos = +BRF_ptrTarget;
    } else {
        BRF_ptrPos = BRF_ptrPos vectorAdd ((BRF_ptrTarget vectorDiff BRF_ptrPos) vectorMultiply 0.3);
    };
    _map drawIcon [BRF_texDot, [1, 0.15, 0.1, 0.3 * _globalAlpha], BRF_ptrPos, 40, 40, 0];
    _map drawIcon [BRF_texDot, [1, 0.25, 0.2, _globalAlpha], BRF_ptrPos, 16, 16, 0];
} else {
    BRF_ptrPos = [];
};

// ---- 主持端：正在画的东西 ----
if (_presenter) then {
    [_map, _now, _mpp] call BRF_fnc_renderPreview;
};
