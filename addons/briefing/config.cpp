#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = "AC Briefing";
        author = "fksans";
        url = "https://github.com/fksans/ARMA3-AC";
        units[] = {};
        weapons[] = {};
        // drawLine 的线宽参数从 2.18 开始才有
        requiredVersion = 2.18;
        // ZEN 是可选的：只在运行时检测（见 fn_init），不要写进这里
        requiredAddons[] = {
            "cba_main",
            "A3_Ui_F"
        };
        version = QUOTE(MAJOR.MINOR.PATCH.BUILD);
        versionStr = QUOTE(MAJOR.MINOR.PATCH.BUILD);
        versionAr[] = {MAJOR, MINOR, PATCH, BUILD};
    };
};

#include "CfgFunctions.hpp"
#include "CfgIcons.hpp"
#include "gui.hpp"
