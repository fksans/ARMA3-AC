#include "..\script_component.hpp"
/*
 * 主持端：按当前工具处理鼠标按下、移动、松开、双击和键盘。
 *
 * Arguments:
 * 0: 事件 <STRING> "down" / "move" / "up" / "dbl" / "key" / "keyUp"
 * 1: 事件参数 <ARRAY>（就是对应事件处理器的 _this）
 *
 * Return Value:
 * "key" 时：是否已处理（true 会挡住默认行为） <BOOL>
 */

params ["_event", "_args"];

private _display = uiNamespace getVariable ["BRF_presenter", displayNull];
if (isNull _display) exitWith {false};
private _map = _display displayCtrl IDC_BRF_MAP;

// 别的 Zeus 正在主持：遮罩期间不处理输入（Esc 照常关闭界面）
if (BRF_locked) exitWith {
    if (_event == "key" && {(_args select 1) == 0x01}) then {
        _display closeDisplay 2;
        true
    } else {
        false
    };
};

// 指挥官标注：橡皮只能擦自己画的
private _commander = BRF_role == "commander";
private _erasable = if (_commander) then {
    private _uid = getPlayerUID player;
    BRF_els select {(_x param [E_AUTHOR, ""]) == _uid}
} else {
    BRF_els
};

// 编排模式：当前步之前所有步的元素记录（后面的步可以摧毁 / 移除它们，见 BRF_fnc_plan 的 "toggleAction"）
private _fnc_planEarlier = {
    private _out = [];
    for "_i" from 0 to (BRF_planEditStep - 1) do {
        _out append ((BRF_plan select _i) select 0);
    };
    _out
};
// 编排模式：先找当前步的元素，没有再找前面步的
private _fnc_planHit = {
    params ["_mx", "_my"];
    private _id = [_map, _mx, _my, (BRF_plan select BRF_planEditStep) select 0] call BRF_fnc_hitTest;
    if (_id == "") then {
        _id = [_map, _mx, _my, call _fnc_planEarlier] call BRF_fnc_hitTest;
    };
    _id
};

private _fnc_world = {
    params ["_mx", "_my"];
    (_map ctrlMapScreenToWorld [_mx, _my]) + [0]
};

private _fnc_cancel = {
    // 取消正在进行的操作
    BRF_drawing = false;
    BRF_ctrlLine = false;
    BRF_pts = [];
    BRF_ringRadius = 0;
    BRF_areaPts = [];
    BRF_rulerA = [];
    BRF_rulerB = [];
    if (BRF_iconPending isNotEqualTo []) then {
        BRF_iconPending = [];
        (_display displayCtrl IDC_BRF_P_LABEL) ctrlShow false;
        (_display displayCtrl IDC_BRF_P_LABEL_ICON) ctrlShow false;
        ctrlSetFocus _map;
    };
    ["set", []] call BRF_fnc_pointer;
};

private _fnc_confirmLabel = {
    private _ctrl = _display displayCtrl IDC_BRF_P_LABEL;
    private _label = trim ctrlText _ctrl;
    ["icon", [BRF_iconPending, BRF_iconKinds select BRF_iconKind, _label]] call BRF_fnc_commit;
    BRF_iconPending = [];
    _ctrl ctrlShow false;
    (_display displayCtrl IDC_BRF_P_LABEL_ICON) ctrlShow false;
    ctrlSetFocus _map;
};

private _fnc_askLabel = {
    // 放点：弹出输入框填标签，回车确认；Tab 切换图标种类。输入框左边是当前图标的缩略图
    params ["_p", "_mx", "_my"];
    BRF_iconPending = _p;
    private _ctrl = _display displayCtrl IDC_BRF_P_LABEL;
    private _icon = _display displayCtrl IDC_BRF_P_LABEL_ICON;
    (ctrlPosition _ctrl) params ["", "", "_w", "_h"];
    (ctrlPosition _icon) params ["", "", "_iw"];
    private _x0 = (_mx + 0.015) min (safeZoneX + safeZoneW - _w - _iw - 0.004);
    private _y0 = (_my - _h / 2) max safeZoneY;
    _icon ctrlSetPosition [_x0, _y0, _iw, _h];
    _icon ctrlCommit 0;
    _ctrl ctrlSetPosition [_x0 + _iw + 0.004, _y0, _w, _h];
    _ctrl ctrlCommit 0;
    _ctrl ctrlSetText "";
    _ctrl ctrlShow true;
    _icon ctrlShow true;
    ctrlSetFocus _ctrl;
    [] call BRF_fnc_presenterUpdate;
};

