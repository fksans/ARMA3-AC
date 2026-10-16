#include "..\script_component.hpp"
/*
 * 原版地图（M 地图、GPS 小地图、Zeus 地图、ACE MicroDAGR）上画简报元素的原样式：静态，不播动画、不出声。
 * 对应的 acb_ 原版标记在本机是隐藏的（见 BRF_fnc_mirrorSweep），所以这里画的就是装了模组的人看到的样子。
 * 挂在这些地图控件的 Draw 事件上，见 BRF_fnc_mirrorSweep。
 * 原版地图是白底的：画的时候换成深色调色板（BRF_paletteLight），发光改成深色描边、线条加粗 1 像素，
 * 图标下面垫一层深色底（见 BRF_lightMap 在各绘制函数里的分支）。简报界面的样式不受影响。
 *
 * Arguments:
 * 0: 地图控件 <CONTROL>
 */

params [["_map", controlNull, [controlNull]]];

if (isNull _map || {BRF_els isEqualTo []}) exitWith {};

private _mpp = ((_map ctrlMapScreenToWorld [0.5, 0.5]) distance2D (_map ctrlMapScreenToWorld [0.5 + 100 * pixelW, 0.5])) / 100;
if (_mpp <= 0) exitWith {};

// 渲染函数用的全局量（虚线裁剪范围等）临时换成这张地图的，画完还原，不影响简报界面
private _saved = [BRF_mpp, BRF_viewBox, BRF_palette];
BRF_palette = BRF_paletteLight;
BRF_lightMap = true;
BRF_mpp = _mpp;
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

{
    if ((_x select E_T1) < 0) then {
        // 浅拷贝一份，把开始时间推到很久以前、当前时间固定为 0：所有动画都是「已播完」的静止状态
        private _record = _x select [0, count _x];
        _record set [E_T0, -1e6];
        if ((_record param [E_DESTROYED, -1]) != -1) then {_record set [E_DESTROYED, -1e6]};
        [_map, _record, 1, false, 0, _mpp] call BRF_fnc_renderElement;
    };
} forEach BRF_els;

BRF_mpp = _saved select 0;
BRF_viewBox = _saved select 1;
BRF_palette = _saved select 2;
BRF_lightMap = false;
