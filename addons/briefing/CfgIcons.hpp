// 图标注册表。新增图标：在这里加一个类，并把白色透明贴图放进 ui\icons\（见 tools/fetch_icons.py），不用改代码。
//
// 每个图标的字段：
//   displayName  显示名（可以是 $STR_ 键）
//   abbr         缩写：标签留空时显示，也写进原版标记的文字
//   texture      贴图（白色、透明底，按元素颜色着色）；留空时用 shape 画基础图形
//   shape        没有贴图时的程序图形：diamond / box / triangle / hollowDiamond / none（只有文字）
//   category     图标面板里的分组：0 基础 / 1 地面单位 / 2 空中·海上 / 3 设施 / 4 战术标记
//   sound        闪烁时的「哔」声（文件路径，必须带扩展名）
//   markerType   【必填】镜像到原版地图时用的 CfgMarkers 类型。b_ 开头的北约兵种标记会按元素颜色换成 b_ / o_ / n_
//   markerColor  【必填】原版标记颜色：palette = 跟着元素颜色走（友军 ColorBLUFOR / 敌军 ColorOPFOR / 注意 ColorYellow / 目标 ColorGreen），
//                也可以写死一个 CfgMarkerColors 类名，例如 ColorOrange
// markerType 或 markerColor 缺失、或者游戏里不存在时，这个图标不会被注册（RPT 里会有 [BRF] 错误）。
//
// 贴图来自 game-icons.net（CC BY 3.0），作者见 docs/CREDITS.md。

