#include "..\script_component.hpp"
/*
 * 主持端：把一笔组装成元素并发送。
 * 画线：Douglas-Peucker 简化（容差 = 屏幕 3 像素）→ Chaikin 平滑 2 次 → 超过 200 点就提高容差重来
 *       → 坐标取整到 1 米。按住 Shift 时跳过这些步骤，只保留首尾两点。
 *
 * Arguments:
 * 0: 类型 <STRING> "line" / "icon" / "ring" / "area"
 * 1: 原始数据 <ARRAY>
 *    line: [点(3D), 直线(Shift), 虚线(Alt)]
 *    icon: [位置, 图标种类, 标签]
 *    ring: [圆心, 半径米]
 *    area: [顶点(3D)]
 *
 * Return Value:
 * 发出的元素 id <STRING>，没有发出时为 ""
 */

params [["_type", "", [""]], ["_raw", [], [[]]]];

private _fnc_round = {
    _this apply {[round (_x select 0), round (_x select 1)]}
};
private _fnc_dedupe = {
    // 去掉取整后重复的相邻点
    private _out = [];
    {
        if (_out isEqualTo [] || {_x isNotEqualTo (_out select (count _out - 1))}) then {
            _out pushBack _x;
        };
    } forEach _this;
    _out
};

private _data = [];
switch (_type) do {
    case "line": {
        _raw params ["_pts", ["_straight", false], ["_dashed", false]];
        if (count _pts < 2) exitWith {};

        // 屏幕上太短的一笔（基本就是点了一下）不算
        private _len = 0;
        for "_i" from 1 to (count _pts - 1) do {
            _len = _len + ((_pts select (_i - 1)) distance2D (_pts select _i));
        };
        if (_len / BRF_mpp < 6) exitWith {};

        private _result = [];
        if (_straight) then {
            _result = [_pts select 0, _pts select (count _pts - 1)];
        } else {
            private _eps = SIMPLIFY_PX * BRF_mpp;
            while {true} do {
                _result = [[_pts, _eps] call BRF_fnc_simplify, 2] call BRF_fnc_smooth;
                if (count _result <= MAX_LINE_POINTS) exitWith {};
                _eps = _eps * 1.5;
            };
        };
        _result = (_result call _fnc_round) call _fnc_dedupe;
        if (count _result < 2) exitWith {};
        _data = [_result, BRF_arrow, _dashed, LINE_WIDTH];
    };
    case "icon": {
        _raw params ["_pos", ["_kind", "tgt"], ["_label", ""]];
        _data = [[round (_pos select 0), round (_pos select 1)], _kind, _label];
    };
    case "ring": {
        _raw params ["_center", "_radius"];
        if (_radius < 1) exitWith {};
        _data = [[round (_center select 0), round (_center select 1)], round _radius];
    };
    case "area": {
        _raw params ["_verts"];
        private _result = (_verts call _fnc_round) call _fnc_dedupe;
        if (count _result > 2 && {(_result select 0) isEqualTo (_result select (count _result - 1))}) then {
            _result deleteAt (count _result - 1);
        };
        if (count _result < 3) exitWith {};
        _data = [_result];
    };
};

if (_data isEqualTo []) exitWith {""};

if ({(_x select E_T1) < 0} count BRF_els >= MAX_ELEMENTS) exitWith {
    [format [localize "STR_BRF_MsgTooMany", MAX_ELEMENTS], [1, 0.4, 0.4, 1]] call BRF_fnc_presenterMessage;
    ""
};

// id = clientOwner_序号；带上 clientOwner 是为了换主持人时不撞号
private _id = "";
while {_id == "" || {_id in BRF_elMap}} do {
    BRF_seq = BRF_seq + 1;
    _id = format ["%1_%2", clientOwner, BRF_seq];
};

["add", [_id, _type, BRF_color, _data]] call BRF_fnc_send;
BRF_undoStack pushBack _id;
[] call BRF_fnc_presenterUpdate;

_id
