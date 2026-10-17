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
    if ([_map, _x, _globalAlpha, _presenter, _now, _mpp] call BRF_fnc_renderElement) then {
        _purge = true;
    };
} forEach BRF_els;

// ---- 主持端编排模式：预案里的元素（只有主持人自己看得到）----
// 当前编辑的步亮显，前面的步淡淡显示，方便对位置；后面的步不画
// 动作（后面的步摧毁 / 移除前面的元素）：前面步的动作直接按结果画（摧毁 = 灰色 + 叉，移除 = 不画）；
// 当前步的动作目标画得亮一些（摧毁 = 灰色 + 叉，移除 = 很淡），方便看出这一步会动哪些元素
if (_presenter && {BRF_planEdit}) then {
    private _done = createHashMap;     // 前面步的动作：planId -> kind
    private _current = createHashMap;  // 当前步的动作
    {
        private _target = [_done, _current] select (_forEachIndex == BRF_planEditStep);
        {_target set [_x select 1, _x select 0]} forEach (_x param [3, []]);
        if (_forEachIndex >= BRF_planEditStep) then {break};
    } forEach BRF_plan;
    {
        private _stepIndex = _forEachIndex;
        private _base = [0.22, 0.8] select (_stepIndex == BRF_planEditStep);
        {
            private _record = _x;
            private _kind = _current getOrDefault [_x select E_ID, ""];
            private _alpha = _base;
            if (_kind != "") then {
                _alpha = [0.25, 0.8] select (_kind == "destroy");
            } else {
                _kind = _done getOrDefault [_x select E_ID, ""];
                if (_kind == "remove") then {continue}; // 前面的步已经移除了
            };
            if (_kind == "destroy") then {
                // 浅拷贝，标成「已经摧毁」的静止样子
                _record = _x select [0, count _x];
                _record resize (E_DESTROYED + 1);
                _record set [E_DESTROYED, -1e6];
            };
            [_map, _record, _alpha, true, _now, _mpp] call BRF_fnc_renderElement;
        } forEach (_x select 0);
        if (_stepIndex >= BRF_planEditStep) then {break};
    } forEach BRF_plan;
};

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