class BRF_Icons {
    class tgt {
        displayName = "$STR_BRF_KindTgt";
        abbr = "TGT";
        texture = "";
        shape = "diamond";
        category = 0;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_destroy";
        markerColor = "palette";
    };
    class lz {
        displayName = "$STR_BRF_KindLz";
        abbr = "LZ";
        texture = "";
        shape = "box";
        category = 0;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_pickup";
        markerColor = "palette";
    };
    class ip {
        displayName = "$STR_BRF_KindIp";
        abbr = "IP";
        texture = "";
        shape = "triangle";
        category = 0;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_start";
        markerColor = "palette";
    };
    class wp {
        displayName = "$STR_BRF_KindWp";
        abbr = "WP";
        texture = "";
        shape = "hollowDiamond";
        category = 0;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_dot";
        markerColor = "palette";
    };
    class text {
        displayName = "$STR_BRF_IconText";
        abbr = "";
        texture = "";
        shape = "none";
        category = 0;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "EmptyIcon";
        markerColor = "palette";
    };
    class inf {
        displayName = "$STR_BRF_IconInf";
        abbr = "INF";
        texture = "\z\brf\addons\briefing\ui\icons\inf_ca.paa";
        shape = "";
        category = 1;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_inf";
        markerColor = "palette";
    };
    class armor {
        displayName = "$STR_BRF_IconArmor";
        abbr = "ARMOR";
        texture = "\z\brf\addons\briefing\ui\icons\armor_ca.paa";
        shape = "";
        category = 1;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_armor";
        markerColor = "palette";
    };
    class mech {
        displayName = "$STR_BRF_IconMech";
        abbr = "MECH";
        texture = "\z\brf\addons\briefing\ui\icons\mech_ca.paa";
        shape = "";
        category = 1;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_mech_inf";
        markerColor = "palette";
    };
    class motor {
        displayName = "$STR_BRF_IconMotor";
        abbr = "MOTOR";
        texture = "\z\brf\addons\briefing\ui\icons\motor_ca.paa";
        shape = "";
        category = 1;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_motor_inf";
        markerColor = "palette";
    };
    class art {
        displayName = "$STR_BRF_IconArt";
        abbr = "ARTY";
        texture = "\z\brf\addons\briefing\ui\icons\art_ca.paa";
        shape = "";
        category = 1;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_art";
        markerColor = "palette";
    };
    class mortar {
        displayName = "$STR_BRF_IconMortar";
        abbr = "MORTAR";
        texture = "\z\brf\addons\briefing\ui\icons\mortar_ca.paa";
        shape = "";
        category = 1;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_mortar";
        markerColor = "palette";
    };
    class aa {
        displayName = "$STR_BRF_IconAa";
        abbr = "AA";
        texture = "\z\brf\addons\briefing\ui\icons\aa_ca.paa";
        shape = "";
        category = 1;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_antiair";
        markerColor = "palette";
    };
    class recon {
        displayName = "$STR_BRF_IconRecon";
        abbr = "RECON";
        texture = "\z\brf\addons\briefing\ui\icons\recon_ca.paa";
        shape = "";
        category = 1;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_recon";
        markerColor = "palette";
    };
    class sniper {
        displayName = "$STR_BRF_IconSniper";
        abbr = "SNIPER";
        texture = "\z\brf\addons\briefing\ui\icons\sniper_ca.paa";
        shape = "";
        category = 1;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_recon";
        markerColor = "palette";
    };
    class heli {
        displayName = "$STR_BRF_IconHeli";
        abbr = "HELO";
        texture = "\z\brf\addons\briefing\ui\icons\heli_ca.paa";
        shape = "";
        category = 2;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_air";
        markerColor = "palette";
    };
    class plane {
        displayName = "$STR_BRF_IconPlane";
        abbr = "AIR";
        texture = "\z\brf\addons\briefing\ui\icons\plane_ca.paa";
        shape = "";
        category = 2;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_plane";
        markerColor = "palette";
    };
    class uav {
        displayName = "$STR_BRF_IconUav";
        abbr = "UAV";
        texture = "\z\brf\addons\briefing\ui\icons\uav_ca.paa";
        shape = "";
        category = 2;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_uav";
        markerColor = "palette";
    };
    class ship {
        displayName = "$STR_BRF_IconShip";
        abbr = "SHIP";
        texture = "\z\brf\addons\briefing\ui\icons\ship_ca.paa";
        shape = "";
        category = 2;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_naval";
        markerColor = "palette";
    };
    class landing {
        displayName = "$STR_BRF_IconLanding";
        abbr = "LCU";
        texture = "\z\brf\addons\briefing\ui\icons\landing_ca.paa";
        shape = "";
        category = 2;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_naval";
        markerColor = "palette";
    };
    class hq {
        displayName = "$STR_BRF_IconHq";
        abbr = "HQ";
        texture = "\z\brf\addons\briefing\ui\icons\hq_ca.paa";
        shape = "";
        category = 3;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_hq";
        markerColor = "palette";
    };
    class supply {
        displayName = "$STR_BRF_IconSupply";
        abbr = "SUPPLY";
        texture = "\z\brf\addons\briefing\ui\icons\supply_ca.paa";
        shape = "";
        category = 3;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_support";
        markerColor = "palette";
    };
    class med {
        displayName = "$STR_BRF_IconMed";
        abbr = "MED";
        texture = "\z\brf\addons\briefing\ui\icons\med_ca.paa";
        shape = "";
        category = 3;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_med";
        markerColor = "palette";
    };
    class radar {
        displayName = "$STR_BRF_IconRadar";
        abbr = "RADAR";
        texture = "\z\brf\addons\briefing\ui\icons\radar_ca.paa";
        shape = "";
        category = 3;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_installation";
        markerColor = "palette";
    };
    class bridge {
        displayName = "$STR_BRF_IconBridge";
        abbr = "BRIDGE";
        texture = "\z\brf\addons\briefing\ui\icons\bridge_ca.paa";
        shape = "";
        category = 3;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_box";
        markerColor = "palette";
    };
    class airfield {
        displayName = "$STR_BRF_IconAirfield";
        abbr = "AIRFIELD";
        texture = "\z\brf\addons\briefing\ui\icons\airfield_ca.paa";
        shape = "";
        category = 3;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_installation";
        markerColor = "palette";
    };
    class fuel {
        displayName = "$STR_BRF_IconFuel";
        abbr = "FUEL";
        texture = "\z\brf\addons\briefing\ui\icons\fuel_ca.paa";
        shape = "";
        category = 3;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_service";
        markerColor = "palette";
    };
    class comms {
        displayName = "$STR_BRF_IconComms";
        abbr = "COMMS";
        texture = "\z\brf\addons\briefing\ui\icons\comms_ca.paa";
        shape = "";
        category = 3;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "b_installation";
        markerColor = "palette";
    };
    class rally {
        displayName = "$STR_BRF_IconRally";
        abbr = "RP";
        texture = "\z\brf\addons\briefing\ui\icons\rally_ca.paa";
        shape = "";
        category = 4;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_flag";
        markerColor = "palette";
    };
    class extract {
        displayName = "$STR_BRF_IconExtract";
        abbr = "EXFIL";
        texture = "\z\brf\addons\briefing\ui\icons\extract_ca.paa";
        shape = "";
        category = 4;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_pickup";
        markerColor = "palette";
    };
    class danger {
        displayName = "$STR_BRF_IconDanger";
        abbr = "DANGER";
        texture = "\z\brf\addons\briefing\ui\icons\danger_ca.paa";
        shape = "";
        category = 4;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_warning";
        markerColor = "palette";
    };
    class op {
        displayName = "$STR_BRF_IconOp";
        abbr = "OP";
        texture = "\z\brf\addons\briefing\ui\icons\op_ca.paa";
        shape = "";
        category = 4;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_triangle";
        markerColor = "palette";
    };
    class checkpoint {
        displayName = "$STR_BRF_IconCheckpoint";
        abbr = "CP";
        texture = "\z\brf\addons\briefing\ui\icons\checkpoint_ca.paa";
        shape = "";
        category = 4;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_box";
        markerColor = "palette";
    };
    class vip {
        displayName = "$STR_BRF_IconVip";
        abbr = "VIP";
        texture = "\z\brf\addons\briefing\ui\icons\vip_ca.paa";
        shape = "";
        category = 4;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_objective";
        markerColor = "palette";
    };
    class ied {
        displayName = "$STR_BRF_IconIed";
        abbr = "IED";
        texture = "\z\brf\addons\briefing\ui\icons\ied_ca.paa";
        shape = "";
        category = 4;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_warning";
        markerColor = "palette";
    };
    class ambush {
        displayName = "$STR_BRF_IconAmbush";
        abbr = "AMBUSH";
        texture = "\z\brf\addons\briefing\ui\icons\ambush_ca.paa";
        shape = "";
        category = 4;
        sound = "\z\brf\addons\briefing\sounds\ping.ogg";
        markerType = "mil_ambush";
        markerColor = "palette";
    };
};
