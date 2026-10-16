// AC Briefing - 暗色战术地图 + 观看界面 + 主持界面
// 文字控件用原版 3DEN 风格基类（configFile 根下的 ctrl*），地图继承 RscMapControl。

class RscMapControl;
class ctrlStatic;
class ctrlStaticBackground;
class ctrlStructuredText;
class ctrlButton;
class ctrlEdit;
class ctrlStaticPicture;
class ctrlCombo;
class ctrlListbox;

// ---------------------------------------------------------------------------
// 暗色地图：颜色全部压暗并换成青绿单色调，关掉卫星图和任务标记。
// 颜色只是起点，最终要进游戏边看边调。
// ---------------------------------------------------------------------------
class BRF_RscMap: RscMapControl {
    idc = IDC_BRF_MAP;
    x = "safeZoneXAbs";
    y = "safeZoneY";
    w = "safeZoneWAbs";
    h = "safeZoneH";
    showMarkers = 0;              // 隐藏任务里已有的地图标记，需实测是否生效
    maxSatelliteAlpha = 0;        // 放大时不显示卫星图
    alphaFadeStartScale = 0;
    alphaFadeEndScale = 0;
    colorBackground[]          = {0.04, 0.07, 0.09, 1};
    colorOutside[]             = {0, 0, 0, 1};
    colorSea[]                 = {0.02, 0.05, 0.08, 1};
    colorForest[]              = {0.07, 0.13, 0.11, 0.6};
    colorForestBorder[]        = {0, 0, 0, 0};
    colorRocks[]               = {0.20, 0.50, 0.45, 0.2};
    colorCountlines[]          = {0.15, 0.45, 0.40, 0.25};
    colorMainCountlines[]      = {0.15, 0.45, 0.40, 0.45};
    colorCountlinesWater[]     = {0.10, 0.30, 0.45, 0.25};
    colorMainCountlinesWater[] = {0.10, 0.30, 0.45, 0.45};
    colorLevels[]              = {0.15, 0.45, 0.40, 0.35};
    colorGrid[]                = {0.20, 0.60, 0.55, 0.25};
    colorGridMap[]             = {0.20, 0.60, 0.55, 0.15};
    colorRoads[]               = {0.25, 0.55, 0.50, 0.6};
    colorRoadsFill[]           = {0.10, 0.20, 0.20, 1};
    colorMainRoads[]           = {0.35, 0.70, 0.65, 0.8};
    colorMainRoadsFill[]       = {0.12, 0.25, 0.24, 1};
    colorTracks[]              = {0.25, 0.50, 0.45, 0.3};
    colorTracksFill[]          = {0.10, 0.20, 0.20, 1};
    colorTrails[]              = {0.25, 0.50, 0.45, 0.2};
    colorTrailsFill[]          = {0.10, 0.20, 0.20, 0.6};
    colorPowerLines[]          = {0.20, 0.50, 0.45, 0.4};
    colorRailWay[]             = {0.30, 0.60, 0.55, 0.6};
    colorNames[]               = {0.40, 0.90, 0.80, 0.8};
    colorText[]                = {0.40, 0.90, 0.80, 1};
    colorInactive[]            = {0.40, 0.90, 0.80, 0.4};
};

class BRF_RscText: ctrlStatic {
    idc = -1;
    sizeEx = QUOTE(TXT_SIZE);
    font = "PuristaMedium";
    colorText[] = {0.40, 0.90, 0.80, 1};
};
class BRF_RscButton: ctrlButton {
    idc = -1;
    sizeEx = QUOTE(TXT_SIZE_SMALL);
    font = "PuristaMedium";
    y = QUOTE(BTN_Y);
    w = QUOTE(BTN_W);
    h = QUOTE(BTN_H);
    colorBackground[] = {0.05, 0.16, 0.17, 0.9};
    colorBackgroundActive[] = {0.12, 0.38, 0.36, 1};
    colorFocused[] = {0.05, 0.16, 0.17, 0.9};
    colorText[] = {0.55, 1, 0.9, 1};
};

// ---------------------------------------------------------------------------
// 观看界面（所有玩家）
// ---------------------------------------------------------------------------
class BRF_Viewer {
    idd = IDD_BRF_VIEWER;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "call BRF_fnc_viewerOnLoad";
    onUnload = "call BRF_fnc_viewerOnUnload";

