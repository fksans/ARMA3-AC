#include "..\script_component.hpp"
/*
 * 主持端：画正在画、还没提交的东西（只有 Zeus 自己看得到）。
 * 画线时用细线、半透明实时显示原始轨迹；松开后原始轨迹消失，换成修好的线播放动画。
 *
 * Arguments:
 * 0: 地图控件 <CONTROL>
 * 1: 当前时间 <NUMBER>
 * 2: 1 像素 = 多少米 <NUMBER>
 */

params ["_map", "_now", "_mpp"];

private _col = +(BRF_palette select BRF_color);
private _faint = +_col;
_faint set [3, 0.5];

// Ctrl + 拖拽：不管当前工具，按航线预览（见 BRF_fnc_input）
switch ([BRF_tool, TOOL_LINE] select BRF_ctrlLine) do {
    case TOOL_LINE: {
        if (!BRF_drawing || {count BRF_pts == 0}) exitWith {};
        private _cursor = BRF_cursor;
        if (_cursor isEqualTo []) then {
            _cursor = BRF_pts select (count BRF_pts - 1);
        };
        private _path = BRF_pts;
        if (BRF_modShift) then {
            // Shift：松开时只保留首尾，预览也画成直线
            _path = [BRF_pts select 0, _cursor];
        };
        if (!BRF_modAlt) then {
            for "_i" from 1 to (count _path - 1) do {
                _map drawLine [_path select (_i - 1), _path select _i, _faint, 2];
            };
        } else {
            // Alt：虚线（画 10 像素、空 6 像素）
            private _dash = 10 * _mpp;
            private _gap = 6 * _mpp;
            private _period = _dash + _gap;
            private _acc = 0;
            for "_i" from 1 to (count _path - 1) do {
                private _a = _path select (_i - 1);
                private _b = _path select _i;
                private _segLen = _a distance2D _b;
                if (_segLen > 0) then {
                    private _dir = (_b vectorDiff _a) vectorMultiply (1 / _segLen);
                    private _t = 0;
                    private _phase = 0;
                    private _len = 0;
                    private _p = [];
                    private _q = [];
                    while {_t < _segLen} do {
                        _phase = (_acc + _t) mod _period;
                        if (_phase < _dash) then {
                            // 画这一段虚线
                            _len = (_dash - _phase) min (_segLen - _t);
                            _p = _a vectorAdd (_dir vectorMultiply _t);
                            _q = _a vectorAdd (_dir vectorMultiply (_t + _len));
                            _map drawLine [_p, _q, _faint, 2];
                            _t = _t + _len;
                        } else {
                            // 跳过空隙
                            _t = _t + ((_period - _phase) min (_segLen - _t));
                        };
                    };
                };
                _acc = _acc + _segLen;
            };
        };
    };
    case TOOL_RING: {
        if (!BRF_drawing || {BRF_ringRadius <= 0}) exitWith {};
        _map drawEllipse [BRF_ringCenter, BRF_ringRadius, BRF_ringRadius, 0, _faint, ""];
        _map drawLine [BRF_ringCenter, BRF_cursor, _faint, 2];
        // 实时显示米数
        _map drawIcon [BRF_texClear, _col, BRF_cursor vectorAdd [12 * _mpp, 0, 0], 1, 1, 0, format ["%1 m", round BRF_ringRadius], 2, 0.04, "PuristaMedium", "right"];
    };
    case TOOL_AREA: {
        if (BRF_areaPts isEqualTo []) exitWith {};
        for "_i" from 1 to (count BRF_areaPts - 1) do {
            _map drawLine [BRF_areaPts select (_i - 1), BRF_areaPts select _i, _faint, 2];
        };
        private _last = BRF_areaPts select (count BRF_areaPts - 1);
        if (BRF_cursor isNotEqualTo []) then {
            _map drawLine [_last, BRF_cursor, _faint, 1];
            // 闭合线
            if (count BRF_areaPts >= 2) then {
                private _dim = +_col;
                _dim set [3, 0.25];
                _map drawLine [BRF_cursor, BRF_areaPts select 0, _dim, 1];
            };
        };
        {
            _map drawIcon [BRF_texWhite, _col, _x, 6, 6, 45];
        } forEach BRF_areaPts;
    };
};

// 放点后等待输入标签：先在原地显示半透明的当前图标（静态，t0 设成很久以前，不播动画、不出声）
if (BRF_iconPending isNotEqualTo []) then {
    private _kind = BRF_iconKinds select (BRF_iconKind min (count BRF_iconKinds - 1));
    [_map, [BRF_iconPending, _kind, ""], [BRF_iconPending, [], 99], _faint, -1e6, _now, _mpp] call BRF_fnc_renderIcon;
};
