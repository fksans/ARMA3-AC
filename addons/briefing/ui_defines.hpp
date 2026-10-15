// AC Briefing - UI IDs & layout helpers

#define IDD_BRF_VIEWER 88100
#define IDD_BRF_PRESENTER 88200

// 两个界面里的地图控件
#define IDC_BRF_MAP 1000

// ---- 观看端 ----
#define IDC_BRF_V_TITLE 1100
#define IDC_BRF_V_HOST 1101
#define IDC_BRF_V_MODE 1102
#define IDC_BRF_V_HINT 1103
#define IDC_BRF_V_TOP_BAR 1104
#define IDC_BRF_V_BOTTOM_BAR 1105
// 开场动画
#define IDC_BRF_V_INTRO_TOP 1110
#define IDC_BRF_V_INTRO_BOTTOM 1111
#define IDC_BRF_V_INTRO_LINE_A 1112
#define IDC_BRF_V_INTRO_GLOW_A 1113
#define IDC_BRF_V_INTRO_LINE_B 1114
#define IDC_BRF_V_INTRO_GLOW_B 1115
#define IDC_BRF_V_INTRO_MARK 1116
#define IDC_BRF_V_INTRO_TEXT 1117

// ---- 主持端：工具栏按钮，基础 IDC + 工具序号（1-6） ----
#define IDC_BRF_P_TOOL 1200
#define IDC_BRF_P_COLOR 1210
#define IDC_BRF_P_ARROW 1211
#define IDC_BRF_P_UNDO 1212
#define IDC_BRF_P_CLEAR 1213
#define IDC_BRF_P_BGM 1214
#define IDC_BRF_P_SESSION 1215
#define IDC_BRF_P_REBUILD 1216
#define IDC_BRF_P_ACCESS 1217
#define IDC_BRF_P_CLOSE 1218
#define IDC_BRF_P_PLAN 1219
#define IDC_BRF_P_STATUS 1220
#define IDC_BRF_P_MESSAGE 1221
#define IDC_BRF_P_LABEL 1230
// 图标面板（目标点工具时显示在左侧）
#define IDC_BRF_P_ICON_TITLE 1250
#define IDC_BRF_P_ICON_LIST 1251
// 标注权限面板（Zeus 点「权限」时显示在右侧）
#define IDC_BRF_P_ACCESS_TITLE 1270
#define IDC_BRF_P_ACCESS_LIST 1271
// 预案状态条（工具栏下方居中）
#define IDC_BRF_P_PLAN_BANNER 1260
// 主持权被别人占用时的遮罩
#define IDC_BRF_P_LOCK_BG 1240
#define IDC_BRF_P_LOCK_TEXT 1241
#define IDC_BRF_P_TAKEOVER 1242
#define IDC_BRF_P_WATCH 1243

// 顶部工具栏 / 底部状态栏
#define BAR_H (0.042 * safezoneH)
#define BTN_Y (safezoneY + 0.005 * safezoneH)
#define BTN_H (0.032 * safezoneH)
#define BTN_W (0.0545 * safezoneW)
#define BTN_X(N) (safezoneX + 0.006 * safezoneW + (N) * 0.0585 * safezoneW)
#define STATUS_Y (safezoneY + safezoneH - BAR_H)

#define TXT_SIZE (0.024 * safezoneH)
#define TXT_SIZE_SMALL (0.021 * safezoneH)