    // 地图放在 controlsBackground：地图控件获得焦点（点一下）时会画到同一层其他控件上面，
    // 放在背景层才能保证标题、工具栏、输入框始终在地图上面（原版主地图也是这样放的）。
    // 地图控件不能放进 controls group，背景层不是 group，可以。
    class controlsBackground {
        class Map: BRF_RscMap {
            idc = IDC_BRF_MAP;
        };
    };
    class controls {
        // 上下两条暗边，像 AC 的简报画面
        class TopBar: ctrlStaticBackground {
            idc = IDC_BRF_V_TOP_BAR;
            x = "safeZoneXAbs";
            y = "safeZoneY";
            w = "safeZoneWAbs";
            h = QUOTE(0.075 * safezoneH);
            colorBackground[] = {0, 0, 0, 0.55};
        };
        class BottomBar: TopBar {
            idc = IDC_BRF_V_BOTTOM_BAR;
            y = QUOTE(safezoneY + safezoneH - 0.04 * safezoneH);
            h = QUOTE(0.04 * safezoneH);
        };
        class Title: BRF_RscText {
            idc = IDC_BRF_V_TITLE;
            text = "BRIEFING";
            font = "PuristaBold";
            sizeEx = QUOTE(0.045 * safezoneH);
            x = QUOTE(safezoneX + 0.012 * safezoneW);
            y = QUOTE(safezoneY + 0.004 * safezoneH);
            w = QUOTE(0.3 * safezoneW);
            h = QUOTE(0.045 * safezoneH);
        };
        class Host: BRF_RscText {
            idc = IDC_BRF_V_HOST;
            sizeEx = QUOTE(TXT_SIZE_SMALL);
            x = QUOTE(safezoneX + 0.013 * safezoneW);
            y = QUOTE(safezoneY + 0.046 * safezoneH);
            w = QUOTE(0.4 * safezoneW);
            h = QUOTE(0.026 * safezoneH);
            colorText[] = {0.40, 0.90, 0.80, 0.75};
        };
        class Mode: BRF_RscText {
            idc = IDC_BRF_V_MODE;
            style = 1; // ST_RIGHT
            sizeEx = QUOTE(TXT_SIZE);
            x = QUOTE(safezoneX + 0.6 * safezoneW);
            y = QUOTE(safezoneY + 0.02 * safezoneH);
            w = QUOTE(0.388 * safezoneW);
            h = QUOTE(0.035 * safezoneH);
        };
        class Hint: BRF_RscText {
            idc = IDC_BRF_V_HINT;
            style = 2; // ST_CENTER
            text = "$STR_BRF_ViewerHint";
            sizeEx = QUOTE(TXT_SIZE_SMALL);
            x = QUOTE(safezoneX);
            y = QUOTE(safezoneY + safezoneH - 0.036 * safezoneH);
            w = QUOTE(safezoneW);
            h = QUOTE(0.03 * safezoneH);
            colorText[] = {0.40, 0.90, 0.80, 0.6};
        };

        // ---- 开场动画（放在最上层；位置和颜色由 BRF_fnc_viewerIntro 每帧设置，不播开场时隐藏）----
        class IntroTop: ctrlStaticBackground {
            idc = IDC_BRF_V_INTRO_TOP;
            x = "safeZoneXAbs";
            y = "safeZoneY";
            w = "safeZoneWAbs";
            h = QUOTE(safezoneH / 2);
            colorBackground[] = {0, 0, 0, 1};
        };
        class IntroBottom: IntroTop {
            idc = IDC_BRF_V_INTRO_BOTTOM;
            y = QUOTE(safezoneY + safezoneH / 2);
        };
        class IntroGlowA: ctrlStaticBackground {
            idc = IDC_BRF_V_INTRO_GLOW_A;
            x = 0;
            y = 0;
            w = 0;
            h = 0;
            colorBackground[] = {0.40, 0.90, 0.80, 0.15};
        };
        class IntroGlowB: IntroGlowA {
            idc = IDC_BRF_V_INTRO_GLOW_B;
        };
        class IntroLineA: IntroGlowA {
            idc = IDC_BRF_V_INTRO_LINE_A;
            colorBackground[] = {0.63, 1, 0.92, 1};
        };
        class IntroLineB: IntroLineA {
            idc = IDC_BRF_V_INTRO_LINE_B;
        };
        class IntroMark: ctrlStaticBackground {
            idc = IDC_BRF_V_INTRO_MARK;
            x = QUOTE(0.5 - 4 * pixelW);
            y = QUOTE(0.5 - 4 * pixelH);
            w = QUOTE(8 * pixelW);
            h = QUOTE(8 * pixelH);
            colorBackground[] = {0.63, 1, 0.92, 1};
        };
        class IntroText: BRF_RscText {
            idc = IDC_BRF_V_INTRO_TEXT;
            style = 2; // ST_CENTER
            font = "EtelkaMonospacePro";
            sizeEx = QUOTE(TXT_SIZE_SMALL);
            x = QUOTE(0.5 - 0.15 * safezoneW);
            y = QUOTE(0.5 + 16 * pixelH);
            w = QUOTE(0.3 * safezoneW);
            h = QUOTE(0.03 * safezoneH);
        };
    };
};

