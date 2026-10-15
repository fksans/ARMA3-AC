#include "..\script_component.hpp"
/*
 * 预案（主持端，只在本机、只在这一局有效）：简报前把内容分步编排好，讲的时候像 PPT 一样按键逐步展示。
 *
 * 预案 BRF_plan = [步, ...]；每一步 = [元素记录, 视角, 是否用镜头]
 *   元素记录和 BRF_els 的格式一样（[id, 类型, 颜色, 数据, t0, t1, 缓存]），编排模式下用 BRF_fnc_renderElement 半透明画出来
 *   视角 = [中心x, 中心y, 缩放]，没记录时为 []
 *   是否用镜头：播放这一步时先把所有人的地图飞到这个视角（视角和当前差不多时不飞）
 * 已经播放的步：BRF_planPlayed = [[该步发出的 id...], ...]，BRF_planTokens 和它一一对应，用来作废还没出完的元素
 *
 * Arguments:
 * 0: 操作 <STRING>
 *    编排："toggleEdit" / "newStep" / "prevStep" / "nextStep" / "recordView" / "toggleView" / "deleteStep"
 *          "add" 类型 数据 / "undo" / "erase" id / "clear"
 *    播放："play" / "back" / "reset"
 * 1, 2: 参数
 */

params [["_action", "", [""]], "_arg1", "_arg2"];

private _display = uiNamespace getVariable ["BRF_presenter", displayNull];
private _map = _display displayCtrl IDC_BRF_MAP;
private _now = diag_tickTime;

private _fnc_msg = {
    params ["_text", ["_color", [1, 0.85, 0.4, 1]]];
    [_text, _color] call BRF_fnc_presenterMessage;
};
private _fnc_currentView = {
    if (isNull _map) exitWith {[]};
    ctrlPosition _map params ["_x0", "_y0", "_w", "_h"];
    private _c = _map ctrlMapScreenToWorld [_x0 + _w / 2, _y0 + _h / 2];
    [round (_c select 0), round (_c select 1), ctrlMapScale _map]
};
private _fnc_jumpLocal = {
    // 编排时切换步骤：只把自己的地图移到那一步的视角
    params ["_view"];
    if (isNull _map || {_view isEqualTo []}) exitWith {};
    _view params ["_cx", "_cy", "_scale"];
    ctrlMapAnimClear _map;
    _map ctrlMapAnimAdd [0.4, _scale, [_cx, _cy]];
    ctrlMapAnimCommit _map;
};
private _fnc_newStep = {
    // [元素记录, 视角, 是否用镜头]；默认记录当前视角
    [[], call _fnc_currentView, true]
};
private _fnc_confirm = {
    // 3 秒内按两次才执行
    params ["_key", "_text"];
    if (_now - (missionNamespace getVariable [_key, -10]) > 3) exitWith {
        missionNamespace setVariable [_key, _now];
        [_text, [1, 0.5, 0.4, 1]] call _fnc_msg;
        false
    };
    missionNamespace setVariable [_key, -10];
    true
};

