-- fremen only (loaded after monitors.lua): external monitor only, laptop panel off.
-- Lid close is ignored by logind: config/etc/systemd/logind.conf.d/ledot-lid.fremen.conf
hl.monitor({
    output   = "LVDS-1",
    disabled = true,
})

-- External monitor is a 5:4 panel behind an AlgolTek HDMI adapter. The adapter
-- reports 1024x768 as "preferred" and hides the real EDID, so pin the native mode:
-- 1920x1080 / 1440x900 stretch vertically, 1024x768 is low-res and oversized.
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1280x1024@60",
    position = "auto",
    scale    = "1",
})