// ---------------------------------------------------------------------------
// 主持界面（Zeus）：全屏地图 + 顶部工具栏 + 底部状态栏
// 工具栏按钮的事件在 BRF_fnc_presenterOnLoad 里挂。
// ---------------------------------------------------------------------------
class BRF_Presenter {
    idd = IDD_BRF_PRESENTER;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "call BRF_fnc_presenterOnLoad";
    onUnload = "call BRF_fnc_presenterOnUnload";

    // 地图放在 controlsBackground，原因见 BRF_Viewer
    class controlsBackground {
        class Map: BRF_RscMap {
            idc = IDC_BRF_MAP;
        };
    };
    class controls {
        // ---- 顶部工具栏 ----
        class ToolbarBg: ctrlStaticBackground {
            x = "safeZoneXAbs";
            y = "safeZoneY";
            w = "safeZoneWAbs";
            h = QUOTE(BAR_H);
            colorBackground[] = {0, 0.03, 0.04, 0.85};
        };
        class Tool1: BRF_RscButton {
            idc = 1201; // IDC_BRF_P_TOOL + 1
            text = "$STR_BRF_ToolLine";
            tooltip = "$STR_BRF_ToolLineTooltip";
            x = QUOTE(BTN_X(0));
        };
        class Tool2: BRF_RscButton {
            idc = 1202; // IDC_BRF_P_TOOL + 2
            text = "$STR_BRF_ToolIcon";
            tooltip = "$STR_BRF_ToolIconTooltip";
            x = QUOTE(BTN_X(1));
        };
        class Tool3: BRF_RscButton {
            idc = 1203; // IDC_BRF_P_TOOL + 3
            text = "$STR_BRF_ToolRing";
            tooltip = "$STR_BRF_ToolRingTooltip";
            x = QUOTE(BTN_X(2));
        };
        class Tool4: BRF_RscButton {
            idc = 1204; // IDC_BRF_P_TOOL + 4
            text = "$STR_BRF_ToolArea";
            tooltip = "$STR_BRF_ToolAreaTooltip";
            x = QUOTE(BTN_X(3));
        };
        class Tool5: BRF_RscButton {
            idc = 1205; // IDC_BRF_P_TOOL + 5
            text = "$STR_BRF_ToolPointer";
            tooltip = "$STR_BRF_ToolPointerTooltip";
            x = QUOTE(BTN_X(4));
        };
        class Tool6: BRF_RscButton {
            idc = 1206; // IDC_BRF_P_TOOL + 6
            text = "$STR_BRF_ToolEraser";
            tooltip = "$STR_BRF_ToolEraserTooltip";
            x = QUOTE(BTN_X(5));
        };
        class Color: ctrlCombo {
            idc = IDC_BRF_P_COLOR;
            tooltip = "$STR_BRF_ColorTooltip";
            sizeEx = QUOTE(TXT_SIZE_SMALL);
            x = QUOTE(BTN_X(6));
            y = QUOTE(BTN_Y);
            w = QUOTE(BTN_W);
            h = QUOTE(BTN_H);
        };
        class Arrow: BRF_RscButton {
            idc = IDC_BRF_P_ARROW;
            tooltip = "$STR_BRF_ArrowTooltip";
            x = QUOTE(BTN_X(7));
        };
        class Undo: BRF_RscButton {
            idc = IDC_BRF_P_UNDO;
            text = "$STR_BRF_Undo";
            tooltip = "$STR_BRF_UndoTooltip";
            x = QUOTE(BTN_X(8));
        };
        class Clear: BRF_RscButton {
            idc = IDC_BRF_P_CLEAR;
            text = "$STR_BRF_Clear";
            tooltip = "$STR_BRF_ClearTooltip";
            x = QUOTE(BTN_X(9));
        };
        class Bgm: ctrlCombo {
            idc = IDC_BRF_P_BGM;
            tooltip = "$STR_BRF_BgmTooltip";
            sizeEx = QUOTE(TXT_SIZE_SMALL);
            x = QUOTE(BTN_X(10));
            y = QUOTE(BTN_Y);
            w = QUOTE(BTN_W * 2 + 0.004 * safezoneW);
            h = QUOTE(BTN_H);
        };
        class Session: BRF_RscButton {
            idc = IDC_BRF_P_SESSION;
            x = QUOTE(BTN_X(12));
            colorBackground[] = {0.10, 0.30, 0.15, 0.95};
        };
        class Rebuild: BRF_RscButton {
            idc = IDC_BRF_P_REBUILD;
            text = "$STR_BRF_Rebuild";
            tooltip = "$STR_BRF_RebuildTooltip";
            x = QUOTE(BTN_X(13));
        };
        class Access: BRF_RscButton {
            idc = IDC_BRF_P_ACCESS;
            text = "$STR_BRF_Access";
            tooltip = "$STR_BRF_AccessTooltip";
            x = QUOTE(BTN_X(14));
        };
        class Plan: BRF_RscButton {
            idc = IDC_BRF_P_PLAN;
            tooltip = "$STR_BRF_PlanTooltip";
            x = QUOTE(BTN_X(15));
        };
        class Close: BRF_RscButton {
            idc = IDC_BRF_P_CLOSE;
            text = "X";
            tooltip = "$STR_BRF_CloseTooltip";
            x = QUOTE(BTN_X(16));
            w = QUOTE(BTN_W * 0.5);
        };