switch (_action) do {
    // ---------------------------------------------------------------- 编排
    case "toggleEdit": {
        BRF_planEdit = !BRF_planEdit;
        BRF_hoverId = "";
        if (BRF_planEdit) then {
            if (BRF_plan isEqualTo []) then {
                BRF_plan pushBack (call _fnc_newStep);
            };
            BRF_planEditStep = (BRF_planEditStep max 0) min (count BRF_plan - 1);
            [localize "STR_BRF_MsgPlanEditOn", [1, 0.75, 0.3, 1]] call _fnc_msg;
        } else {
            // 去掉空的步
            BRF_plan = BRF_plan select {(_x select 0) isNotEqualTo []};
            BRF_planEditStep = (BRF_planEditStep min (count BRF_plan - 1)) max 0;
            [format [localize "STR_BRF_MsgPlanEditOff", count BRF_plan], [0.55, 1, 0.9, 1]] call _fnc_msg;
        };
    };
    case "newStep": {
        BRF_planEditStep = BRF_planEditStep + 1;
        BRF_plan insert [BRF_planEditStep, [call _fnc_newStep]];
    };
    case "prevStep";
    case "nextStep": {
        private _to = BRF_planEditStep + ([-1, 1] select (_action == "nextStep"));
        if (_to < 0 || {_to >= count BRF_plan}) exitWith {};
        BRF_planEditStep = _to;
        BRF_hoverId = "";
        [(BRF_plan select _to) select 1] call _fnc_jumpLocal;
    };
    case "recordView": {
        private _step = BRF_plan select BRF_planEditStep;
        _step set [1, call _fnc_currentView];
        _step set [2, true];
        [localize "STR_BRF_MsgPlanViewRecorded", [0.55, 1, 0.9, 1]] call _fnc_msg;
    };
    case "toggleView": {
        private _step = BRF_plan select BRF_planEditStep;
        _step set [2, !(_step select 2)];
        if ((_step select 2) && {(_step select 1) isEqualTo []}) then {
            _step set [1, call _fnc_currentView];
        };
    };
    case "deleteStep": {
        private _step = BRF_plan select BRF_planEditStep;
        if ((_step select 0) isNotEqualTo [] && {!(["BRF_planDeleteArmed", localize "STR_BRF_MsgPlanDeleteConfirm"] call _fnc_confirm)}) exitWith {};
        BRF_plan deleteAt BRF_planEditStep;
        if (BRF_plan isEqualTo []) then {
            BRF_plan pushBack (call _fnc_newStep);
        };
        BRF_planEditStep = (BRF_planEditStep min (count BRF_plan - 1)) max 0;
    };
    case "add": {
        private _cache = [_arg1, _arg2] call BRF_fnc_buildCache;
        if (_cache isEqualTo []) exitWith {};
        if (BRF_plan isEqualTo []) then {
            BRF_plan pushBack (call _fnc_newStep);
            BRF_planEditStep = 0;
        };
        BRF_planSeq = BRF_planSeq + 1;
        private _step = BRF_plan select BRF_planEditStep;
        (_step select 0) pushBack [format ["plan_%1", BRF_planSeq], _arg1, BRF_color, _arg2, -1e6, -1, _cache];
        // 这一步还没记录视角的话，用放第一个元素时的视角
        if ((_step select 2) && {(_step select 1) isEqualTo []}) then {
            _step set [1, call _fnc_currentView];
        };
    };
    case "undo": {
        private _records = (BRF_plan select BRF_planEditStep) select 0;
        if (_records isEqualTo []) exitWith {
            [localize "STR_BRF_MsgNothingToUndo"] call _fnc_msg;
        };
        _records deleteAt (count _records - 1);
    };
    case "erase": {
        private _records = (BRF_plan select BRF_planEditStep) select 0;
        private _index = _records findIf {(_x select E_ID) == _arg1};
        if (_index != -1) then {_records deleteAt _index};
        BRF_hoverId = "";
    };
    case "clear": {
        if !(["BRF_planClearArmed", localize "STR_BRF_MsgPlanClearConfirm"] call _fnc_confirm) exitWith {};
        BRF_plan = [call _fnc_newStep];
        BRF_planEditStep = 0;
        // 已经播放出去的元素还在地图上，但不再算作预案的步
        BRF_planPlayed = [];
        BRF_planTokens = [];
        [localize "STR_BRF_MsgPlanCleared", [0.55, 1, 0.9, 1]] call _fnc_msg;
    };

    // ---------------------------------------------------------------- 播放
    case "play": {
        private _index = count BRF_planPlayed;
        if (BRF_plan isEqualTo [] || {(BRF_plan select {(_x select 0) isNotEqualTo []}) isEqualTo []}) exitWith {
            [localize "STR_BRF_MsgPlanEmpty"] call _fnc_msg;
        };
        // 跳过空的步
        while {_index < count BRF_plan && {((BRF_plan select _index) select 0) isEqualTo []}} do {
            BRF_planPlayed pushBack [];
            BRF_planTokens pushBack -1;
            _index = _index + 1;
        };
        if (_index >= count BRF_plan) exitWith {
            [localize "STR_BRF_MsgPlanDone"] call _fnc_msg;
        };

        (BRF_plan select _index) params ["_records", "_view", "_useView"];
        private _live = {(_x select E_T1) < 0} count BRF_els;
        if (_live + count _records > MAX_ELEMENTS) exitWith {
            [format [localize "STR_BRF_MsgTooMany", MAX_ELEMENTS], [1, 0.4, 0.4, 1]] call _fnc_msg;
        };

        // 镜头：飞到这一步的视角；和当前视角差不多（中心偏移小于画面宽度的 15%、缩放差不到 1.3 倍）就不飞
        private _delay = 0;
        if (_useView && {_view isNotEqualTo []} && {!isNull _map}) then {
            private _current = call _fnc_currentView;
            _view params ["_cx", "_cy", "_scale"];
            BRF_viewBox params ["_minX", "", "_maxX"];
            private _offset = [_cx, _cy] distance2D [_current select 0, _current select 1];
            private _ratio = (_scale max (_current select 2)) / ((_scale min (_current select 2)) max 1e-6);
            if (_offset > 0.15 * (_maxX - _minX) || {_ratio > 1.3}) then {
                ctrlMapAnimClear _map;
                _map ctrlMapAnimAdd [PLAN_FLY_TIME, _scale, [_cx, _cy]];
                ctrlMapAnimCommit _map;
                if (call BRF_fnc_isHost) then {
                    // 飞行期间不发中间视角，免得观看端一顿一顿
                    BRF_viewSyncPauseUntil = _now + PLAN_FLY_TIME + 0.1;
                    BRF_lastView = +_view;
                    BRF_lastViewTime = _now;
                    BRF_view = [_cx, _cy, _scale, PLAN_FLY_TIME];
                    publicVariable "BRF_view";
                };
                _delay = PLAN_FLY_TIME * 0.75;
            };
        };

        // 元素一个接一个出现；撤回这一步时，还没出现的作废
        BRF_planTokenSeq = BRF_planTokenSeq + 1;
        private _token = BRF_planTokenSeq;
        private _ids = [];
        {
            _x params ["", "_type", "_color", "_data"];
            private _id = [] call BRF_fnc_newId;
            _ids pushBack _id;
            [{
                params ["_token", "_evt"];
                if !(_token in BRF_planTokens) exitWith {};
                _evt call BRF_fnc_send;
                [] call BRF_fnc_presenterUpdate;
            }, [_token, ["add", [_id, _type, _color, _data]]], _delay + _forEachIndex * PLAN_ELEMENT_GAP] call CBA_fnc_waitAndExecute;
        } forEach _records;
        BRF_planPlayed pushBack _ids;
        BRF_planTokens pushBack _token;

        [format [localize "STR_BRF_MsgPlanStep", _index + 1, count BRF_plan], [0.55, 1, 0.9, 1]] call _fnc_msg;
    };
    case "back": {
        // 撤回最后播放的一步：只移除元素，镜头不动
        while {BRF_planPlayed isNotEqualTo [] && {(BRF_planPlayed select (count BRF_planPlayed - 1)) isEqualTo []}} do {
            BRF_planPlayed deleteAt (count BRF_planPlayed - 1);
            BRF_planTokens deleteAt (count BRF_planTokens - 1);
        };
        if (BRF_planPlayed isEqualTo []) exitWith {
            [localize "STR_BRF_MsgPlanAtStart"] call _fnc_msg;
        };
        private _ids = BRF_planPlayed deleteAt (count BRF_planPlayed - 1);
        BRF_planTokens deleteAt (count BRF_planTokens - 1);
        {
            private _record = BRF_elMap getOrDefault [_x, []];
            if (_record isNotEqualTo [] && {(_record select E_T1) < 0}) then {
                ["del", _x] call BRF_fnc_send;
            };
        } forEach _ids;
        [format [localize "STR_BRF_MsgPlanBack", count BRF_planPlayed, count BRF_plan], [0.55, 1, 0.9, 1]] call _fnc_msg;
    };
    case "reset": {
        while {BRF_planPlayed isNotEqualTo []} do {
            ["back"] call BRF_fnc_plan;
        };
    };
};

[] call BRF_fnc_presenterUpdate;
