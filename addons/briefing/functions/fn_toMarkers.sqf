#include "..\script_component.hpp"
/*
 * 主持端：把当前元素转成普通的全局地图标记（打的时候按 M 还能看）。
 * 标记名统一用 BRF_mk_ 前缀，每次转换前先清掉上一次的。
 *
 * 为了少发网络包：先用 *Local 命令设好所有属性，最后用一条全局命令（setMarkerAlpha）
 * 把整个标记同步出去。
 *
 * Arguments:
 * 0: 模式 <STRING> "create"（默认）/ "clear"（只清掉 BRF_mk_ 标记）
 *
 * Return Value:
 * 创建的标记数 <NUMBER>
 */

params [["_mode", "create", [""]]];

{
    if (_x select [0, 7] == "BRF_mk_") then {
        deleteMarker _x;
    };
} forEach allMapMarkers;

if (_mode == "clear") exitWith {0};

BRF_markerBatch = (missionNamespace getVariable ["BRF_markerBatch", 0]) + 1;

// b_ 开头的北约兵种标记按颜色换阵营：友军 b_、敌军 o_、注意 / 目标 n_
private _sidePrefix = ["b_", "o_", "n_", "n_"];

private _count = 0;
{
    _x params ["_id", "_type", "_colorIndex", "_data"];
    private _name = format ["BRF_mk_%1_%2", BRF_markerBatch, _id];
    private _color = BRF_markerColors select _colorIndex;

    switch (_type) do {
        case "line";
        case "area": {
            private _pts = +(_data select 0);
            if (_type == "area") then {
                _pts pushBack (_pts select 0); // 闭合：末尾补上第一个点
            };
            // setMarkerPolyline 要的是展平的 [x1, y1, x2, y2, ...]
            private _flat = [];
            {_flat append _x} forEach _pts;

            private _m = createMarker [_name, _pts select 0];
            if (_m == "") exitWith {};
            _m setMarkerShapeLocal "POLYLINE";
            _m setMarkerPolylineLocal _flat;
            _m setMarkerColorLocal _color;
            _m setMarkerAlpha 1;
            _count = _count + 1;

            // 带箭头的线：末端加一个箭头图标
            if (_type == "line" && {_data select 1}) then {
                private _n = count _pts;
                private _b = _pts select (_n - 1);
                private _a = _pts select (_n - 2);
                private _arrow = createMarker [_name + "_arrow", _b];
                if (_arrow == "") exitWith {};
                _arrow setMarkerTypeLocal "mil_arrow2";
                _arrow setMarkerDirLocal (_a getDir _b);
                _arrow setMarkerSizeLocal [0.6, 0.6];
                _arrow setMarkerColorLocal _color;
                _arrow setMarkerAlpha 1;
            };
        };
        case "icon": {
            _data params ["_pos", "_kind", "_label"];
            private _m = createMarker [_name, _pos];
            if (_m == "") exitWith {};
            private _def = BRF_iconDefs getOrDefault [_kind, ["", "", toUpper _kind, "", "mil_dot"]];
            private _type = _def select 4;
            if (_type select [0, 2] == "b_") then {
                _type = (_sidePrefix select _colorIndex) + (_type select [2]);
            };
            if !(isClass (configFile >> "CfgMarkers" >> _type)) then {_type = "mil_dot"};
            _m setMarkerTypeLocal _type;
            _m setMarkerTextLocal ([_label, _def select 2] select (_label == ""));
            _m setMarkerColorLocal _color;
            _m setMarkerAlpha 1;
            _count = _count + 1;
        };
        case "ring": {
            _data params ["_center", "_radius"];
            private _m = createMarker [_name, _center];
            if (_m == "") exitWith {};
            _m setMarkerShapeLocal "ELLIPSE";
            _m setMarkerSizeLocal [_radius, _radius];
            _m setMarkerBrushLocal "Border";
            _m setMarkerColorLocal _color;
            _m setMarkerAlpha 1;
            _count = _count + 1;
        };
    };
} forEach BRF_state;

_count
