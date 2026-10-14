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

// ---- 主持端：工具栏按钮，基础 IDC + 工具序号（1-6） ----
#define IDC_BRF_P_TOOL 1200
#define IDC_BRF_P_COLOR 1210
#define IDC_BRF_P_ARROW 1211
#define IDC_BRF_P_UNDO 1212
#define IDC_BRF_P_CLEAR 1213
#define IDC_BRF_P_BGM 1214
#define IDC_BRF_P_SESSION 1215
#define IDC_BRF_P_MARKERS 1216
#define IDC_BRF_P_CLEAR_MARKERS 1217
#define IDC_BRF_P_CLOSE 1218
#define IDC_BRF_P_STATUS 1220
#define IDC_BRF_P_MESSAGE 1221
#define IDC_BRF_P_LABEL 1230
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
