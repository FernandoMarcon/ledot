-- model.yazi — image preview for 3MF / STEP / STL / OBJ (mirrors ranger's scope.sh)
-- 3MF / FCStd: embedded thumbnail (unzip), else f3d render. STEP/STL/OBJ: f3d render.
-- FCStd has no f3d fallback: enable "Save thumbnail" in FreeCAD prefs (default on).

local SCRIPT = [[
f=$1 out=$2
ext=$(printf %s "${f##*.}" | tr A-Z a-z)
if [ "$ext" = 3mf ]; then
	for t in Auxiliaries/.thumbnails/thumbnail_middle.png Auxiliaries/.thumbnails/thumbnail_3mf.png \
	         Metadata/plate_1.png Metadata/thumbnail.png; do
		unzip -p -- "$f" "$t" > "$out" 2>/dev/null && [ -s "$out" ] && exit 0
	done
fi
if [ "$ext" = fcstd ]; then
	unzip -p -- "$f" thumbnails/Thumbnail.png > "$out" 2>/dev/null && [ -s "$out" ] && exit 0
	rm -f -- "$out"; exit 1
fi
command -v f3d >/dev/null || exit 127
up=+Z dir=-1,1,-0.8
[ "$ext" = obj ] && up=+Y dir=-1,-0.8,-1
png="$out.f3d.png"
timeout 20 f3d --no-config --output="$png" --resolution=800,600 --up="$up" \
	--camera-direction="$dir" --filename=false --grid=false -- "$f" >/dev/null 2>&1 \
	&& mv -f -- "$png" "$out"
]]

local M = {}

function M:peek(job)
	local start, cache = os.clock(), ya.file_cache(job)
	if not cache then
		return
	end
	local ok, err = self:preload(job)
	if not ok or err then
		return ya.preview_widget(job, err)
	end
	ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - os.clock()))
	local _, err = ya.image_show(cache, job.area)
	ya.preview_widget(job, err)
end

function M:seek() end

function M:preload(job)
	local cache = ya.file_cache(job)
	if not cache or fs.cha(cache) then
		return true
	end
	local status, err = Command("sh"):arg({ "-c", SCRIPT, "sh", tostring(job.file.path), tostring(cache) }):status()
	if not status then
		return true, Err("Failed to start `sh`, error: %s", err)
	elseif not status.success then
		return false, Err("No thumbnail / f3d render failed (code %s)", status.code)
	end
	return true
end

return M
