#include "..\script_component.hpp"
/*
 * 处理一个简报事件（主持端和观看端共用）。动画时钟以本机收到事件的 diag_tickTime 为起点，
 * 不需要跨机器对时。按 id 去重：重复收到、乱序收到都不会出错。
 * 每次 add / del / clear 都同步更新 BRF_state，但只有主持端会把它发出去（见 BRF_fnc_send）。
 *
 * Arguments（_this 就是事件数组）:
 * ["add", 元素, 立即(可选，默认 false)]  元素 = [id, 类型, 颜色序号, 数据]；立即 = 不播动画、不出声
 * ["del", id]
 * ["clear"]
 * ["session", 开关, 主持人名字, 主持人 clientOwner]
 * ["sync"]   本机专用：把本地元素表对齐到 BRF_state（中途加入 / 重新打开界面）
 */

params [["_type", "", [""]]];

private _now = diag_tickTime;

switch (_type) do {
    case "add": {
        params ["", ["_el", [], [[]]], ["_instant", false, [false]]];
        _el params [["_id", "", [""]], ["_elType", "", [""]], ["_color", 0, [0]], ["_data", [], [[]]]];
        if (_id == "" || {_id in BRF_elMap}) exitWith {};

        private _cache = [_elType, _data] call BRF_fnc_buildCache;
        if (_cache isEqualTo []) exitWith {}; // 数据不合法

        _color = (round _color) max 0 min (count BRF_palette - 1);
        private _record = [_id, _elType, _color, _data, [_now, -1e6] select _instant, -1, _cache];
        BRF_els pushBack _record;
        BRF_elMap set [_id, _record];

        if (BRF_state findIf {(_x select 0) == _id} == -1) then {
            BRF_state pushBack [_id, _elType, _color, _data];
        };

        // 音效只在界面打开时播放（图标的「滴滴」在 BRF_fnc_renderIcon 里随闪烁播放）
        if (!_instant && {
            !isNull (uiNamespace getVariable ["BRF_viewer", displayNull])
            || {!isNull (uiNamespace getVariable ["BRF_presenter", displayNull])}
        }) then {
            switch (_elType) do {
                case "line";
                case "area": {playSoundUI [SOUND_DRAW, SOUND_VOLUME]};
                case "ring": {playSoundUI [SOUND_RING, SOUND_VOLUME]};
            };
        };

        // 删除后已经淡完、但界面没开（没人渲染）的元素顺便清掉
        if (count BRF_els > MAX_ELEMENTS) then {[] call BRF_fnc_purge};
    };

    case "del": {
        params ["", ["_id", "", [""]]];
        private _record = BRF_elMap getOrDefault [_id, []];
        if (_record isEqualTo [] || {(_record select E_T1) >= 0}) exitWith {};

        _record set [E_T1, _now];
        private _index = BRF_state findIf {(_x select 0) == _id};
        if (_index != -1) then {
            BRF_state deleteAt _index;
        };
        if (BRF_hoverId == _id) then {BRF_hoverId = ""};
    };

    case "clear": {
        {
            if ((_x select E_T1) < 0) then {
                _x set [E_T1, _now];
            };
        } forEach BRF_els;
        BRF_state = [];
        BRF_hoverId = "";
    };

    case "session": {
        params ["", ["_active", false, [false]], ["_name", "", [""]], ["_owner", -1, [0]]];
        BRF_session = [_active, _name, _owner];

        if (_active) then {
            if (_owner == clientOwner) then {
                [false] call BRF_fnc_closeViewer;
            } else {
                [] call BRF_fnc_openViewer;
            };
        } else {
            BRF_ptrTarget = [];
            [true] call BRF_fnc_closeViewer;
        };

        [] call BRF_fnc_viewerUpdate;
        [] call BRF_fnc_presenterUpdate;
    };

    case "sync": {
        // 本地有、BRF_state 里没有的：立即移除（不播淡出）
        private _ids = createHashMapFromArray (BRF_state apply {[_x select 0, true]});
        {
            if ((_x select E_T1) < 0 && {!((_x select E_ID) in _ids)}) then {
                _x set [E_T1, _now - FADE_OUT_TIME];
            };
        } forEach BRF_els;
        [] call BRF_fnc_purge;

        // BRF_state 里有、本地没有的：直接设为「已播完」
        {
            ["add", _x, true] call BRF_fnc_onEvent;
        } forEach +BRF_state;
    };
};
