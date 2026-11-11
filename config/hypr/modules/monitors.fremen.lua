-- fremen only (loaded after monitors.lua): external monitor only, laptop panel off.
-- Lid close is ignored by logind: config/etc/systemd/logind.conf.d/ledot-lid.fremen.conf
hl.monitor({
    output   = "LVDS-1",
    disabled = true,
})