        // ---- 预案状态条：编排模式（橙色）/ 有预案时的播放进度（青色）----
        class PlanBanner: BRF_RscText {
            idc = IDC_BRF_P_PLAN_BANNER;
            style = 2; // ST_CENTER
            sizeEx = QUOTE(TXT_SIZE_SMALL);
            x = QUOTE(safezoneX + 0.25 * safezoneW);
            y = QUOTE(safezoneY + BAR_H + 0.008 * safezoneH);
            w = QUOTE(0.5 * safezoneW);
            h = QUOTE(0.032 * safezoneH);
            colorBackground[] = {0, 0.03, 0.04, 0.85};
        };

        // ---- 底部状态栏 ----
        class StatusBg: ToolbarBg {
            y = QUOTE(STATUS_Y);
        };
        class Status: BRF_RscText {
            idc = IDC_BRF_P_STATUS;
            sizeEx = QUOTE(TXT_SIZE_SMALL);
            x = QUOTE(safezoneX + 0.006 * safezoneW);
            y = QUOTE(STATUS_Y + 0.006 * safezoneH);
            w = QUOTE(0.64 * safezoneW);
            h = QUOTE(0.03 * safezoneH);
        };
        class Message: BRF_RscText {
            idc = IDC_BRF_P_MESSAGE;
            style = 1; // ST_RIGHT
            sizeEx = QUOTE(TXT_SIZE_SMALL);
            x = QUOTE(safezoneX + 0.65 * safezoneW);
            y = QUOTE(STATUS_Y + 0.006 * safezoneH);
            w = QUOTE(0.344 * safezoneW);
            h = QUOTE(0.03 * safezoneH);
            colorText[] = {1, 0.85, 0.4, 1};
        };

