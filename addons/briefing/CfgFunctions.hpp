class CfgFunctions {
    class BRF {
        tag = "BRF";
        class briefing {
            file = "\z\brf\addons\briefing\functions";
            // 初始化：快捷键、ZEN 菜单、公共变量监听、中途加入
            class init {postInit = 1;};
            class canPresent {};
            class isHost {};
            // 网络：事件分发 / 发送
            class onEvent {};
            class send {};
            class buildCache {};
            class purge {};
            // 主持端
            class openPresenter {};
            class presenterOnLoad {};
            class presenterOnUnload {};
            class presenterUpdate {};
            class presenterAction {};
            class presenterMessage {};
            class input {};
            class commit {};
            class simplify {};
            class smooth {};
            class segDist {};
            class triangulate {};
            class hitTest {};
            class syncView {};
            class pointer {};
            class undo {};
            class clear {};
            class toMarkers {};
            class musicPlayAll {};
            class musicStop {};
            // 观看端
            class openViewer {};
            class closeViewer {};
            class viewerOnLoad {};
            class viewerOnUnload {};
            class viewerUpdate {};
            class viewerIntro {};
            class viewerOutro {};
            // 测试
            class demo {};
            // 渲染（主持端和观看端共用）
            class render {};
            class renderIcon {};
            class renderRing {};
            class renderArea {};
            class renderPreview {};
            class renderOverlay {};
            class drawLine {};
            class drawPath {};
            class easeOutCubic {};
            class easeOutBack {};
        };
    };
};