private _fnc_finishArea = {
    if (count BRF_areaPts >= 3) then {
        ["area", [BRF_areaPts]] call BRF_fnc_commit;
        BRF_areaPts = [];
    } else {
        [localize "STR_BRF_MsgAreaPoints", [1, 0.85, 0.4, 1]] call BRF_fnc_presenterMessage;
    };
};

private _return = false;
switch (_event) do {
    case "down": {
        _args params ["", "_btn", "_mx", "_my", ["_shift", false], ["_ctrl", false], ["_alt", false]];
        if (_btn != 0) exitWith {};

        // 标签还没确认就点了别处：按当前输入确认
        if (BRF_iconPending isNotEqualTo []) exitWith {
            // 双击的第二下落在刚放的点附近：不当成「点了别处」，留着输入框
            private _near = (([_mx, _my] call _fnc_world) distance2D BRF_iconPending) < HIT_PX * BRF_mpp;
            if (!_near) then {call _fnc_confirmLabel};
        };

        BRF_ctrlLine = _ctrl;
        private _tool = [BRF_tool, TOOL_LINE] select BRF_ctrlLine;
        private _p = [_mx, _my] call _fnc_world;
        switch (_tool) do {
            case TOOL_LINE: {
                BRF_drawing = true;
                BRF_pts = [_p];
            };
            case TOOL_ICON: {
                [_p, _mx, _my] call _fnc_askLabel;
            };
            case TOOL_RING: {
                BRF_drawing = true;
                BRF_ringCenter = _p;
                BRF_ringRadius = 0;
                BRF_cursor = _p;
            };
            case TOOL_AREA: {
                if (BRF_areaPts isEqualTo [] || {(_p distance2D (BRF_areaPts select (count BRF_areaPts - 1))) > MIN_STEP_PX * BRF_mpp}) then {
                    BRF_areaPts pushBack _p;
                };
            };
            case TOOL_POINTER: {
                BRF_drawing = true;
                ["set", _p] call BRF_fnc_pointer;
            };
            case TOOL_RULER: {
                // 按下定起点，拖动看距离和方位；松开后结果留着，下次测量或 Esc 清掉
                BRF_drawing = true;
                BRF_rulerA = _p;
                BRF_rulerB = _p;
            };
            case TOOL_ERASER: {
                if (BRF_planEdit) exitWith {
                    // 当前步的元素：直接擦掉；前面步的元素：本步加 / 取消「移除它」
                    private _id = [_map, _mx, _my, (BRF_plan select BRF_planEditStep) select 0] call BRF_fnc_hitTest;
                    if (_id != "") exitWith {["erase", _id] call BRF_fnc_plan};
                    _id = [_map, _mx, _my, call _fnc_planEarlier] call BRF_fnc_hitTest;
                    if (_id != "") then {["toggleAction", "remove", _id] call BRF_fnc_plan};
                };
                private _id = [_map, _mx, _my, _erasable] call BRF_fnc_hitTest;
                if (_id != "") then {
                    ["del", _id] call BRF_fnc_send;
                    [] call BRF_fnc_presenterUpdate;
                };
            };
        };
    };

    case "move": {
        _args params ["", "_mx", "_my"];
        private _p = [_mx, _my] call _fnc_world;
        BRF_cursor = _p;

        private _tool = [BRF_tool, TOOL_LINE] select BRF_ctrlLine;
        switch (_tool) do {
            case TOOL_LINE: {
                if (!BRF_drawing) exitWith {};
                // 每次缩放后屏幕 4 像素对应的米数都不同，BRF_mpp 每帧更新
                private _last = BRF_pts select (count BRF_pts - 1);
                if ((_p distance2D _last) > MIN_STEP_PX * BRF_mpp && {count BRF_pts < 5000}) then {
                    BRF_pts pushBack _p;
                };
            };
            case TOOL_RING: {
                if (!BRF_drawing) exitWith {};
                BRF_ringRadius = BRF_ringCenter distance2D _p;
            };
            case TOOL_POINTER: {
                if (!BRF_drawing) exitWith {};
                ["set", _p] call BRF_fnc_pointer;
            };
            case TOOL_RULER: {
                if (!BRF_drawing) exitWith {};
                BRF_rulerB = _p;
            };
            case TOOL_ERASER: {
                BRF_hoverId = if (BRF_planEdit) then {
                    [_mx, _my] call _fnc_planHit
                } else {
                    [_map, _mx, _my, _erasable] call BRF_fnc_hitTest
                };
            };
        };
    };

    case "up": {
        _args params ["", "_btn", "_mx", "_my", ["_shift", false], ["_ctrl", false], ["_alt", false]];
        if (_btn != 0) exitWith {};
        if (!BRF_drawing) exitWith {BRF_ctrlLine = false};
        BRF_drawing = false;
        // 界面上补挂的松开事件不带修饰键，用键盘事件记下的状态兜底
        _shift = _shift || BRF_modShift;
        _alt = _alt || BRF_modAlt;

        private _tool = [BRF_tool, TOOL_LINE] select BRF_ctrlLine;
        switch (_tool) do {
            case TOOL_LINE: {
                private _pts = BRF_pts;
                BRF_pts = [];
                private _p = [_mx, _my] call _fnc_world;
                if ((_p distance2D (_pts select (count _pts - 1))) > 0) then {
                    _pts pushBack _p;
                };
                // Shift：只保留首尾成直线；Alt：提交为虚线
                ["line", [_pts, _shift, _alt]] call BRF_fnc_commit;
            };
            case TOOL_RING: {
                if (BRF_ringRadius / BRF_mpp >= 5) then {
                    ["ring", [BRF_ringCenter, BRF_ringRadius]] call BRF_fnc_commit;
                };
                BRF_ringRadius = 0;
            };
            case TOOL_POINTER: {
                ["set", []] call BRF_fnc_pointer;
            };
        };
        BRF_ctrlLine = false;
    };

    case "dbl": {
        _args params ["", "_btn", "_mx", "_my"];
        if (_btn != 0) exitWith {};
        switch (true) do {
            // 区域工具：双击闭合区域（双击的第二下已经在 down 里去重了）
            case (BRF_tool == TOOL_AREA && {!BRF_ctrlLine}): {call _fnc_finishArea};
            // 橡皮：不放标记（第一下可能已经删了东西）
            case (BRF_tool == TOOL_ERASER): {};
            // 已经在输入标签（目标点工具单击时就弹出了）：什么都不做
            case (BRF_iconPending isNotEqualTo []): {};
            default {
                // 其他工具：和原版地图一样，双击放标记（当前图标种类），弹出标签输入框
                call _fnc_cancel;
                [[_mx, _my] call _fnc_world, _mx, _my] call _fnc_askLabel;
            };
        };
    };

    case "keyUp": {
        _args params ["", "_key"];
        if (_key in [0x2A, 0x36]) then {BRF_modShift = false}; // Shift
        if (_key in [0x38, 0xB8]) then {BRF_modAlt = false};   // Alt
    };

    case "key": {
        _args params ["", "_key", "_shift", "_ctrl", "_alt"];
        if (_key in [0x2A, 0x36]) then {BRF_modShift = true};
        if (_key in [0x38, 0xB8]) then {BRF_modAlt = true};

        // 同一个按键在控件和界面上各触发一次时只处理一次
        private _stamp = [diag_frameNo, _key];
        if (_stamp isEqualTo BRF_lastKey) exitWith {
            _return = BRF_lastKeyResult;
        };
        BRF_lastKey = _stamp;

        private _handled = true;

        // 正在输入标签：只处理回车 / Esc / Tab，其他键留给输入框
        if (BRF_iconPending isNotEqualTo []) then {
            switch (_key) do {
                case 0x1C;
                case 0x9C: {call _fnc_confirmLabel};                    // Enter
                case 0x01: {call _fnc_cancel};                          // Esc
                case 0x0F: {["iconKind"] call BRF_fnc_presenterAction}; // Tab
                default {_handled = false};
            };
        } else {
            switch (true) do {
                // 指挥官标注：Space 跟随 / 自由；主持人专用的键（激光笔、F、预案、清屏）不响应
                case (_commander && {_key == 0x39}): {["follow"] call BRF_fnc_presenterAction};
                case (_commander && {_key in [0x06, 0x21, 0x19, 0xCD, 0xD1, 0x1B, 0xCB, 0xC9, 0x1A, 0xC7] || {_key == 0xD3 && {_ctrl && _shift}}}): {};
                // 1-7：切换工具
                case (_key >= 0x02 && {_key <= 0x08} && {!_ctrl} && {!_alt}): {
                    call _fnc_cancel;
                    ["tool", _key - 1] call BRF_fnc_presenterAction;
                };
                // Esc：先取消正在进行的操作，没有的话关闭界面
                case (_key == 0x01): {
                    if (BRF_drawing || {BRF_areaPts isNotEqualTo []} || {BRF_rulerA isNotEqualTo []}) then {
                        call _fnc_cancel;
                    } else {
                        _display closeDisplay 2;
                    };
                };
                case (_key in [0x1C, 0x9C]): {
                    if (BRF_tool == TOOL_AREA) then {call _fnc_finishArea};
                };
                case (_key == 0x10): {["color", -1] call BRF_fnc_presenterAction};              // Q
                case (_key == 0x12): {["color", 1] call BRF_fnc_presenterAction};               // E
                case (_key == 0x0F): {["iconKind"] call BRF_fnc_presenterAction};               // Tab
                case (_key == 0x1E && {!_ctrl}): {["arrow"] call BRF_fnc_presenterAction};      // A
                case (_key == 0x21 && {!_ctrl}): {["focus"] call BRF_fnc_presenterAction};      // F
                case (_key == 0x2C && {_ctrl}): {["undo"] call BRF_fnc_presenterAction};        // Ctrl+Z
                case (_key == 0xD3 && {_ctrl} && {_shift}): {["clear"] call BRF_fnc_presenterAction}; // Ctrl+Shift+Del
                case (_key == 0xD3 && {!_ctrl} && {!BRF_planEdit}): {                         // Delete：删除鼠标下的元素
                    getMousePosition params ["_mx", "_my"];
                    private _id = [_map, _mx, _my, _erasable] call BRF_fnc_hitTest;
                    if (_id != "") then {
                        ["del", _id] call BRF_fnc_send;
                        [] call BRF_fnc_presenterUpdate;
                    };
                };
                case (_key == 0x2D && {!_ctrl} && {BRF_planEdit}): {                          // X（编排）：本步加 / 取消「摧毁」前面步的元素
                    getMousePosition params ["_mx", "_my"];
                    private _id = [_mx, _my] call _fnc_planHit;
                    if (_id != "") then {["toggleAction", "destroy", _id] call BRF_fnc_plan};
                };
                case (_key == 0x2D && {!_ctrl} && {!BRF_planEdit}): {                         // X：摧毁 / 恢复鼠标下的元素
                    getMousePosition params ["_mx", "_my"];
                    private _id = [_map, _mx, _my, _erasable] call BRF_fnc_hitTest;
                    if (_id != "") then {
                        private _on = ((BRF_elMap get _id) param [E_DESTROYED, -1]) == -1;
                        ["destroy", _id, _on] call BRF_fnc_send;
                    };
                };

                // ---- 预案 ----
                case (_key == 0x19 && {!_ctrl}): {["toggleEdit"] call BRF_fnc_plan};            // P
                case (_key in [0xCD, 0xD1, 0x1B]): {                                            // → / PageDown / ]
                    [["play", "nextStep"] select BRF_planEdit] call BRF_fnc_plan;
                };
                case (_key in [0xCB, 0xC9, 0x1A]): {                                            // ← / PageUp / [
                    [["back", "prevStep"] select BRF_planEdit] call BRF_fnc_plan;
                };
                case (_key == 0xC7 && {!BRF_planEdit}): {["reset"] call BRF_fnc_plan};          // Home
                case (BRF_planEdit && {_key == 0x31} && {!_ctrl}): {["newStep"] call BRF_fnc_plan};    // N
                case (BRF_planEdit && {_key == 0x2F} && {!_ctrl}): {["recordView"] call BRF_fnc_plan}; // V
                case (BRF_planEdit && {_key == 0x2E} && {!_ctrl}): {["toggleView"] call BRF_fnc_plan}; // C
                case (BRF_planEdit && {_key == 0xD3}): {["deleteStep"] call BRF_fnc_plan};             // Delete
                default {_handled = false};
            };
        };

        BRF_lastKeyResult = _handled;
        _return = _handled;
    };
};

_return