        // ---- 图标面板：目标点工具时显示，按类别列出全部图标 ----
        class IconTitle: BRF_RscText {
            idc = IDC_BRF_P_ICON_TITLE;
            text = "$STR_BRF_IconPanel";
            sizeEx = QUOTE(TXT_SIZE_SMALL);
            x = QUOTE(safezoneX + 0.006 * safezoneW);
            y = QUOTE(safezoneY + BAR_H + 0.008 * safezoneH);
            w = QUOTE(0.15 * safezoneW);
            h = QUOTE(0.03 * safezoneH);
            colorBackground[] = {0, 0.03, 0.04, 0.85};
        };
        class IconList: ctrlListbox {
            idc = IDC_BRF_P_ICON_LIST;
            sizeEx = QUOTE(TXT_SIZE_SMALL);
            rowHeight = QUOTE(0.034 * safezoneH);
            x = QUOTE(safezoneX + 0.006 * safezoneW);
            y = QUOTE(safezoneY + BAR_H + 0.038 * safezoneH);
            w = QUOTE(0.15 * safezoneW);
            h = QUOTE(0.62 * safezoneH);
            colorBackground[] = {0, 0.03, 0.04, 0.85};
            colorSelectBackground[] = {0.12, 0.38, 0.36, 1};
            colorSelectBackground2[] = {0.12, 0.38, 0.36, 1};
        };

        // ---- 标注权限面板：Zeus 点「权限」时显示在右侧，点一行切换 自动 → 授权 → 禁止 ----
        class AccessTitle: IconTitle {
            idc = IDC_BRF_P_ACCESS_TITLE;
            text = "$STR_BRF_AccessPanel";
            x = QUOTE(safezoneX + safezoneW - 0.226 * safezoneW);
            w = QUOTE(0.22 * safezoneW);
        };
        class AccessList: IconList {
            idc = IDC_BRF_P_ACCESS_LIST;
            x = QUOTE(safezoneX + safezoneW - 0.226 * safezoneW);
            w = QUOTE(0.22 * safezoneW);
            h = QUOTE(0.5 * safezoneH);
        };

        // ---- 目标点标签输入框（放点时出现在鼠标旁边） ----
        class Label: ctrlEdit {
            idc = IDC_BRF_P_LABEL;
            tooltip = "$STR_BRF_LabelTooltip";
            sizeEx = QUOTE(TXT_SIZE);
            x = 0;
            y = 0;
            w = QUOTE(0.14 * safezoneW);
            h = QUOTE(0.032 * safezoneH);
        };
        // 标签输入框左边的图标缩略图（按当前颜色着色，见 BRF_fnc_presenterUpdate）
        class LabelIcon: ctrlStaticPicture {
            idc = IDC_BRF_P_LABEL_ICON;
            x = 0;
            y = 0;
            w = QUOTE(0.032 * safezoneH * pixelW / pixelH);
            h = QUOTE(0.032 * safezoneH);
        };

        // ---- 别的 Zeus 正在主持时的遮罩：接管 / 只看 ----
        class LockBg: ctrlStaticBackground {
            idc = IDC_BRF_P_LOCK_BG;
            x = QUOTE(safezoneX + 0.3 * safezoneW);
            y = QUOTE(safezoneY + 0.38 * safezoneH);
            w = QUOTE(0.4 * safezoneW);
            h = QUOTE(0.2 * safezoneH);
            colorBackground[] = {0, 0.03, 0.04, 0.95};
        };
        class LockText: ctrlStructuredText {
            idc = IDC_BRF_P_LOCK_TEXT;
            size = QUOTE(TXT_SIZE);
            x = QUOTE(safezoneX + 0.31 * safezoneW);
            y = QUOTE(safezoneY + 0.395 * safezoneH);
            w = QUOTE(0.38 * safezoneW);
            h = QUOTE(0.11 * safezoneH);
        };
        class Takeover: BRF_RscButton {
            idc = IDC_BRF_P_TAKEOVER;
            text = "$STR_BRF_Takeover";
            sizeEx = QUOTE(TXT_SIZE);
            x = QUOTE(safezoneX + 0.32 * safezoneW);
            y = QUOTE(safezoneY + 0.52 * safezoneH);
            w = QUOTE(0.17 * safezoneW);
            h = QUOTE(0.04 * safezoneH);
        };
        class Watch: Takeover {
            idc = IDC_BRF_P_WATCH;
            text = "$STR_BRF_Watch";
            x = QUOTE(safezoneX + 0.51 * safezoneW);
        };
    };
};
