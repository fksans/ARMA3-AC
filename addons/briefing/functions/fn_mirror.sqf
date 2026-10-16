#include "..\script_component.hpp"
/*
 * 原版标记镜像：每个简报元素同时对应一组全局原版地图标记，名字是 acb_<元素 id>（带箭头的线另有 acb_<id>_arrow）。
 * 没装模组的人（以及简报结束后所有人）按 M 看到的就是这些标记；装了模组的客户端在本机把它们隐藏
 * （setMarkerAlphaLocal 0），改由 BRF_fnc_mapDraw 画原样式。
 * 只动名字以 acb_ 开头的标记（"clearAll" 额外清旧版「转标记」留下的 BRF_mk_*），别的标记一概不碰。
 *
 * 为了少发网络包：createMarker 之后先用 *Local 命令设好所有属性，最后用一条全局命令（setMarkerAlpha）
 * 把整个标记同步出去，然后在本机隐藏。
 *
 * Arguments:
 * 0: 操作 <STRING>
 *    "add" 元素 [id, 类型, 颜色序号, 数据(, 作者)]：创建标记
 *    "del" id：删除这个元素的标记
 *    "clearAll"：删除所有 acb_* 和 BRF_mk_* 标记
 *    "rebuild"：删除所有 acb_* 标记，再按 BRF_state 重建
 *    "heal"：BRF_state 里有、但标记不存在的元素，补建标记（建标记的人掉线等情况）
 *    "hide" id：本机隐藏这个元素的标记
 * 1: 参数
 *
 * Return Value:
 * "add" / "rebuild" / "heal"：创建的标记数；"clearAll"：删除的标记数 <NUMBER>
 */

params [["_mode", "", [""]], "_arg"];

private _fnc_exists = {getMarkerColor _this != ""};
private _fnc_hide = {
    params ["_id"];
    {
        if (_x call _fnc_exists && {markerAlpha _x != 0}) then {
            _x setMarkerAlphaLocal 0;
        };
    } forEach [MARKER_PREFIX + _id, MARKER_PREFIX + _id + "_arrow"];
};

private _fnc_add = {
    params [["_el", [], [[]]]];
    _el params [["_id", "", [""]], ["_type", "", [""]], ["_colorIndex", 0, [0]], ["_data", [], [[]]], ["", ""], ["_destroyed", false, [false]]];
    if (_id == "") exitWith {0};
    private _name = MARKER_PREFIX + _id;
    if (_name call _fnc_exists) exitWith {0};
    _colorIndex = (round _colorIndex) max 0 min (count BRF_markerColors - 1);
    private _color = BRF_markerColors select _colorIndex;
    // 已摧毁：原版标记一律灰色（图标文字后面加「已摧毁」）
    if (_destroyed) then {
        _color = ["ColorBlack", "ColorGrey"] select isClass (configFile >> "CfgMarkerColors" >> "ColorGrey");
    };
    private _made = 0;

    switch (_type) do {
        case "line";
        case "area": {
            private _pts = +(_data param [0, []]);
            if (count _pts < 2) exitWith {};
            if (_type == "area") then {
                _pts pushBack (_pts select 0); // 闭合：末尾补上第一个点
            };
            // setMarkerPolyline 要的是展平的 [x1, y1, x2, y2, ...]（至少 4 个数）
            private _flat = [];
            {_flat append [_x select 0, _x select 1]} forEach _pts;

            private _m = createMarker [_name, _pts select 0];
            if (_m == "") exitWith {};
            _m setMarkerShapeLocal "POLYLINE";
            _m setMarkerPolylineLocal _flat;
            _m setMarkerColorLocal _color;
            _m setMarkerAlpha 1;
            _made = 1;

            // 带箭头的线：末端加一个箭头标记
            if (_type == "line" && {_data param [1, false]}) then {
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
                _made = 2;
            };
        };
        case "icon": {
            _data params [["_pos", [], [[]]], ["_kind", "", [""]], ["_label", "", [""]]];
            if !(_pos isEqualTypeArray [0, 0]) exitWith {};
            // 注册表保证 markerType / markerColor 一定有效（见 CfgIcons.hpp 和 BRF_fnc_init）
            private _def = BRF_iconDefs getOrDefault [_kind, []];
            if (_def isEqualTo []) exitWith {};
            private _markerType = _def select 4;
            // b_ 开头的北约兵种标记按颜色换阵营：友军 b_、敌军 o_、其他颜色 n_
            if (_markerType select [0, 2] == "b_") then {
                private _sided = (["b_", "o_"] param [_colorIndex, "n_"]) + (_markerType select [2]);
                if (isClass (configFile >> "CfgMarkers" >> _sided)) then {_markerType = _sided};
            };
            private _markerColor = _def select 6;
            if (_markerColor == "palette" || _destroyed) then {_markerColor = _color};

            private _m = createMarker [_name, _pos];
            if (_m == "") exitWith {};
            _m setMarkerTypeLocal _markerType;
            // 和模组里显示的一样：有标签用标签，没有用缩写
            private _text = [_label, _def select 2] select (_label == "");
            if (_destroyed) then {_text = format [localize "STR_BRF_MarkerDestroyed", _text]};
            _m setMarkerTextLocal _text;
            _m setMarkerColorLocal _markerColor;
            _m setMarkerAlpha 1;
            _made = 1;
        };
        case "ring": {
            _data params [["_center", [], [[]]], ["_radius", 0, [0]]];
            if (!(_center isEqualTypeArray [0, 0]) || {_radius <= 0}) exitWith {};
            private _m = createMarker [_name, _center];
            if (_m == "") exitWith {};
            _m setMarkerShapeLocal "ELLIPSE";
            _m setMarkerSizeLocal [_radius, _radius];
            _m setMarkerBrushLocal "Border";
            _m setMarkerColorLocal _color;
            _m setMarkerAlpha 1;
            _made = 1;
        };
    };

    // 本机由模组画原样式：已经认识这个元素就立即隐藏
    if (_made > 0 && {_id in BRF_elMap}) then {[_id] call _fnc_hide};
    _made
};

private _fnc_deleteMatching = {
    params ["_prefixes"];
    private _count = 0;
    {
        private _lower = toLower _x;
        if (_prefixes findIf {_lower select [0, count _x] == _x} != -1) then {
            deleteMarker _x;
            _count = _count + 1;
        };
    } forEach allMapMarkers;
    _count
};

switch (_mode) do {
    case "add": {
        [_arg] call _fnc_add
    };
    case "del": {
        if !(_arg isEqualType "") exitWith {0};
        {
            if (_x call _fnc_exists) then {deleteMarker _x};
        } forEach [MARKER_PREFIX + _arg, MARKER_PREFIX + _arg + "_arrow"];
        0
    };
    case "clearAll": {
        [[MARKER_PREFIX, MARKER_PREFIX_OLD]] call _fnc_deleteMatching
    };
    case "rebuild": {
        [[MARKER_PREFIX]] call _fnc_deleteMatching;
        private _count = 0;
        {
            _count = _count + ([_x] call _fnc_add);
        } forEach BRF_state;
        _count
    };
    case "heal": {
        private _count = 0;
        {
            if !((MARKER_PREFIX + (_x select 0)) call _fnc_exists) then {
                _count = _count + ([_x] call _fnc_add);
            };
        } forEach BRF_state;
        _count
    };
    case "hide": {
        if (_arg isEqualType "") then {[_arg] call _fnc_hide};
        0
    };
    default {0};
};
