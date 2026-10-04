if not luajava or not luajava.bindClass then error("当前环境不支持 luajava") end
if not activity then error("无法获取 activity 上下文") end

local function use(name) return luajava.bindClass(name) end

local File           = use("java.io.File")
local Handler        = use("android.os.Handler")
local Intent         = use("android.content.Intent")
local Uri            = use("android.net.Uri")
local View           = use("android.view.View")
local ViewGroup      = use("android.view.ViewGroup")
local Gravity        = use("android.view.Gravity")
local Typeface       = use("android.graphics.Typeface")
local Color          = use("android.graphics.Color")
local GradientDrawable = use("android.graphics.drawable.GradientDrawable")
local Build          = use("android.os.Build")
local Window         = use("android.view.Window")
local WindowManager  = use("android.view.WindowManager")
local WindowManagerLayoutParams = use("android.view.WindowManager$LayoutParams")
local PixelFormat    = use("android.graphics.PixelFormat")
local Settings       = use("android.provider.Settings")
local KeyEvent       = use("android.view.KeyEvent")

local TextView     = use("android.widget.TextView")
local EditText     = use("android.widget.EditText")
local LinearLayout = use("android.widget.LinearLayout")
local FrameLayout  = use("android.widget.FrameLayout")
local ScrollView   = use("android.widget.ScrollView")
local Switch       = use("android.widget.Switch")
local SeekBar      = use("android.widget.SeekBar")

local ImageView          = use("android.widget.ImageView")
local Bitmap             = use("android.graphics.Bitmap")
local BitmapFactory      = use("android.graphics.BitmapFactory")
local Canvas             = use("android.graphics.Canvas")
local Paint              = use("android.graphics.Paint")
local Path               = use("android.graphics.Path")
local Rect               = use("android.graphics.Rect")
local PorterDuff         = use("android.graphics.PorterDuff")
local PorterDuffXfermode = use("android.graphics.PorterDuffXfermode")

local dm = activity.getResources().getDisplayMetrics()
local function dp(v) return math.floor(v * dm.density + 0.5) end

pcall(function() activity.requestWindowFeature(Window.FEATURE_NO_TITLE) end)
pcall(function() local ab = activity.getSupportActionBar(); if ab then ab.hide() end end)
pcall(function() local ab = activity.getActionBar(); if ab then ab.hide() end end)
pcall(function()
  local window = activity.getWindow()
  window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
  window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
  window.setStatusBarColor(Color.TRANSPARENT)
  window.getDecorView().setSystemUiVisibility(256 + 1024 + 8192)
end)
pcall(function()
  local lp = activity.getWindow().getAttributes()
  lp.layoutInDisplayCutoutMode = 1
  activity.getWindow().setAttributes(lp)
end)

local function getStatusBarHeight()
  local res = activity.getResources()
  local id = res.getIdentifier("status_bar_height", "dimen", "android")
  if id > 0 then return res.getDimensionPixelSize(id) end
  return math.floor(24 * dm.density + 0.5)
end
local statusBarH = getStatusBarHeight()

pcall(function()
  if Build.VERSION.SDK_INT >= 23 then
    activity.requestPermissions({
      "android.permission.READ_EXTERNAL_STORAGE",
      "android.permission.WRITE_EXTERNAL_STORAGE",
    }, 100)
  end
end)

local CFG = {
  APP_NAME = "七叶", AUTHOR = "久峰", VERSION = "1.0.7",
  FIXED_KEY = "Qiye",
  AUTH_KEY = "Qiye",
  CARD_URL = "https://qun.qq.com/universal-share/share?ac=1&authKey=m%2BJhqbch%2FxA0RZPfk18UqHNBAxRaWObKMnWKSw0cmWdQJsdSmRK8fxgMm%2BFNUrrI&busi_data=eyJncm91cENvZGUiOiI1Nzk0NjM3NTAiLCJ0b2tlbiI6IkJ1QTkvSlo3TkZMNFNwblUrWmxOUXgzWFJndWhiZE8ydmpPdzRQbGpqVTNmWE5mMGZ6R1pVejVKZFZ2OFFBVTUiLCJ1aW4iOiIyNDY2MjA1NzYxIn0%3D&data=EcTRZ0DBlCSIyshPZ7GuU7sFJjb_891yx7WYnJ0RuMkq73VBNgYjsLvclKVFvqTNGhbV81dRvPJf5F9GcrgkGg&svctype=4&tempid=h5_group_info",
  NETDISK_URL = "https://1829261260.share.123pan.cn/123pan/zFgZjv-yJGj?pwd=jZP0/",
  QQ_URL = "https://qun.qq.com/universal-share/share?ac=1&authKey=FdSeOHT8KWyAjvNkcpyT28vC3vBlCWm8SRMPUW%2FmNVV%2BTUlkR6IPdZt3sscBmHYb&busi_data=eyJncm91cENvZGUiOiI1Nzk0NjM3NTAiLCJ0b2tlbiI6InluL2R3RitqMkNhYUJUTjRudFZpZEMzVll0RURSQ1hYT09aRzFwMWMyMVpLbzNJSGlSZ1B1TUVLYjZvMWF3RlkiLCJ1aW4iOiIyNDY2MjA1NzYxIn0%3D&data=MQRmjbIXlQQveJe6leSKMRivWTNEMuHwx_CAcfynnc8Hb6jNk2prwRQHn_uiUB4KObcaOgHjdDGxUVJnjRzkHQ&svctype=4&tempid=h5_group_info",
  QQ_NUM = "579463750",
  ANNOUNCEMENT_TITLE = "欢迎使用七叶",
  ANNOUNCEMENT_SUBTITLE = "版本 1.0.7",
  ANNOUNCEMENT_CONTENT =
    "感谢使用七叶 v1.0.7！\n\n本次更新：\n" ..
    "1. 修复已知 bug\n" ..
    "2. 增加显示水印\n\n"..
    "祝您使用愉快！",
}

local LOG_DIR  = "/storage/emulated/0/Qiye"
local LOG_FILE = LOG_DIR .. "/日志.txt"
local ERR_FILE = LOG_DIR .. "/错误报告.txt"
local AUTH_FILE = LOG_DIR .. "/auth.txt"

local function ensureLogDir()
  pcall(function()
    local d = File(LOG_DIR); if not d.exists() then d.mkdirs() end
  end)
end

local function writeLog(msg)
  ensureLogDir()
  pcall(function()
    local f = io.open(LOG_FILE, "a")
    if f then f:write("[" .. os.date("%H:%M:%S") .. "] " .. msg .. "\n"); f:close() end
  end)
end

local function resetLog()
  ensureLogDir()
  pcall(function()
    local f = io.open(LOG_FILE, "w")
    if f then
      f:write("══════════════════════════════════════════\n")
      f:write("  七叶 v" .. CFG.VERSION .. " 运行日志\n")
      f:write("  启动日期：" .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
      f:write("══════════════════════════════════════════\n\n")
      f:close()
    end
  end)
end

local function readLog()
  local t = ""
  pcall(function()
    local f = io.open(LOG_FILE, "r")
    if f then t = f:read("*a") or ""; f:close() end
  end)
  return t
end

local function writeErrorReport(level, context, err)
  ensureLogDir()
  pcall(function()
    local f = io.open(ERR_FILE, "a")
    if not f then return end
    f:write("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [" .. level .. "]\n")
    f:write("位置: " .. tostring(context) .. " | 错误: " .. tostring(err) .. "\n\n")
    f:close()
  end)
end

ensureLogDir()
resetLog()
writeLog("[BOOT] 七叶 v" .. CFG.VERSION .. " 启动")

local THEMES = {
  { key = "blue",   name = "经典蓝", primary = 0xFF4A90E2, bg = 0xFFF7F8FA,
    deco = {0xFF7FB3FF, 0xFF4A90E2, 0xFFB3D4FF}, rootGrad = {0xFF6EA8FF, 0xFF4A90E2},
    navActiveBg = 0x1A4A90E2, glow = 0xFFDCE8FF },
  { key = "green",  name = "薄荷绿", primary = 0xFF27AE60, bg = 0xFFF4FBF6,
    deco = {0xFF7FE0A8, 0xFF27AE60, 0xFFB3F0CE}, rootGrad = {0xFF5FD68F, 0xFF27AE60},
    navActiveBg = 0x1A27AE60, glow = 0xFFDAF5E5 },
  { key = "purple", name = "梦幻紫", primary = 0xFF8E44AD, bg = 0xFFFAF6FC,
    deco = {0xFFC28FE0, 0xFF8E44AD, 0xFFE4C8F0}, rootGrad = {0xFFA86FD1, 0xFF8E44AD},
    navActiveBg = 0x1A8E44AD, glow = 0xFFEDE4FF },
  { key = "orange", name = "暖橙", primary = 0xFFE67E22, bg = 0xFFFDF8F3,
    deco = {0xFFFFB870, 0xFFE67E22, 0xFFFFD9B3}, rootGrad = {0xFFFFA85F, 0xFFE67E22},
    navActiveBg = 0x1AE67E22, glow = 0xFFFFE8D0 },
  { key = "pink",   name = "樱花粉", primary = 0xFFE91E63, bg = 0xFFFDF5F8,
    deco = {0xFFFF8FB3, 0xFFE91E63, 0xFFFFC7DA}, rootGrad = {0xFFFF6E97, 0xFFE91E63},
    navActiveBg = 0x1AE91E63, glow = 0xFFFFE4EC },
}

local function findTheme(key)
  for _, v in ipairs(THEMES) do
    if v.key == key then return v end
  end
  return THEMES[1]
end

local C = {
  primary = THEMES[1].primary, bg = THEMES[1].bg, card = 0xFFFFFFFF,
  text = 0xFF1A1A1A, textSub = 0xFF8A8F99, border = 0xFFF0F1F3,
  danger = 0xFFE74C3C, warning = 0xFFF39C12, success = 0xFF27AE60,
  glass = 0xF2FFFFFF, glow = 0xFFDCE8FF,
  termBg = 0xFF0D1117, termHeader = 0xFF161B22, termBorder = 0xFF30363D,
  termText = 0xFF7EE787, termBlue = 0xFF58A6FF,
  termRed = 0xFFF85149, termYellow = 0xFFFFBD2E, termGreen = 0xFF27C93F,
  themeDeco = THEMES[1].deco, themeRootGrad = THEMES[1].rootGrad,
  navActiveBg = THEMES[1].navActiveBg,
}

local S = {
  logged = false,
  authorized = false,
  snowOn = false, snowNum = 50, snowSpeed = 50, theme = "blue",
}

local function loadAuthState()
  pcall(function()
    local f = io.open(AUTH_FILE, "r")
    if f then
      local content = f:read("*a") or ""
      f:close()
      if content:find("authorized=1") then S.authorized = true end
    end
  end)
end

local function saveAuthState()
  ensureLogDir()
  pcall(function()
    local f = io.open(AUTH_FILE, "w")
    if f then
      f:write("authorized=" .. (S.authorized and "1" or "0") .. "\n")
      f:write("time=" .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
      f:close()
    end
  end)
end

loadAuthState()

local function round(color, r, strokeColor, sw)
  local d = GradientDrawable()
  d.setShape(GradientDrawable.RECTANGLE)
  d.setColor(color)
  d.setCornerRadius(dp(r))
  if strokeColor then d.setStroke(dp(sw or 1), strokeColor) end
  return d
end

local function roundRadii(color, r, strokeColor, sw)
  local d = GradientDrawable()
  d.setShape(GradientDrawable.RECTANGLE)
  d.setColor(color)
  d.setCornerRadii({dp(r[1]), dp(r[1]), dp(r[2]), dp(r[2]),
                    dp(r[3]), dp(r[3]), dp(r[4]), dp(r[4])})
  if strokeColor then d.setStroke(dp(sw or 1), strokeColor) end
  return d
end

local function makeGlassBg(radius, strokeColor)
  local gd = GradientDrawable(
    GradientDrawable.Orientation.TOP_BOTTOM,
    {0x66FFFFFF, 0x33FFFFFF, 0x40FFFFFF, 0x59FFFFFF})
  gd.setShape(GradientDrawable.RECTANGLE)
  gd.setCornerRadius(dp(radius))
  gd.setStroke(dp(1.5), strokeColor)
  return gd
end

local function removeFromParent(v)
  if not v then return end
  pcall(function()
    local p = v.getParent()
    if p then p.removeView(v) end
  end)
end

local function mkText(txt, size, color, bold)
  local t = TextView(activity)
  t.setText(txt)
  t.setTextSize(size or 14)
  t.setTextColor(color or C.text)
  if bold then t.setTypeface(Typeface.DEFAULT_BOLD) end
  return t
end

local function mkMono(txt, size, color)
  local t = TextView(activity)
  t.setText(txt)
  t.setTextSize(size or 11)
  t.setTextColor(color or C.termText)
  t.setTypeface(Typeface.MONOSPACE)
  return t
end

local function toBool(v)
  if v == nil then return false end
  if v == true then return true end
  if v == false then return false end
  return (v == true)
end

local GLOBAL_HANDLER = Handler()
local ANIM_INTERVAL = 16

local function easeOut(t)
  local a = 1 - t
  return 1 - a * a * a
end

local function animValue(from, to, duration, onUpdate, onEnd)
  local totalSteps = math.max(1, math.floor(duration / ANIM_INTERVAL))
  local step = 0
  local function tick()
    step = step + 1
    local t = step / totalSteps
    if t > 1 then t = 1 end
    local e = easeOut(t)
    local v = from + (to - from) * e
    if onUpdate then onUpdate(v, e) end
    if step < totalSteps then
      GLOBAL_HANDLER.postDelayed(tick, ANIM_INTERVAL)
    else
      if onEnd then onEnd() end
    end
  end
  GLOBAL_HANDLER.postDelayed(tick, ANIM_INTERVAL)
end

local function animatePageIn(view)
  view.setAlpha(0)
  view.setTranslationY(dp(28))
  animValue(0, 1, 260,
    function(v)
      view.setAlpha(v)
      view.setTranslationY(dp(28) * (1 - v))
    end)
end

local function animateDialogIn(overlay, card)
  overlay.setBackgroundColor(0x00000000)
  card.setScaleX(0.85)
  card.setScaleY(0.85)
  card.setAlpha(0)
  animValue(0, 1, 240,
    function(v)
      local maskAlpha = math.floor(v * 0x88)
      overlay.setBackgroundColor(maskAlpha * 0x1000000)
      local s = 0.85 + 0.15 * v
      card.setScaleX(s)
      card.setScaleY(s)
      card.setAlpha(v)
    end)
end

local function animateDialogOut(overlay, card, onEnd)
  animValue(1, 0, 140,
    function(v)
      local maskAlpha = math.floor(v * 0x88)
      overlay.setBackgroundColor(maskAlpha * 0x1000000)
      local s = 0.9 + 0.1 * v
      card.setScaleX(s)
      card.setScaleY(s)
      card.setAlpha(v)
    end,
    function()
      removeFromParent(overlay)
      if onEnd then onEnd() end
    end)
end

local function animateNotifIn(view)
  view.setTranslationX(dp(280))
  view.setAlpha(0)
  animValue(0, 1, 260,
    function(v)
      view.setTranslationX(dp(280) * (1 - v))
      view.setAlpha(v)
    end)
end

local function animateNotifOut(view, onEnd)
  animValue(1, 0, 180,
    function(v)
      view.setTranslationX(dp(280) * (1 - v))
      view.setAlpha(v)
    end,
    function()
      removeFromParent(view)
      if onEnd then onEnd() end
    end)
end

local function animateTap(view)
  view.setScaleX(0.92)
  view.setScaleY(0.92)
  animValue(0.92, 1, 140,
    function(v)
      view.setScaleX(v)
      view.setScaleY(v)
    end)
end

local activeNotif = nil
local notifToken = 0

local function dismissNotif()
  if activeNotif then
    local v = activeNotif
    activeNotif = nil
    animateNotifOut(v)
  end
end

local function showNotif(text)
  notifToken = notifToken + 1
  local myToken = notifToken
  if activeNotif then
    local old = activeNotif
    activeNotif = nil
    removeFromParent(old)
  end

  local wrap = LinearLayout(activity)
  wrap.setOrientation(LinearLayout.VERTICAL)
  wrap.setBackground(round(C.card, 14, C.border, 1))
  wrap.setElevation(dp(5))
  wrap.setPadding(dp(14), dp(10), dp(14), 0)
  wrap.setClickable(true)

  local msg = mkText(text, 13, C.text, true)
  wrap.addView(msg)

  local barWrap = FrameLayout(activity)
  local bwp = LinearLayout.LayoutParams(-1, dp(3))
  bwp.topMargin = dp(10)
  barWrap.setLayoutParams(bwp)

  local track = View(activity)
  track.setLayoutParams(FrameLayout.LayoutParams(-1, dp(3)))
  track.setBackground(round(0x14000000, 2))
  barWrap.addView(track)

  local bar = View(activity)
  bar.setLayoutParams(FrameLayout.LayoutParams(-1, dp(3)))
  bar.setBackground(round(C.primary, 2))
  bar.setPivotX(0)
  bar.setPivotY(dp(1.5))
  barWrap.addView(bar)
  wrap.addView(barWrap)

  local lp = FrameLayout.LayoutParams(dp(240), -2)
  lp.gravity = Gravity.TOP + Gravity.RIGHT
  lp.topMargin = statusBarH + dp(12)
  lp.rightMargin = dp(14)
  wrap.setLayoutParams(lp)

  activity.getWindow().getDecorView().addView(wrap)
  activeNotif = wrap

  wrap.setOnClickListener(function()
    if myToken == notifToken then dismissNotif() end
  end)

  animateNotifIn(wrap)

  local step = 0
  local function progressTick()
    if myToken ~= notifToken then return end
    step = step + 1
    local ratio = 1 - step / 60
    if ratio <= 0 then dismissNotif(); return end
    bar.setScaleX(ratio)
    GLOBAL_HANDLER.postDelayed(progressTick, 40)
  end
  GLOBAL_HANDLER.postDelayed(progressTick, 40)
end

local function toast(s) showNotif(s) end

local function openUrl(url)
  local ok, err = pcall(function()
    local i = Intent(Intent.ACTION_VIEW, Uri.parse(url))
    i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    activity.startActivity(i)
  end)
  if not ok then
    writeErrorReport("WARN", "openUrl", err)
    toast("无法打开链接")
  end
  return ok
end

local function showDialog(opts)
  local closable = (opts.closableByOutside ~= false)
  local overlay = FrameLayout(activity)
  overlay.setBackgroundColor(0x00000000)
  overlay.setClickable(true)
  local card = LinearLayout(activity)
  card.setOrientation(LinearLayout.VERTICAL)
  card.setPadding(dp(22), dp(22), dp(22), dp(18))
  card.setBackground(round(C.card, 20, C.border, 1))
  card.setElevation(dp(12))
  card.setClickable(true)
  local lp = FrameLayout.LayoutParams(dp(300), -2)
  lp.gravity = Gravity.CENTER
  card.setLayoutParams(lp)
  if opts.title then card.addView(mkText(opts.title, 18, C.text, true)) end
  if opts.content then
    local c = mkText(opts.content, 14, C.textSub)
    local clp = LinearLayout.LayoutParams(-1, -2)
    clp.topMargin = dp(12)
    c.setLayoutParams(clp)
    c.setLineSpacing(0, 1.3)
    card.addView(c)
  end
  local btnRow = LinearLayout(activity)
  btnRow.setOrientation(LinearLayout.HORIZONTAL)
  btnRow.setGravity(Gravity.END)
  local blp = LinearLayout.LayoutParams(-1, -2)
  blp.topMargin = dp(18)
  btnRow.setLayoutParams(blp)
  local function mkBtn(text, isPrimary, cb)
    local b = TextView(activity)
    b.setText(text)
    b.setTextSize(14)
    b.setPadding(dp(20), dp(10), dp(20), dp(10))
    if isPrimary then
      b.setTextColor(0xFFFFFFFF)
      b.setBackground(round(C.primary, 12))
    else
      b.setTextColor(C.textSub)
      b.setBackground(round(0x00000000, 12, C.border, 1))
    end
    b.setGravity(Gravity.CENTER)
    b.setClickable(true)
    b.setOnClickListener(function()
      animateTap(b)
      GLOBAL_HANDLER.postDelayed(function() cb() end, 60)
    end)
    return b
  end
  local function closeDialog(cb) animateDialogOut(overlay, card, cb) end
  if opts.cancelText ~= nil then
    local cancel = mkBtn(opts.cancelText or "取消", false, function()
      if opts.onCancel then opts.onCancel() end
      closeDialog()
    end)
    local clp2 = LinearLayout.LayoutParams(-2, -2)
    clp2.rightMargin = dp(10)
    btnRow.addView(cancel, clp2)
  end
  local okBtn = mkBtn(opts.okText or "确定", true, function()
    if opts.onOk then opts.onOk() end
    if opts.autoClose ~= false then closeDialog() end
  end)
  btnRow.addView(okBtn)
  card.addView(btnRow)
  overlay.addView(card)
  if closable then
    overlay.setOnClickListener(function() closeDialog() end)
  end
  activity.getWindow().getDecorView().addView(overlay, ViewGroup.LayoutParams(-1, -1))
  animateDialogIn(overlay, card)
  return overlay
end

local function showAnnouncement()
  local overlay = FrameLayout(activity)
  overlay.setBackgroundColor(0x00000000)
  overlay.setClickable(true)
  local card = LinearLayout(activity)
  card.setOrientation(LinearLayout.VERTICAL)
  card.setBackground(round(C.card, 22, C.border, 1))
  card.setElevation(dp(14))
  card.setClickable(true)
  local clp = FrameLayout.LayoutParams(dp(310), -2)
  clp.gravity = Gravity.CENTER
  card.setLayoutParams(clp)
  local topBand = LinearLayout(activity)
  topBand.setOrientation(LinearLayout.HORIZONTAL)
  topBand.setGravity(Gravity.CENTER_VERTICAL)
  topBand.setPadding(dp(20), dp(18), dp(20), dp(18))
  local bandD = GradientDrawable(GradientDrawable.Orientation.TL_BR, C.themeDeco)
  bandD.setCornerRadii({dp(22), dp(22), dp(22), dp(22), 0, 0, 0, 0})
  topBand.setBackground(bandD)
  local titleWrap = LinearLayout(activity)
  titleWrap.setOrientation(LinearLayout.VERTICAL)
  titleWrap.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
  titleWrap.addView(mkText(CFG.ANNOUNCEMENT_TITLE, 16, 0xFFFFFFFF, true))
  titleWrap.addView(mkText(CFG.ANNOUNCEMENT_SUBTITLE, 11, 0xCCFFFFFF))
  topBand.addView(titleWrap)
  card.addView(topBand)
  local body = LinearLayout(activity)
  body.setOrientation(LinearLayout.VERTICAL)
  body.setPadding(dp(22), dp(18), dp(22), dp(6))
  local content = mkText(CFG.ANNOUNCEMENT_CONTENT, 14, C.text)
  content.setLineSpacing(dp(3), 1.4)
  body.addView(content)
  card.addView(body)
  local btnWrap = LinearLayout(activity)
  btnWrap.setOrientation(LinearLayout.HORIZONTAL)
  btnWrap.setGravity(Gravity.CENTER)
  btnWrap.setPadding(dp(22), dp(10), dp(22), dp(20))
  card.addView(btnWrap)
  local okBtn = TextView(activity)
  okBtn.setText("我知道了")
  okBtn.setTextSize(15)
  okBtn.setTextColor(0xFFFFFFFF)
  okBtn.setTypeface(Typeface.DEFAULT_BOLD)
  okBtn.setGravity(Gravity.CENTER)
  okBtn.setBackground(round(C.primary, 14))
  okBtn.setPadding(0, dp(13), 0, dp(13))
  okBtn.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
  okBtn.setClickable(true)
  okBtn.setOnClickListener(function()
    animateTap(okBtn)
    GLOBAL_HANDLER.postDelayed(function()
      writeLog("[ANNOUNCE] 用户已确认公告")
      animateDialogOut(overlay, card)
    end, 60)
  end)
  btnWrap.addView(okBtn)
  overlay.addView(card)
  activity.getWindow().getDecorView().addView(overlay, ViewGroup.LayoutParams(-1, -1))
  animateDialogIn(overlay, card)
end
-- ============================================================
--  ★获取真实屏幕尺寸（适配横屏）
-- ============================================================
local screenRealW, screenRealH = dm.widthPixels, dm.heightPixels
pcall(function()
  local Point = use("android.graphics.Point")
  local display = activity.getWindowManager().getDefaultDisplay()
  local p = Point()
  display.getRealSize(p)
  screenRealW = p.x
  screenRealH = p.y
end)

-- ============================================================
--  悬浮窗权限
-- ============================================================
local function canDrawOverlays()
  if Build.VERSION.SDK_INT < 23 then return true end
  local ok, result = pcall(function()
    return Settings.canDrawOverlays(activity)
  end)
  return ok and result
end

local function requestOverlayPermission()
  pcall(function()
    local i = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
    i.setData(Uri.parse("package:" .. activity.getPackageName()))
    i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    activity.startActivity(i)
  end)
  toast("请打开悬浮窗权限")
end

-- ============================================================
--  ★独立视图：灵动岛 + 面板 + 水印
-- ============================================================
local islandView = nil
local panelView = nil
local watermarkView = nil   -- ★ 新增：左下角水印
local overlayWM = nil

local appContext = nil
pcall(function() appContext = activity.getApplicationContext() end)
if not appContext then appContext = activity end

local function removeIslandView()
  if islandView and overlayWM then
    pcall(function() overlayWM.removeView(islandView) end)
  end
  islandView = nil
end

local function removePanelView()
  if panelView and overlayWM then
    pcall(function() overlayWM.removeView(panelView) end)
  end
  panelView = nil
end

-- ★ 新增：移除水印视图
local function removeWatermarkView()
  if watermarkView and overlayWM then
    pcall(function() overlayWM.removeView(watermarkView) end)
  end
  watermarkView = nil
end

local function removeOverlay()
  removeWatermarkView()   -- ★ 新增
  removePanelView()
  removeIslandView()
end

-- ============================================================
--  Tab 页内容
-- ============================================================
local function buildTabPage(idx)
  local page = ScrollView(activity)
  page.setBackgroundColor(0x00000000)
  page.setVerticalScrollBarEnabled(false)

  local inner = LinearLayout(activity)
  inner.setOrientation(LinearLayout.VERTICAL)
  inner.setPadding(dp(14), dp(14), dp(14), dp(14))
  inner.setBackgroundColor(0x00000000)

  if idx == 1 then
    local title = mkText("首页", 15, C.text, true)
    inner.addView(title)

    local sub = mkText("七叶 · 运行中", 11, C.textSub)
    local slp = LinearLayout.LayoutParams(-1, -2); slp.topMargin = dp(4)
    sub.setLayoutParams(slp)
    inner.addView(sub)

    local function infoCard(label, value)
      local card = LinearLayout(activity)
      card.setOrientation(LinearLayout.HORIZONTAL)
      card.setGravity(Gravity.CENTER_VERTICAL)
      card.setPadding(dp(10), dp(9), dp(10), dp(9))
      card.setBackground(round(0x14000000, 10))
      local clp = LinearLayout.LayoutParams(-1, -2); clp.bottomMargin = dp(6)
      card.setLayoutParams(clp)

      local lbl = mkText(label, 11, C.textSub)
      lbl.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
      card.addView(lbl)

      local val = mkText(value, 11, C.primary, true)
      card.addView(val)
      return card
    end

    inner.addView(infoCard("版本", CFG.VERSION))
    inner.addView(infoCard("状态", "运行中"))
    inner.addView(infoCard("悬浮权限",
      canDrawOverlays() and "已开启" or "未开启"))
    inner.addView(infoCard("授权状态",
      S.authorized and "已授权" or "未授权"))

  elseif idx == 2 then
    local title = mkText("页面 2", 15, C.text, true)
    inner.addView(title)
    local sub = mkText("（七叶）", 11, C.textSub)
    local slp = LinearLayout.LayoutParams(-1, -2); slp.topMargin = dp(6)
    sub.setLayoutParams(slp)
    inner.addView(sub)

  elseif idx == 3 then
    local title = mkText("页面 3", 15, C.text, true)
    inner.addView(title)
    local sub = mkText("（七叶）", 11, C.textSub)
    local slp = LinearLayout.LayoutParams(-1, -2); slp.topMargin = dp(6)
    sub.setLayoutParams(slp)
    inner.addView(sub)

  elseif idx == 4 then
    local title = mkText("页面 4", 15, C.text, true)
    inner.addView(title)
    local sub = mkText("（七叶）", 11, C.textSub)
    local slp = LinearLayout.LayoutParams(-1, -2); slp.topMargin = dp(6)
    sub.setLayoutParams(slp)
    inner.addView(sub)
  end

  page.addView(inner, FrameLayout.LayoutParams(-1, -2))
  return page
end

-- ============================================================
--  灵动岛（固定顶部）
-- ============================================================
local function buildIslandContent()
  local island = LinearLayout(activity)
  island.setOrientation(LinearLayout.HORIZONTAL)
  island.setGravity(Gravity.CENTER_VERTICAL)
  island.setPadding(dp(14), dp(7), dp(14), dp(7))

  local gd = GradientDrawable()
  gd.setShape(GradientDrawable.RECTANGLE)
  gd.setColor(0xFF000000)
  gd.setCornerRadius(dp(22))
  island.setBackground(gd)

  local dot = View(activity)
  dot.setClickable(false)
  dot.setFocusable(false)
  local dotLp = LinearLayout.LayoutParams(dp(7), dp(7))
  dotLp.rightMargin = dp(8)
  dot.setLayoutParams(dotLp)
  dot.setBackground(round(C.success, 4))
  island.addView(dot)

  local label = mkText("七叶正在守护", 12, 0xFFFFFFFF, true)
  label.setClickable(false)
  label.setFocusable(false)
  island.addView(label)

  return island, dot
end

-- ============================================================
--  ★ 左下角水印（作者久峰）
-- ============================================================
local function buildWatermarkContent()
  local wm = TextView(activity)
  wm.setText("作者久峰")
  wm.setTextSize(18)
  wm.setTextColor(0xFFFFFFFF)
  wm.setTypeface(Typeface.DEFAULT_BOLD)
  wm.setGravity(Gravity.CENTER)
  wm.setPadding(dp(22), dp(12), dp(22), dp(12))
  wm.setClickable(false)
  wm.setFocusable(false)
  wm.setFocusableInTouchMode(false)

  -- 半透明黑底 + 白边框，任何界面都清晰可见
  local gd = GradientDrawable()
  gd.setShape(GradientDrawable.RECTANGLE)
  gd.setColor(0xCC000000)
  gd.setCornerRadius(dp(16))
  gd.setStroke(dp(2), 0xFFFFFFFF)
  wm.setBackground(gd)
  wm.setElevation(dp(8))

  return wm
end

-- ============================================================
--  面板（可拖动）
-- ============================================================
local function buildPanelContent()
  -- 正方形边长：屏幕短边的 78%，320~420dp
  local screenMinPx = math.min(screenRealW, screenRealH)
  local screenMinDp = math.floor(screenMinPx / dm.density)
  local sideDp = math.floor(screenMinDp * 0.78)
  if sideDp < 320 then sideDp = 320 end
  if sideDp > 420 then sideDp = 420 end

  local panelW = dp(sideDp)
  local panelH = dp(sideDp)

  local panel = LinearLayout(activity)
  panel.setOrientation(LinearLayout.VERTICAL)
  panel.setPadding(dp(12), dp(10), dp(12), dp(12))

  local pgd = GradientDrawable(
    GradientDrawable.Orientation.TOP_BOTTOM,
    {0xF2FFFFFF, 0xE6FFFFFF, 0xF0FFFFFF})
  pgd.setShape(GradientDrawable.RECTANGLE)
  pgd.setCornerRadius(dp(22))
  pgd.setStroke(dp(1.5), 0xCCFFFFFF)
  panel.setBackground(pgd)

  -- ★ 顶部拖动条（用于拖拽面板）
  local statusRow = LinearLayout(activity)
  statusRow.setOrientation(LinearLayout.HORIZONTAL)
  statusRow.setGravity(Gravity.CENTER_VERTICAL)
  statusRow.setPadding(dp(6), dp(6), dp(6), dp(10))

  local dotInd = View(activity)
  dotInd.setClickable(false)
  dotInd.setLayoutParams(LinearLayout.LayoutParams(dp(8), dp(8)))
  dotInd.setBackground(round(C.success, 4))
  statusRow.addView(dotInd)

  local statusTxt = mkText("七叶注入", 13, C.text, true)
  statusTxt.setClickable(false)
  statusTxt.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
  statusRow.addView(statusTxt)

  local collapseBtn = TextView(activity)
  collapseBtn.setText("▴")
  collapseBtn.setTextSize(14)
  collapseBtn.setTextColor(C.textSub)
  collapseBtn.setGravity(Gravity.CENTER)
  collapseBtn.setBackground(round(0x00000000, 8))
  collapseBtn.setPadding(dp(10), dp(3), dp(10), dp(3))
  collapseBtn.setClickable(true)
  statusRow.addView(collapseBtn)

  panel.addView(statusRow)

  local div1 = View(activity)
  div1.setLayoutParams(LinearLayout.LayoutParams(-1, dp(1)))
  div1.setBackground(round(C.border, 0))
  panel.addView(div1)

  -- 主体：左 Tab + 右内容
  local bodyRow = LinearLayout(activity)
  bodyRow.setOrientation(LinearLayout.HORIZONTAL)
  local brlp = LinearLayout.LayoutParams(-1, 0, 1)
  brlp.topMargin = dp(8)
  bodyRow.setLayoutParams(brlp)

  local tabBar = LinearLayout(activity)
  tabBar.setOrientation(LinearLayout.VERTICAL)
  tabBar.setPadding(dp(4), dp(6), dp(4), dp(6))
  tabBar.setLayoutParams(LinearLayout.LayoutParams(dp(66), -1))

  local contentArea = FrameLayout(activity)
  contentArea.setLayoutParams(LinearLayout.LayoutParams(0, -1, 1))
  contentArea.setBackground(round(0x08000000, 12))

  local tabNames = {"首页", "页面2", "页面3", "页面4"}
  local tabs = {}
  local currentTab = 1

  local function switchTab(idx)
    currentTab = idx
    for i, tab in ipairs(tabs) do
      if i == idx then
        tab.setBackground(round(C.primary, 10))
        tab.setTextColor(0xFFFFFFFF)
      else
        tab.setBackgroundColor(0x00000000)
        tab.setTextColor(C.textSub)
      end
    end
    contentArea.removeAllViews()
    local page = buildTabPage(idx)
    if page then
      contentArea.addView(page, FrameLayout.LayoutParams(-1, -1))
    end
  end

  for i, name in ipairs(tabNames) do
    local tab = TextView(activity)
    tab.setText(name)
    tab.setTextSize(12)
    tab.setGravity(Gravity.CENTER)
    tab.setPadding(dp(5), dp(10), dp(5), dp(10))
    tab.setBackgroundColor(0x00000000)
    tab.setTextColor(C.textSub)
    tab.setClickable(true)
    local tlp = LinearLayout.LayoutParams(-1, -2)
    tlp.bottomMargin = dp(6)
    tab.setLayoutParams(tlp)
    tab.setOnClickListener(function()
      if currentTab == i then return end
      switchTab(i)
    end)
    tabBar.addView(tab)
    tabs[i] = tab
  end

  bodyRow.addView(tabBar)
  bodyRow.addView(contentArea)
  panel.addView(bodyRow)

  -- 底部退出按钮
  local exitBtn = TextView(activity)
  exitBtn.setText("退出悬浮窗")
  exitBtn.setTextSize(13)
  exitBtn.setTextColor(0xFFFFFFFF)
  exitBtn.setTypeface(Typeface.DEFAULT_BOLD)
  exitBtn.setGravity(Gravity.CENTER)
  exitBtn.setBackground(round(0xFFE74C3C, 10))
  exitBtn.setPadding(dp(18), dp(10), dp(18), dp(10))
  exitBtn.setClickable(true)
  local elp = LinearLayout.LayoutParams(-1, -2); elp.topMargin = dp(10)
  exitBtn.setLayoutParams(elp)
  panel.addView(exitBtn)

  switchTab(1)

  return panel, collapseBtn, exitBtn, statusRow, panelW, panelH
end

-- ============================================================
--  ★显示悬浮窗（灵动岛 + 面板 + 左下角水印）
-- ============================================================
local function showIslandOverlay()
  if not S.authorized then
    showDialog({
      title = "未激活独家授权",
      content = "启动灵动岛悬浮窗需要先完成独家授权。\n\n请前往「配置」页点击「独家授权」，输入授权卡密后即可使用。",
      okText = "去授权",
      cancelText = "取消",
      onOk = function()
        if currentKey ~= "config" then
          switchPage("config")
        end
      end,
    })
    return
  end

  if not canDrawOverlays() then
    showDialog({
      title = "需要悬浮窗权限",
      content = "七叶需要「显示在其他应用上层」权限。\n\n点击「去开启」跳转到系统设置。",
      okText = "去开启",
      cancelText = "取消",
      onOk = function() requestOverlayPermission() end,
    })
    return
  end

  removeOverlay()

  local ok, wm = pcall(function()
    return appContext.getSystemService("window")
  end)
  if not ok or not wm then
    toast("无法获取 WindowManager")
    return
  end
  overlayWM = wm

  local type
  if Build.VERSION.SDK_INT >= 26 then
    type = 2038
  else
    type = 2002
  end
  local flags = 0x00000008 + 0x00000200 + 0x00000020

  -- ============================================================
  --  ① 灵动岛（固定顶部居中，不可拖动）
  -- ============================================================
  local island, dot = buildIslandContent()
  islandView = island

  local islandLp = WindowManagerLayoutParams(-2, -2, type, flags, PixelFormat.TRANSLUCENT)
  islandLp.gravity = Gravity.TOP + Gravity.CENTER_HORIZONTAL
  islandLp.x = 0
  islandLp.y = dp(6)
  islandLp.format = PixelFormat.TRANSLUCENT

  local ok1, err1 = pcall(function()
    wm.addView(islandView, islandLp)
  end)
  if not ok1 then
    toast("灵动岛创建失败")
    writeErrorReport("ERROR", "addIsland", err1)
    return
  end

  -- ============================================================
  --  ② ★ 左下角水印「作者久峰」（全屏浮层，横竖屏都在左下角）
  -- ============================================================
  local watermark = buildWatermarkContent()
  watermarkView = watermark

  -- flags 追加 0x10（FLAG_NOT_TOUCHABLE）→ 触摸穿透，不挡底层操作
  local wmFlags = flags + 0x00000010
  local wmLp = WindowManagerLayoutParams(-2, -2, type, wmFlags, PixelFormat.TRANSLUCENT)
  wmLp.gravity = Gravity.BOTTOM + Gravity.LEFT   -- ★ 屏幕左下角
  wmLp.x = dp(18)
  wmLp.y = dp(18)
  wmLp.format = PixelFormat.TRANSLUCENT

  local okW, errW = pcall(function()
    wm.addView(watermarkView, wmLp)
  end)
  if not okW then
    watermarkView = nil
    writeErrorReport("ERROR", "addWatermark", errW)
    toast("水印创建失败")
  else
    writeLog("[WATERMARK] 水印已创建 @ 屏幕左下角")
  end

  -- ============================================================
  --  ③ 面板（独立视图，可拖动）
  -- ============================================================
  local panel, collapseBtn, exitBtn, dragArea, panelW, panelH = buildPanelContent()

  local function hidePanel()
    if panelView then
      pcall(function() wm.removeView(panelView) end)
      panelView = nil
      writeLog("[OVERLAY] 面板已隐藏")
    end
  end

  local function showPanel()
    if panelView then return end
    panelView = panel

    local panelLp = WindowManagerLayoutParams(panelW, panelH, type, flags, PixelFormat.TRANSLUCENT)
    panelLp.gravity = Gravity.TOP + Gravity.CENTER_HORIZONTAL
    panelLp.x = 0
    panelLp.y = dp(70)
    panelLp.format = PixelFormat.TRANSLUCENT

    local ok2, err2 = pcall(function()
      wm.addView(panelView, panelLp)
    end)
    if not ok2 then
      toast("面板创建失败")
      writeErrorReport("ERROR", "addPanel", err2)
      panelView = nil
      return
    end

    -- ★ 拖动：按住顶部拖动条移动面板
    local dragStartX, dragStartY = 0, 0
    local lpStartX, lpStartY = 0, 0
    local moved = false

    dragArea.setOnTouchListener(function(v, event)
      local action = event.getAction()
      if action == 0 then
        dragStartX = event.getRawX()
        dragStartY = event.getRawY()
        lpStartX = panelLp.x
        lpStartY = panelLp.y
        moved = false
        return true
      elseif action == 2 then
        local dx = event.getRawX() - dragStartX
        local dy = event.getRawY() - dragStartY
        if math.abs(dx) > dp(4) or math.abs(dy) > dp(4) then
          moved = true
        end
        if moved then
          panelLp.x = lpStartX + math.floor(dx)
          panelLp.y = lpStartY + math.floor(dy)
          local sw = screenRealW
          local sh = screenRealH
          if panelLp.x < -panelW + dp(60) then panelLp.x = -panelW + dp(60) end
          if panelLp.y < 0 then panelLp.y = 0 end
          if panelLp.x > sw - dp(60) then panelLp.x = sw - dp(60) end
          if panelLp.y > sh - dp(40) then panelLp.y = sh - dp(40) end
          pcall(function() wm.updateViewLayout(panelView, panelLp) end)
        end
        return true
      elseif action == 1 or action == 3 then
        return true
      end
      return false
    end)

    -- 收起按钮 → 只隐藏面板，灵动岛和水印保留
    collapseBtn.setOnClickListener(function()
      animateTap(collapseBtn)
      GLOBAL_HANDLER.postDelayed(function()
        hidePanel()
      end, 80)
    end)

    -- 退出按钮 → 关闭全部（灵动岛 + 水印 + 面板）
    exitBtn.setOnClickListener(function()
      animateTap(exitBtn)
      GLOBAL_HANDLER.postDelayed(function()
        removeOverlay()
        toast("已退出悬浮窗")
      end, 80)
    end)

    writeLog("[OVERLAY] 面板已显示")
  end

  -- ============================================================
  --  ④ 点击灵动岛 → 开/关面板
  -- ============================================================
  islandView.setClickable(true)
  islandView.setOnClickListener(function()
    animateTap(islandView)
    GLOBAL_HANDLER.postDelayed(function()
      if panelView then
        hidePanel()
      else
        showPanel()
      end
    end, 80)
  end)

  -- 呼吸灯
  local dotAlpha = 1.0
  local dotDir = -1
  local dotActive = true
  local function dotTick()
    if not dotActive or not islandView then return end
    dotAlpha = dotAlpha + dotDir * 0.08
    if dotAlpha <= 0.4 then
      dotAlpha = 0.4; dotDir = 1
    elseif dotAlpha >= 1.0 then
      dotAlpha = 1.0; dotDir = -1
    end
    pcall(function() dot.setAlpha(dotAlpha) end)
    GLOBAL_HANDLER.postDelayed(dotTick, 60)
  end
  GLOBAL_HANDLER.postDelayed(dotTick, 60)

  writeLog("[OVERLAY] 灵动岛已创建 @ 屏幕 " .. screenRealW .. "x" .. screenRealH)
  toast("灵动岛已开启 · 点击展开面板")
end

-- ============================================================
--  方案选择弹窗
-- ============================================================
local function showPlanSelector()
  local overlay = FrameLayout(activity)
  overlay.setBackgroundColor(0x00000000)
  overlay.setClickable(true)

  local card = LinearLayout(activity)
  card.setOrientation(LinearLayout.VERTICAL)
  card.setPadding(dp(20), dp(22), dp(20), dp(20))
  local cgd = GradientDrawable(
    GradientDrawable.Orientation.TOP_BOTTOM,
    {0xFFFFFFFF, 0xFAFFFFFF})
  cgd.setShape(GradientDrawable.RECTANGLE)
  cgd.setCornerRadius(dp(22))
  cgd.setStroke(dp(1), 0xB0FFFFFF)
  card.setBackground(cgd)
  card.setElevation(dp(16))
  card.setClickable(true)
  local clp = FrameLayout.LayoutParams(dp(320), -2)
  clp.gravity = Gravity.CENTER
  card.setLayoutParams(clp)

  local titleWrap = LinearLayout(activity)
  titleWrap.setOrientation(LinearLayout.VERTICAL)
  titleWrap.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
  titleWrap.addView(mkText("选择注入方案", 17, C.text, true))
  titleWrap.addView(mkText("请选择一种注入方案", 11, C.textSub))
  card.addView(titleWrap)

  local authTip = mkText(
    S.authorized and "已激活独家授权" or "未激活独家授权（需先授权）",
    11,
    S.authorized and C.success or C.danger)
  local atlp = LinearLayout.LayoutParams(-1, -2); atlp.topMargin = dp(8)
  authTip.setLayoutParams(atlp)
  card.addView(authTip)

  local permOk = canDrawOverlays()
  local permTip = mkText(
    permOk and "悬浮窗权限已开启" or "悬浮窗权限未开启（点击开启）",
    11,
    permOk and C.success or C.warning)
  local ptlp = LinearLayout.LayoutParams(-1, -2); ptlp.topMargin = dp(4)
  permTip.setLayoutParams(ptlp)
  permTip.setClickable(true)
  permTip.setOnClickListener(function()
    if not canDrawOverlays() then requestOverlayPermission() end
  end)
  card.addView(permTip)

  local function makePlanCard(planName, planDesc, planColor1, planColor2)
    local planCard = LinearLayout(activity)
    planCard.setOrientation(LinearLayout.HORIZONTAL)
    planCard.setGravity(Gravity.CENTER_VERTICAL)
    planCard.setPadding(dp(16), dp(16), dp(16), dp(16))

    local pcgd = GradientDrawable(
      GradientDrawable.Orientation.TOP_BOTTOM,
      {0xF0FFFFFF, 0xE6FFFFFF})
    pcgd.setShape(GradientDrawable.RECTANGLE)
    pcgd.setCornerRadius(dp(16))
    pcgd.setStroke(dp(1), 0xA0FFFFFF)
    planCard.setBackground(pcgd)
    planCard.setElevation(dp(4))
    planCard.setClickable(true)

    local planDot = View(activity)
    local pdlp = LinearLayout.LayoutParams(dp(14), dp(14))
    pdlp.rightMargin = dp(14)
    planDot.setLayoutParams(pdlp)
    local pdgd = GradientDrawable(
      GradientDrawable.Orientation.TL_BR, {planColor1, planColor2})
    pdgd.setShape(GradientDrawable.OVAL)
    planDot.setBackground(pdgd)
    planCard.addView(planDot)

    local planTextWrap = LinearLayout(activity)
    planTextWrap.setOrientation(LinearLayout.VERTICAL)
    planTextWrap.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
    planTextWrap.addView(mkText(planName, 15, C.text, true))

    local pdesc = mkText(planDesc, 11, C.textSub)
    local pdlp2 = LinearLayout.LayoutParams(-1, -2); pdlp2.topMargin = dp(4)
    pdesc.setLayoutParams(pdlp2)
    planTextWrap.addView(pdesc)
    planCard.addView(planTextWrap)

    local arrow = mkText("›", 20, C.textSub)
    planCard.addView(arrow)

    planCard.setOnClickListener(function()
      animateTap(planCard)
      GLOBAL_HANDLER.postDelayed(function()
        animateDialogOut(overlay, card, function()
          GLOBAL_HANDLER.postDelayed(function()
            showIslandOverlay()
          end, 150)
        end)
      end, 80)
    end)
    return planCard
  end

  local plan1Card = makePlanCard("方案一", "标准注入 · 稳定可靠", 0xFF6EA8FF, 0xFF4A90E2)
  local p1lp = LinearLayout.LayoutParams(-1, -2); p1lp.topMargin = dp(18)
  plan1Card.setLayoutParams(p1lp)
  card.addView(plan1Card)

  local plan2Card = makePlanCard("方案二", "增强注入 · 更高兼容", 0xFFB47BF0, 0xFF6B2EB0)
  local p2lp = LinearLayout.LayoutParams(-1, -2); p2lp.topMargin = dp(12)
  plan2Card.setLayoutParams(p2lp)
  card.addView(plan2Card)

  local cancelBtn = TextView(activity)
  cancelBtn.setText("取消")
  cancelBtn.setTextSize(14)
  cancelBtn.setTextColor(C.textSub)
  cancelBtn.setGravity(Gravity.CENTER)
  cancelBtn.setBackground(round(0x00000000, 12, C.border, 1))
  cancelBtn.setPadding(0, dp(12), 0, dp(12))
  cancelBtn.setClickable(true)
  local cblp = LinearLayout.LayoutParams(-1, -2); cblp.topMargin = dp(16)
  cancelBtn.setLayoutParams(cblp)
  cancelBtn.setOnClickListener(function()
    animateTap(cancelBtn)
    GLOBAL_HANDLER.postDelayed(function()
      animateDialogOut(overlay, card)
    end, 60)
  end)
  card.addView(cancelBtn)

  overlay.addView(card)
  overlay.setOnClickListener(function()
    animateDialogOut(overlay, card)
  end)
  activity.getWindow().getDecorView().addView(overlay, ViewGroup.LayoutParams(-1, -1))
  animateDialogIn(overlay, card)
end

-- ============================================================
--  根布局
-- ============================================================
local root = FrameLayout(activity)
root.setBackgroundColor(C.bg)

local mainCol = LinearLayout(activity)
mainCol.setOrientation(LinearLayout.VERTICAL)
mainCol.setPadding(0, statusBarH, 0, 0)
root.addView(mainCol, FrameLayout.LayoutParams(-1, -1))

local content = FrameLayout(activity)
mainCol.addView(content, LinearLayout.LayoutParams(-1, 0, 1))

local navContainer = FrameLayout(activity)
local navLp = FrameLayout.LayoutParams(-1, dp(78))
navLp.gravity = Gravity.BOTTOM
navContainer.setLayoutParams(navLp)
navContainer.setClipChildren(false)
navContainer.setClipToPadding(false)
root.addView(navContainer)

local nav = LinearLayout(activity)
nav.setOrientation(LinearLayout.HORIZONTAL)
nav.setGravity(Gravity.CENTER)
nav.setPadding(dp(8), dp(6), dp(8), dp(6))
nav.setBackground(makeGlassBg(30, 0xB0FFFFFF))
nav.setElevation(dp(20))
local innerLp = FrameLayout.LayoutParams(-1, dp(58))
innerLp.gravity = Gravity.CENTER
innerLp.leftMargin = dp(16)
innerLp.rightMargin = dp(16)
innerLp.bottomMargin = dp(10)
nav.setLayoutParams(innerLp)
navContainer.addView(nav)

local navHighlight = View(activity)
local nhlp = FrameLayout.LayoutParams(dp(80), dp(1.5))
nhlp.gravity = Gravity.TOP + Gravity.CENTER_HORIZONTAL
nhlp.topMargin = dp(14)
navHighlight.setLayoutParams(nhlp)
local navHlGd = GradientDrawable(
  GradientDrawable.Orientation.LEFT_RIGHT,
  {0x00FFFFFF, 0xCCFFFFFF, 0x00FFFFFF})
navHlGd.setCornerRadius(dp(1))
navHighlight.setBackground(navHlGd)
navContainer.addView(navHighlight)

-- ============================================================
--  雪花
-- ============================================================
local snowHandler = Handler()
local snowRunning = false
local snowList = {}
local snowFrameCounter = 0
local snowCacheW, snowCacheH = 0, 0
local startSnow

local function getSnowInterval()
  local n = #snowList
  if n <= 30 then return 16
  elseif n <= 60 then return 22
  elseif n <= 100 then return 33
  else return 45 end
end

local function snowTickLoop()
  if not snowRunning then return end
  if snowCacheW == 0 or snowCacheH == 0 then
    snowCacheW = root.getWidth()
    snowCacheH = root.getHeight()
    if snowCacheW <= 0 then snowCacheW = dm.widthPixels end
    if snowCacheH <= 0 then snowCacheH = dm.heightPixels end
  end
  local w, h = snowCacheW, snowCacheH
  local mult = S.snowSpeed / 50.0
  local list = snowList
  local n = #list
  local interval = getSnowInterval()
  local fpsScale = 16 / interval
  for i = 1, n do
    local s = list[i]
    s.y = s.y + s.speed * mult * fpsScale
    s.phase = s.phase + 0.03 * mult * fpsScale
    local x = (s.x % w) + math.sin(s.phase) * s.drift
    s.view.setX(x)
    s.view.setY(s.y)
    if s.y > h then
      s.y = -dp(40)
      s.x = math.random(0, w)
    end
  end
  snowHandler.postDelayed(snowTickLoop, interval)
end

local function stopSnow()
  snowRunning = false
  local list = snowList
  local n = #list
  for i = 1, n do
    root.removeView(list[i].view)
  end
  snowList = {}
  snowCacheW = 0
  snowCacheH = 0
end

local function pauseSnow() snowRunning = false end

local function resumeSnow()
  if not S.snowOn or S.snowNum <= 0 then return end
  if #snowList == 0 then startSnow(); return end
  if not snowRunning then
    snowRunning = true
    snowHandler.postDelayed(snowTickLoop, getSnowInterval())
  end
end

startSnow = function()
  stopSnow()
  if not S.snowOn or S.snowNum <= 0 then return end
  local w = root.getWidth()
  local h = root.getHeight()
  if w <= 0 then w = dm.widthPixels end
  if h <= 0 then h = dm.heightPixels end
  local snowColor = C.primary
  local count = S.snowNum
  for i = 1, count do
    local sizePx = dp(math.random(15, 30))
    local v = View(activity)
    v.setLayoutParams(FrameLayout.LayoutParams(sizePx, sizePx))
    local d = GradientDrawable()
    d.setShape(GradientDrawable.OVAL)
    d.setColor(snowColor)
    v.setBackground(d)
    v.setAlpha(0.75)
    v.setClickable(false)
    v.setFocusable(false)
    v.setFocusableInTouchMode(false)
    root.addView(v)
    local initX = math.random(0, math.max(1, w - sizePx))
    local initY = math.random(0, math.max(1, h - sizePx))
    v.setX(initX)
    v.setY(initY)
    table.insert(snowList, {
      view = v, x = initX, y = initY,
      speed = math.random(1, 3),
      phase = math.random() * 6.28,
      drift = math.random(5, 20),
    })
  end
  snowRunning = true
  snowFrameCounter = 0
  snowCacheW = 0
  snowCacheH = 0
  snowHandler.postDelayed(snowTickLoop, getSnowInterval())
  writeLog("[SNOW] 启动: " .. #snowList .. " 片 @" .. getSnowInterval() .. "ms")
end

-- ============================================================
--  日志自动刷新
-- ============================================================
local autoRefreshActive = false
local autoRefreshHandler = Handler()
local currentTermRefresh = nil

local function startAutoRefresh()
  if autoRefreshActive then return end
  autoRefreshActive = true
  local function loop()
    if not autoRefreshActive then return end
    if currentTermRefresh then pcall(currentTermRefresh) end
    autoRefreshHandler.postDelayed(loop, 1500)
  end
  autoRefreshHandler.postDelayed(loop, 1500)
end

local function stopAutoRefresh()
  autoRefreshActive = false
  currentTermRefresh = nil
end

-- ============================================================
--  登录页
-- ============================================================
local function showLogin()
  local loginOverlay = FrameLayout(activity)
  loginOverlay.setBackgroundColor(0xFFFFFFFF)
  loginOverlay.setClickable(true)
  loginOverlay.setFocusable(true)
  loginOverlay.setFocusableInTouchMode(true)
  loginOverlay.setOnKeyListener(function(_, keyCode, _)
    if keyCode == KeyEvent.KEYCODE_BACK then return true end
    return false
  end)
  local deco = View(activity)
  deco.setBackground(GradientDrawable(GradientDrawable.Orientation.TL_BR, C.themeDeco))
  loginOverlay.addView(deco, FrameLayout.LayoutParams(-1, dp(220) + statusBarH))
  local card = LinearLayout(activity)
  card.setOrientation(LinearLayout.VERTICAL)
  card.setPadding(dp(26), dp(34), dp(26), dp(34))
  card.setBackground(round(C.card, 24, C.border, 1))
  card.setElevation(dp(10))
  card.setClickable(true)
  local clp = FrameLayout.LayoutParams(dp(310), -2)
  clp.gravity = Gravity.CENTER
  card.setLayoutParams(clp)

  local t1 = mkText("七叶", 24, C.text, true)
  t1.setGravity(Gravity.CENTER)
  card.addView(t1)

  local t2 = mkText("请输入卡密以继续使用", 13, C.textSub)
  t2.setGravity(Gravity.CENTER)
  local t2p = LinearLayout.LayoutParams(-1, -2); t2p.topMargin = dp(8)
  t2.setLayoutParams(t2p)
  card.addView(t2)

  local input = EditText(activity)
  input.setHint("请输入卡密")
  input.setTextSize(15)
  input.setTextColor(C.text)
  input.setHintTextColor(C.textSub)
  input.setPadding(dp(16), dp(14), dp(16), dp(14))
  input.setSingleLine(true)
  input.setBackground(round(0xFFF2F4F8, 14, C.border, 1))
  local ilp = LinearLayout.LayoutParams(-1, -2); ilp.topMargin = dp(24)
  input.setLayoutParams(ilp)
  card.addView(input)

  local btnLogin = TextView(activity)
  btnLogin.setText("登  录")
  btnLogin.setTextSize(16)
  btnLogin.setTextColor(0xFFFFFFFF)
  btnLogin.setTypeface(Typeface.DEFAULT_BOLD)
  btnLogin.setGravity(Gravity.CENTER)
  btnLogin.setBackground(round(C.primary, 14))
  btnLogin.setPadding(0, dp(14), 0, dp(14))
  btnLogin.setClickable(true)
  local blp = LinearLayout.LayoutParams(-1, -2); blp.topMargin = dp(16)
  btnLogin.setLayoutParams(blp)
  btnLogin.setOnClickListener(function()
    animateTap(btnLogin)
    GLOBAL_HANDLER.postDelayed(function()
      local key = input.getText().toString()
      if key == nil or key == "" then toast("请输入卡密"); return end
      if key ~= CFG.FIXED_KEY then
        writeLog("[AUTH] 卡密校验失败")
        toast("卡密无效"); return
      end
      S.logged = true
      writeLog("[AUTH] 卡密校验成功")
      animValue(1, 0, 220,
        function(v)
          loginOverlay.setAlpha(v)
          card.setScaleX(0.9 + 0.1 * v)
          card.setScaleY(0.9 + 0.1 * v)
        end,
        function()
          removeFromParent(loginOverlay)
          toast("登录成功，欢迎使用七叶")
          GLOBAL_HANDLER.postDelayed(function() showAnnouncement() end, 300)
        end)
    end, 60)
  end)
  card.addView(btnLogin)

  local btnGet = TextView(activity)
  btnGet.setText("获取卡密链接 →")
  btnGet.setTextSize(13)
  btnGet.setTextColor(C.primary)
  btnGet.setGravity(Gravity.CENTER)
  btnGet.setBackground(round(0x00000000, 14, C.primary, 1))
  btnGet.setPadding(0, dp(12), 0, dp(12))
  btnGet.setClickable(true)
  local glp = LinearLayout.LayoutParams(-1, -2); glp.topMargin = dp(10)
  btnGet.setLayoutParams(glp)
  btnGet.setOnClickListener(function()
    animateTap(btnGet)
    GLOBAL_HANDLER.postDelayed(function() openUrl(CFG.CARD_URL) end, 50)
  end)
  card.addView(btnGet)

  loginOverlay.addView(card)
  activity.getWindow().getDecorView().addView(loginOverlay, ViewGroup.LayoutParams(-1, -1))
  loginOverlay.setAlpha(0)
  card.setScaleX(0.9)
  card.setScaleY(0.9)
  animValue(0, 1, 320,
    function(v)
      loginOverlay.setAlpha(v)
      local s = 0.9 + 0.1 * v
      card.setScaleX(s)
      card.setScaleY(s)
    end)
end

-- ============================================================
--  毛玻璃卡片
-- ============================================================
local function cardView(title, content, onClick)
  local card = LinearLayout(activity)
  card.setOrientation(LinearLayout.VERTICAL)
  card.setPadding(dp(20), dp(20), dp(20), dp(20))
  local cgd = GradientDrawable(
    GradientDrawable.Orientation.TOP_BOTTOM,
    {0xA6FFFFFF, 0x80FFFFFF, 0x99FFFFFF})
  cgd.setShape(GradientDrawable.RECTANGLE)
  cgd.setCornerRadius(dp(22))
  cgd.setStroke(dp(1), 0xB0FFFFFF)
  card.setBackground(cgd)
  card.setElevation(dp(6))
  if onClick then
    card.setClickable(true)
    card.setOnClickListener(function()
      card.setScaleX(0.98)
      card.setScaleY(0.98)
      animValue(0.98, 1, 130,
        function(v)
          card.setScaleX(v)
          card.setScaleY(v)
        end)
      GLOBAL_HANDLER.postDelayed(function() onClick() end, 50)
    end)
  end
  card.addView(mkText(title, 15, C.text, true))
  if content then
    local c = mkText(content, 13, C.textSub)
    local clp = LinearLayout.LayoutParams(-1, -2); clp.topMargin = dp(6)
    c.setLayoutParams(clp)
    c.setLineSpacing(0, 1.3)
    card.addView(c)
  end
  return card
end

-- ============================================================
--  柔光斑
-- ============================================================
local function addGlowBlobs(container)
  local blob1 = View(activity)
  local lp1 = FrameLayout.LayoutParams(dp(280), dp(280))
  lp1.leftMargin = dp(-80); lp1.topMargin = dp(40)
  blob1.setLayoutParams(lp1)
  local gd1 = GradientDrawable()
  gd1.setShape(GradientDrawable.OVAL)
  gd1.setGradientType(GradientDrawable.RADIAL_GRADIENT)
  gd1.setColors({0x59FFFFFF, 0x00FFFFFF})
  blob1.setBackground(gd1)
  container.addView(blob1)
  local blob2 = View(activity)
  local lp2 = FrameLayout.LayoutParams(dp(320), dp(320))
  lp2.gravity = Gravity.BOTTOM + Gravity.RIGHT
  lp2.rightMargin = dp(-100); lp2.bottomMargin = dp(-80)
  blob2.setLayoutParams(lp2)
  local gd2 = GradientDrawable()
  gd2.setShape(GradientDrawable.OVAL)
  gd2.setGradientType(GradientDrawable.RADIAL_GRADIENT)
  gd2.setColors({0x40FFFFFF, 0x00FFFFFF})
  blob2.setBackground(gd2)
  container.addView(blob2)
  local blob3 = View(activity)
  local lp3 = FrameLayout.LayoutParams(dp(200), dp(200))
  lp3.gravity = Gravity.TOP + Gravity.CENTER_HORIZONTAL
  lp3.topMargin = dp(200)
  blob3.setLayoutParams(lp3)
  local gd3 = GradientDrawable()
  gd3.setShape(GradientDrawable.OVAL)
  gd3.setGradientType(GradientDrawable.RADIAL_GRADIENT)
  gd3.setColors({0x30FFFFFF, 0x00FFFFFF})
  blob3.setBackground(gd3)
  container.addView(blob3)
end

-- ============================================================
--  主页
-- ============================================================
local function buildHomePage()
  local wrapper = FrameLayout(activity)
  wrapper.setBackgroundColor(C.bg)
  addGlowBlobs(wrapper)
  local scroll = ScrollView(activity)
  scroll.setFillViewport(true)
  scroll.setVerticalScrollBarEnabled(false)
  scroll.setOverScrollMode(View.OVER_SCROLL_NEVER)
  scroll.setBackgroundColor(0x00000000)
  local page = LinearLayout(activity)
  page.setOrientation(LinearLayout.VERTICAL)
  page.setPadding(dp(20), dp(20), dp(20), dp(90))
  page.setBackgroundColor(0x00000000)
  page.addView(mkText("七叶", 26, C.text, true))
  local sub = mkText("个人研究与开发项目", 13, C.textSub)
  local sp = LinearLayout.LayoutParams(-1, -2)
  sp.topMargin = dp(4); sp.bottomMargin = dp(18)
  sub.setLayoutParams(sp)
  page.addView(sub)

  local injectCard = LinearLayout(activity)
  injectCard.setOrientation(LinearLayout.VERTICAL)
  injectCard.setPadding(dp(20), dp(20), dp(20), dp(20))
  local icgd = GradientDrawable(
    GradientDrawable.Orientation.TL_BR,
    {0xFF8E7CF0, 0xFF6B5ED6})
  icgd.setShape(GradientDrawable.RECTANGLE)
  icgd.setCornerRadius(dp(20))
  injectCard.setBackground(icgd)
  injectCard.setElevation(dp(8))
  injectCard.setClickable(true)

  local injectTitleRow = LinearLayout(activity)
  injectTitleRow.setOrientation(LinearLayout.HORIZONTAL)
  injectTitleRow.setGravity(Gravity.CENTER_VERTICAL)
  local injectTitle = mkText("七叶注入", 16, 0xFFFFFFFF, true)
  injectTitle.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
  injectTitleRow.addView(injectTitle)
  local injectArrow = mkText("›", 22, 0xCCFFFFFF)
  injectTitleRow.addView(injectArrow)
  injectCard.addView(injectTitleRow)

  local injectDesc = mkText("点击启动系统悬浮窗 · 需先激活授权", 12, 0xCCFFFFFF)
  local idlp = LinearLayout.LayoutParams(-1, -2); idlp.topMargin = dp(8)
  injectDesc.setLayoutParams(idlp)
  injectCard.addView(injectDesc)

  local authOk = S.authorized
  local authStatus = mkText(
    authOk and "已激活独家授权" or "未激活独家授权（需先授权）",
    11,
    authOk and 0xCCFFFFFF or 0xFFFFD45C)
  local aslp = LinearLayout.LayoutParams(-1, -2); aslp.topMargin = dp(8)
  authStatus.setLayoutParams(aslp)
  injectCard.addView(authStatus)

  local permOk = canDrawOverlays()
  local permStatus = mkText(
    permOk and "悬浮窗权限已开启" or "需要悬浮窗权限",
    11,
    permOk and 0xCCFFFFFF or 0xFFFFD45C)
  local pslp = LinearLayout.LayoutParams(-1, -2); pslp.topMargin = dp(4)
  permStatus.setLayoutParams(pslp)
  injectCard.addView(permStatus)

  injectCard.setOnClickListener(function()
    animateTap(injectCard)
    GLOBAL_HANDLER.postDelayed(function()
      showPlanSelector()
    end, 80)
  end)

  local icp = LinearLayout.LayoutParams(-1, -2); icp.bottomMargin = dp(12)
  page.addView(injectCard, icp)

  local c1 = cardView("作者：" .. CFG.AUTHOR, "个人研究与开发项目")
  local c1p = LinearLayout.LayoutParams(-1, -2); c1p.bottomMargin = dp(12)
  page.addView(c1, c1p)
  local c2 = cardView("版本", CFG.VERSION)
  local c2p = LinearLayout.LayoutParams(-1, -2); c2p.bottomMargin = dp(12)
  page.addView(c2, c2p)
  local c3 = cardView("123 网盘", "取码：jZP0", function()
    openUrl(CFG.NETDISK_URL)
  end)
  local c3p = LinearLayout.LayoutParams(-1, -2); c3p.bottomMargin = dp(12)
  page.addView(c3, c3p)
  local c4 = cardView("学习 QQ 群", "群号：" .. CFG.QQ_NUM .. "  ·  点击加群", function()
    openUrl(CFG.QQ_URL)
  end)
  local c4p = LinearLayout.LayoutParams(-1, -2); c4p.bottomMargin = dp(12)
  page.addView(c4, c4p)
  scroll.addView(page, FrameLayout.LayoutParams(-1, -2))
  wrapper.addView(scroll, FrameLayout.LayoutParams(-1, -1))
  return wrapper
end

-- ============================================================
--  配置页
-- ============================================================
local function buildConfigPage()
  local wrapper = FrameLayout(activity)
  wrapper.setBackgroundColor(C.bg)
  addGlowBlobs(wrapper)
  local scroll = ScrollView(activity)
  scroll.setVerticalScrollBarEnabled(false)
  scroll.setOverScrollMode(View.OVER_SCROLL_NEVER)
  scroll.setBackgroundColor(0x00000000)
  local page = LinearLayout(activity)
  page.setOrientation(LinearLayout.VERTICAL)
  page.setPadding(dp(20), dp(20), dp(20), dp(90))
  page.setBackgroundColor(0x00000000)
  page.addView(mkText("配置", 24, C.text, true))

  local authCard = LinearLayout(activity)
  authCard.setOrientation(LinearLayout.HORIZONTAL)
  authCard.setGravity(Gravity.CENTER_VERTICAL)
  authCard.setPadding(dp(18), dp(16), dp(18), dp(16))
  local augd = GradientDrawable(
    GradientDrawable.Orientation.TOP_BOTTOM,
    {0xA6FFFFFF, 0x80FFFFFF, 0x99FFFFFF})
  augd.setShape(GradientDrawable.RECTANGLE)
  augd.setCornerRadius(dp(18))
  augd.setStroke(dp(1), 0xB0FFFFFF)
  authCard.setBackground(augd)
  authCard.setElevation(dp(6))
  authCard.setClickable(true)
  local aucp = LinearLayout.LayoutParams(-1, -2); aucp.topMargin = dp(16)
  page.addView(authCard, aucp)

  local goldDot = View(activity)
  local gdlp = LinearLayout.LayoutParams(dp(12), dp(12))
  gdlp.rightMargin = dp(14)
  goldDot.setLayoutParams(gdlp)
  local gdgd = GradientDrawable(
    GradientDrawable.Orientation.TL_BR,
    {0xFFFFD45C, 0xFFE8A100})
  gdgd.setShape(GradientDrawable.OVAL)
  goldDot.setBackground(gdgd)
  authCard.addView(goldDot)

  local auTextWrap = LinearLayout(activity)
  auTextWrap.setOrientation(LinearLayout.VERTICAL)
  auTextWrap.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
  auTextWrap.addView(mkText("独家授权", 15, C.text, true))
  local auStatus = mkText(
    S.authorized and "已授权 · 感谢支持" or "点击输入卡密授权",
    12,
    S.authorized and C.success or C.textSub)
  local auSp = LinearLayout.LayoutParams(-1, -2); auSp.topMargin = dp(4)
  auStatus.setLayoutParams(auSp)
  auTextWrap.addView(auStatus)
  authCard.addView(auTextWrap)

  authCard.setOnClickListener(function()
    animateTap(authCard)
    GLOBAL_HANDLER.postDelayed(function()
      if S.authorized then
        showDialog({
          title = "已授权",
          content = "您已经完成独家授权，感谢支持！",
          okText = "知道了",
        })
        return
      end
      local overlay = FrameLayout(activity)
      overlay.setBackgroundColor(0x00000000)
      overlay.setClickable(true)
      local card = LinearLayout(activity)
      card.setOrientation(LinearLayout.VERTICAL)
      card.setPadding(dp(24), dp(24), dp(24), dp(20))
      local cgd = GradientDrawable(
        GradientDrawable.Orientation.TOP_BOTTOM,
        {0xFFFFFFFF, 0xFAFFFFFF})
      cgd.setShape(GradientDrawable.RECTANGLE)
      cgd.setCornerRadius(dp(22))
      cgd.setStroke(dp(1), 0xB0FFFFFF)
      card.setBackground(cgd)
      card.setElevation(dp(16))
      card.setClickable(true)
      local clp = FrameLayout.LayoutParams(dp(300), -2)
      clp.gravity = Gravity.CENTER
      card.setLayoutParams(clp)
      local topDeco = View(activity)
      local tdp = LinearLayout.LayoutParams(-1, dp(4))
      topDeco.setLayoutParams(tdp)
      local tdgd = GradientDrawable(
        GradientDrawable.Orientation.LEFT_RIGHT,
        {0xFFFFE082, 0xFFFFB300, 0xFFFFE082})
      tdgd.setCornerRadius(dp(2))
      topDeco.setBackground(tdgd)
      card.addView(topDeco)

      local titleWrap = LinearLayout(activity)
      titleWrap.setOrientation(LinearLayout.VERTICAL)
      local trp = LinearLayout.LayoutParams(-1, -2); trp.topMargin = dp(14)
      titleWrap.setLayoutParams(trp)
      titleWrap.addView(mkText("独家授权", 16, C.text, true))
      titleWrap.addView(mkText("请输入授权卡密", 11, C.textSub))
      card.addView(titleWrap)

      local authInput = EditText(activity)
      authInput.setHint("请输入独家授权卡密")
      authInput.setTextSize(14)
      authInput.setTextColor(C.text)
      authInput.setHintTextColor(C.textSub)
      authInput.setPadding(dp(16), dp(14), dp(16), dp(14))
      authInput.setSingleLine(true)
      authInput.setBackground(round(0xFFF2F4F8, 12, C.border, 1))
      local ailp = LinearLayout.LayoutParams(-1, -2); ailp.topMargin = dp(18)
      authInput.setLayoutParams(ailp)
      card.addView(authInput)
      local hint = mkText("请输入独家授权卡密后点击确认", 11, C.textSub)
      local hlp = LinearLayout.LayoutParams(-1, -2); hlp.topMargin = dp(8)
      hint.setLayoutParams(hlp)
      card.addView(hint)
      local btnRow = LinearLayout(activity)
      btnRow.setOrientation(LinearLayout.HORIZONTAL)
      btnRow.setGravity(Gravity.END)
      local brlp = LinearLayout.LayoutParams(-1, -2); brlp.topMargin = dp(18)
      btnRow.setLayoutParams(brlp)
      local cancelBtn = TextView(activity)
      cancelBtn.setText("取消")
      cancelBtn.setTextSize(14)
      cancelBtn.setTextColor(C.textSub)
      cancelBtn.setGravity(Gravity.CENTER)
      cancelBtn.setBackground(round(0x00000000, 12, C.border, 1))
      cancelBtn.setPadding(dp(20), dp(10), dp(20), dp(10))
      cancelBtn.setClickable(true)
      local cblp = LinearLayout.LayoutParams(-2, -2); cblp.rightMargin = dp(10)
      cancelBtn.setLayoutParams(cblp)
      cancelBtn.setOnClickListener(function()
        animateTap(cancelBtn)
        GLOBAL_HANDLER.postDelayed(function()
          animateDialogOut(overlay, card)
        end, 60)
      end)
      btnRow.addView(cancelBtn)
      local okBtn = TextView(activity)
      okBtn.setText("确认授权")
      okBtn.setTextSize(14)
      okBtn.setTextColor(0xFFFFFFFF)
      okBtn.setTypeface(Typeface.DEFAULT_BOLD)
      okBtn.setGravity(Gravity.CENTER)
      local okgd = GradientDrawable(
        GradientDrawable.Orientation.TL_BR,
        {0xFFFFB300, 0xFFE8A100})
      okgd.setCornerRadius(dp(12))
      okBtn.setBackground(okgd)
      okBtn.setPadding(dp(20), dp(10), dp(20), dp(10))
      okBtn.setClickable(true)
      okBtn.setLayoutParams(LinearLayout.LayoutParams(-2, -2))
      okBtn.setOnClickListener(function()
        animateTap(okBtn)
        GLOBAL_HANDLER.postDelayed(function()
          local key = authInput.getText().toString()
          if key == nil or key == "" then
            toast("请输入授权卡密")
            return
          end
          if key ~= CFG.AUTH_KEY then
            writeLog("[AUTH-KEY] 授权失败")
            toast("授权卡密错误")
            animValue(0, 1, 320,
              function(v)
                local offset = math.sin(v * 20) * dp(8) * (1 - v)
                card.setTranslationX(offset)
              end,
              function() card.setTranslationX(0) end)
            return
          end
          S.authorized = true
          saveAuthState()
          writeLog("[AUTH-KEY] 独家授权成功")
          toast("授权成功，感谢支持")
          animateDialogOut(overlay, card, function()
            pages["config"] = nil
            if currentKey == "config" then
              currentKey = nil
              switchPage("config")
            end
          end)
        end, 60)
      end)
      btnRow.addView(okBtn)
      card.addView(btnRow)
      overlay.addView(card)
      overlay.setOnClickListener(function()
        animateDialogOut(overlay, card)
      end)
      activity.getWindow().getDecorView().addView(overlay,
        ViewGroup.LayoutParams(-1, -1))
      animateDialogIn(overlay, card)
    end, 80)
  end)

  -- 日志终端
  local term = LinearLayout(activity)
  term.setOrientation(LinearLayout.VERTICAL)
  term.setBackground(round(C.termBg, 16, C.termBorder, 1))
  term.setElevation(dp(4))
  local tp = LinearLayout.LayoutParams(-1, dp(500)); tp.topMargin = dp(16)
  page.addView(term, tp)
  local header = LinearLayout(activity)
  header.setOrientation(LinearLayout.HORIZONTAL)
  header.setGravity(Gravity.CENTER_VERTICAL)
  header.setPadding(dp(14), dp(10), dp(14), dp(10))
  header.setBackground(roundRadii(C.termHeader, {16, 16, 0, 0}, C.termBorder, 1))
  local dotR = View(activity)
  dotR.setLayoutParams(LinearLayout.LayoutParams(dp(10), dp(10)))
  dotR.setBackground(round(C.termRed, 5))
  header.addView(dotR)
  local dotY = View(activity)
  local dyp = LinearLayout.LayoutParams(dp(10), dp(10)); dyp.leftMargin = dp(6)
  dotY.setLayoutParams(dyp)
  dotY.setBackground(round(C.termYellow, 5))
  header.addView(dotY)
  local dotG = View(activity)
  local dgp = LinearLayout.LayoutParams(dp(10), dp(10)); dgp.leftMargin = dp(6); dgp.rightMargin = dp(10)
  dotG.setLayoutParams(dgp)
  dotG.setBackground(round(C.termGreen, 5))
  header.addView(dotG)
  header.addView(mkMono(LOG_DIR .. "/", 11, C.termBlue))
  term.addView(header)
  local contentWrap = ScrollView(activity)
  contentWrap.setBackgroundColor(C.termBg)
  contentWrap.setPadding(dp(12), dp(10), dp(12), dp(10))
  contentWrap.setVerticalScrollBarEnabled(false)
  contentWrap.setOverScrollMode(View.OVER_SCROLL_NEVER)
  term.addView(contentWrap, LinearLayout.LayoutParams(-1, 0, 1))
  local termContent = mkMono("", 11, C.termText)
  termContent.setLineSpacing(0, 1.4)
  termContent.setTextIsSelectable(true)
  contentWrap.addView(termContent)
  local lastLogHash = ""
  local function refreshTerm()
    local text = readLog()
    if text == "" then text = "(暂无日志)\n" end
    if text ~= lastLogHash then
      lastLogHash = text
      termContent.setText(text)
      pcall(function()
        contentWrap.post(function()
          contentWrap.fullScroll(View.FOCUS_DOWN)
        end)
      end)
    end
  end
  currentTermRefresh = refreshTerm
  local btnRow = LinearLayout(activity)
  btnRow.setOrientation(LinearLayout.HORIZONTAL)
  btnRow.setGravity(Gravity.CENTER)
  btnRow.setPadding(dp(10), dp(8), dp(10), dp(8))
  btnRow.setBackground(roundRadii(C.termHeader, {0, 0, 16, 16}, C.termBorder, 1))
  local function termBtn(text, color, cb)
    local b = mkMono(text, 12, color)
    b.setGravity(Gravity.CENTER)
    b.setPadding(dp(14), dp(8), dp(14), dp(8))
    b.setBackground(round(0x00000000, 8, color, 1))
    b.setClickable(true)
    local lp = LinearLayout.LayoutParams(0, -2, 1)
    lp.leftMargin = dp(4); lp.rightMargin = dp(4)
    b.setLayoutParams(lp)
    b.setOnClickListener(function()
      animateTap(b)
      GLOBAL_HANDLER.postDelayed(function() cb() end, 50)
    end)
    return b
  end
  btnRow.addView(termBtn("刷新", C.termBlue, function()
    refreshTerm(); toast("已刷新")
  end))
  btnRow.addView(termBtn("清空", C.termRed, function()
    showDialog({
      title = "确认清空？",
      content = "将清空当前日志文件内容（保留日期头），无法恢复。",
      okText = "清空", cancelText = "取消",
      onOk = function()
        resetLog()
        writeLog("[TERM] 用户清空了日志")
        lastLogHash = ""
        refreshTerm()
        toast("日志已清空")
      end,
    })
  end))
  btnRow.addView(termBtn("目录", C.termYellow, function()
    toast("目录：" .. LOG_DIR)
  end))
  term.addView(btnRow)
  refreshTerm()
  scroll.addView(page, FrameLayout.LayoutParams(-1, -2))
  wrapper.addView(scroll, FrameLayout.LayoutParams(-1, -1))
  return wrapper
end

-- ============================================================
--  设置页
-- ============================================================
local applyTheme

local function buildSettingPage()
  local wrapper = FrameLayout(activity)
  wrapper.setBackgroundColor(C.bg)
  addGlowBlobs(wrapper)
  local scroll = ScrollView(activity)
  scroll.setVerticalScrollBarEnabled(false)
  scroll.setOverScrollMode(View.OVER_SCROLL_NEVER)
  scroll.setBackgroundColor(0x00000000)
  local page = LinearLayout(activity)
  page.setOrientation(LinearLayout.VERTICAL)
  page.setPadding(dp(20), dp(20), dp(20), dp(90))
  page.setBackgroundColor(0x00000000)
  page.addView(mkText("设置", 24, C.text, true))

  local themeCard = LinearLayout(activity)
  themeCard.setOrientation(LinearLayout.VERTICAL)
  themeCard.setPadding(dp(20), dp(20), dp(20), dp(20))
  local tcgd = GradientDrawable(
    GradientDrawable.Orientation.TOP_BOTTOM,
    {0xA6FFFFFF, 0x80FFFFFF, 0x99FFFFFF})
  tcgd.setShape(GradientDrawable.RECTANGLE)
  tcgd.setCornerRadius(dp(22))
  tcgd.setStroke(dp(1), 0xB0FFFFFF)
  themeCard.setBackground(tcgd)
  themeCard.setElevation(dp(6))
  local tcp = LinearLayout.LayoutParams(-1, -2); tcp.topMargin = dp(16)
  page.addView(themeCard, tcp)
  themeCard.addView(mkText("主题配色", 15, C.text, true))
  local themeSub = mkText("点击色块切换 · 卡片与弹窗颜色保持白色", 12, C.textSub)
  local tsp = LinearLayout.LayoutParams(-1, -2); tsp.topMargin = dp(4)
  themeSub.setLayoutParams(tsp)
  themeCard.addView(themeSub)
  local swatchRow = LinearLayout(activity)
  swatchRow.setOrientation(LinearLayout.HORIZONTAL)
  swatchRow.setGravity(Gravity.CENTER)
  local srp = LinearLayout.LayoutParams(-1, -2); srp.topMargin = dp(18)
  swatchRow.setLayoutParams(srp)
  for _, th in ipairs(THEMES) do
    local wrap = LinearLayout(activity)
    wrap.setOrientation(LinearLayout.VERTICAL)
    wrap.setGravity(Gravity.CENTER_HORIZONTAL)
    wrap.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
    local swatchWrap = FrameLayout(activity)
    swatchWrap.setLayoutParams(LinearLayout.LayoutParams(dp(54), dp(54)))
    if S.theme == th.key then
      local ring = View(activity)
      local rlp = FrameLayout.LayoutParams(dp(54), dp(54))
      rlp.gravity = Gravity.CENTER
      ring.setLayoutParams(rlp)
      local rd = GradientDrawable()
      rd.setShape(GradientDrawable.OVAL)
      rd.setColor(0x00000000)
      rd.setStroke(dp(2), C.primary)
      ring.setBackground(rd)
      swatchWrap.addView(ring)
    end
    local swatch = View(activity)
    local slp = FrameLayout.LayoutParams(dp(44), dp(44))
    slp.gravity = Gravity.CENTER
    swatch.setLayoutParams(slp)
    local sd = GradientDrawable(GradientDrawable.Orientation.TL_BR, th.deco)
    sd.setShape(GradientDrawable.OVAL)
    if S.theme == th.key then sd.setStroke(dp(3), 0xFFFFFFFF) end
    swatch.setBackground(sd)
    swatch.setClickable(true)
    swatch.setFocusable(true)
    swatch.setFocusableInTouchMode(true)
    swatch.setOnClickListener(function()
      if S.theme == th.key then return end
      swatch.setScaleX(0.8)
      swatch.setScaleY(0.8)
      animValue(0.8, 1, 220,
        function(v)
          swatch.setScaleX(v)
          swatch.setScaleY(v)
        end)
      GLOBAL_HANDLER.postDelayed(function()
        applyTheme(th.key)
        toast("已切换到：" .. th.name)
      end, 60)
    end)
    swatchWrap.addView(swatch)
    wrap.addView(swatchWrap)
    local name = mkText(th.name, 11,
      (S.theme == th.key) and C.primary or C.textSub,
      (S.theme == th.key))
    name.setGravity(Gravity.CENTER)
    local nlp = LinearLayout.LayoutParams(-1, -2)
    nlp.topMargin = dp(6)
    name.setLayoutParams(nlp)
    wrap.addView(name)
    swatchRow.addView(wrap)
  end
  themeCard.addView(swatchRow)

  local aCard = cardView("关于七叶", "点击查看作者信息", function()
    showDialog({
      title = "关于",
      content = "作者：" .. CFG.AUTHOR .. "\n版本号：" .. CFG.VERSION,
      okText = "确定",
    })
  end)
  local acp = LinearLayout.LayoutParams(-1, -2); acp.topMargin = dp(12)
  page.addView(aCard, acp)

  local sCard = LinearLayout(activity)
  sCard.setOrientation(LinearLayout.VERTICAL)
  sCard.setPadding(dp(20), dp(20), dp(20), dp(20))
  local scgd = GradientDrawable(
    GradientDrawable.Orientation.TOP_BOTTOM,
    {0xA6FFFFFF, 0x80FFFFFF, 0x99FFFFFF})
  scgd.setShape(GradientDrawable.RECTANGLE)
  scgd.setCornerRadius(dp(22))
  scgd.setStroke(dp(1), 0xB0FFFFFF)
  sCard.setBackground(scgd)
  sCard.setElevation(dp(6))
  local scp = LinearLayout.LayoutParams(-1, -2); scp.topMargin = dp(12)
  page.addView(sCard, scp)
  local sRow = LinearLayout(activity)
  sRow.setOrientation(LinearLayout.HORIZONTAL)
  sRow.setGravity(Gravity.CENTER_VERTICAL)
  local sTitleWrap = LinearLayout(activity)
  sTitleWrap.setOrientation(LinearLayout.VERTICAL)
  sTitleWrap.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
  sTitleWrap.addView(mkText("雪花粒子特效", 15, C.text, true))
  sTitleWrap.addView(mkText("全屏飘落 · 自适应帧率", 12, C.textSub))
  sRow.addView(sTitleWrap)
  S.snowOn = toBool(S.snowOn)
  S.snowNum = tonumber(S.snowNum) or 50
  S.snowSpeed = tonumber(S.snowSpeed) or 50
  local sw = Switch(activity)
  sw.setChecked(S.snowOn)
  sRow.addView(sw)
  sCard.addView(sRow)
  local numRow = LinearLayout(activity)
  numRow.setOrientation(LinearLayout.HORIZONTAL)
  numRow.setGravity(Gravity.CENTER_VERTICAL)
  local nrp = LinearLayout.LayoutParams(-1, -2); nrp.topMargin = dp(20)
  numRow.setLayoutParams(nrp)
  numRow.addView(mkText("粒子数量", 13, C.textSub))
  local numVal = mkText(tostring(S.snowNum), 13, C.primary, true)
  local nvlp = LinearLayout.LayoutParams(-1, -2)
  nvlp.gravity = Gravity.END
  numVal.setLayoutParams(nvlp)
  numVal.setGravity(Gravity.END)
  numRow.addView(numVal)
  sCard.addView(numRow)
  local numSeek = SeekBar(activity)
  numSeek.setMax(150)
  numSeek.setProgress(S.snowNum)
  sCard.addView(numSeek)
  local spdRow = LinearLayout(activity)
  spdRow.setOrientation(LinearLayout.HORIZONTAL)
  spdRow.setGravity(Gravity.CENTER_VERTICAL)
  local srp2 = LinearLayout.LayoutParams(-1, -2); srp2.topMargin = dp(14)
  spdRow.setLayoutParams(srp2)
  spdRow.addView(mkText("飘落速度", 13, C.textSub))
  local spdVal = mkText(tostring(S.snowSpeed), 13, C.primary, true)
  local svlp = LinearLayout.LayoutParams(-1, -2)
  svlp.gravity = Gravity.END
  spdVal.setLayoutParams(svlp)
  spdVal.setGravity(Gravity.END)
  spdRow.addView(spdVal)
  sCard.addView(spdRow)
  local spdSeek = SeekBar(activity)
  spdSeek.setMax(100)
  spdSeek.setProgress(S.snowSpeed)
  sCard.addView(spdSeek)
  local tip = mkText("提示：≤30 片 60fps · 31~60 片 45fps · >60 片 30fps", 11, C.textSub)
  local tipP = LinearLayout.LayoutParams(-1, -2); tipP.topMargin = dp(10)
  tip.setLayoutParams(tipP)
  sCard.addView(tip)
  local suppressSwitch = false
  sw.setOnCheckedChangeListener(function(v)
    if suppressSwitch then return end
    S.snowOn = toBool(v)
    writeLog("[SNOW] 开关 = " .. (S.snowOn and "ON" or "OFF"))
    if S.snowOn then
      if S.snowNum <= 0 then
        suppressSwitch = true
        S.snowNum = 50
        numSeek.setProgress(50)
        numVal.setText("50")
        suppressSwitch = false
      end
      startSnow()
    else
      stopSnow()
    end
  end)
  numSeek.setOnSeekBarChangeListener(SeekBar.OnSeekBarChangeListener{
    onProgressChanged = function(_, progress, _)
      S.snowNum = tonumber(progress) or 0
      numVal.setText(tostring(S.snowNum))
      if S.snowNum <= 0 and S.snowOn then
        suppressSwitch = true
        S.snowOn = false
        sw.setChecked(false)
        suppressSwitch = false
        stopSnow()
      end
    end,
    onStartTrackingTouch = function(_) end,
    onStopTrackingTouch = function(_)
      if S.snowOn then startSnow() end
    end,
  })
  spdSeek.setOnSeekBarChangeListener(SeekBar.OnSeekBarChangeListener{
    onProgressChanged = function(_, progress, _)
      local p = tonumber(progress) or 1
      if p < 1 then p = 1 end
      S.snowSpeed = p
      spdVal.setText(tostring(p))
    end,
    onStartTrackingTouch = function(_) end,
    onStopTrackingTouch = function(_) end,
  })
  scroll.addView(page, FrameLayout.LayoutParams(-1, -2))
  wrapper.addView(scroll, FrameLayout.LayoutParams(-1, -1))
  return wrapper
end

-- ============================================================
--  错误页
-- ============================================================
local function buildErrorPage(pageKey, errMsg)
  local page = LinearLayout(activity)
  page.setOrientation(LinearLayout.VERTICAL)
  page.setPadding(dp(20), dp(40), dp(20), dp(20))
  page.setBackgroundColor(C.bg)
  page.addView(mkText("页面加载失败", 18, C.danger, true))
  local tip = mkText("页面：" .. tostring(pageKey) ..
    "\n\n错误：" .. tostring(errMsg or "未知"), 13, C.textSub)
  local tp = LinearLayout.LayoutParams(-1, -2); tp.topMargin = dp(12)
  tip.setLayoutParams(tp)
  tip.setLineSpacing(0, 1.4)
  page.addView(tip)
  return page
end

-- ============================================================
--  页面切换
-- ============================================================
local pages = {}
local currentKey = nil
local navKeys = {}
local navButtons = {}

local function refreshNav()
  for _, btn in ipairs(navButtons) do
    local key = navKeys[btn]
    if key == currentKey then
      local sgd = GradientDrawable(
        GradientDrawable.Orientation.TOP_BOTTOM,
        {0xFFFFFFFF, 0xF0FFFFFF, 0xFFFFFFFF})
      sgd.setShape(GradientDrawable.RECTANGLE)
      sgd.setCornerRadius(dp(20))
      sgd.setStroke(dp(1.5), 0xFFFFFFFF)
      btn.setBackground(sgd)
      btn.setTextColor(C.primary)
      btn.setTypeface(Typeface.DEFAULT_BOLD)
      btn.setTextSize(13)
      btn.setElevation(dp(4))
    else
      btn.setBackgroundColor(0x00000000)
      btn.setTextColor(C.textSub)
      btn.setTypeface(Typeface.DEFAULT)
      btn.setTextSize(13)
      btn.setElevation(0)
    end
  end
end

local function switchPage(key)
  if currentKey == key then return end
  currentKey = key
  if key == "config" then startAutoRefresh()
  else stopAutoRefresh() end
  if not pages[key] then
    local ok, result = pcall(function()
      if key == "home" then return buildHomePage()
      elseif key == "config" then return buildConfigPage()
      elseif key == "setting" then return buildSettingPage()
      end
      return nil
    end)
    if ok and result then
      pages[key] = result
    else
      writeErrorReport("ERROR", "switchPage:" .. tostring(key), result)
      pages[key] = buildErrorPage(key, result)
    end
  end
  content.removeAllViews()
  if pages[key] then
    content.addView(pages[key], FrameLayout.LayoutParams(-1, -1))
    animatePageIn(pages[key])
  end
  refreshNav()
end

local function makeNavBtn(label, key)
  local b = TextView(activity)
  b.setText(label)
  b.setTextSize(13)
  b.setGravity(Gravity.CENTER)
  b.setPadding(dp(20), dp(8), dp(20), dp(8))
  b.setBackground(round(0x00000000, 20))
  b.setTextColor(C.textSub)
  b.setClickable(true)
  local lp = LinearLayout.LayoutParams(0, dp(44), 1)
  lp.leftMargin = dp(4); lp.rightMargin = dp(4)
  b.setLayoutParams(lp)
  b.setOnClickListener(function()
    animateTap(b)
    if currentKey == key then return end
    GLOBAL_HANDLER.postDelayed(function() switchPage(key) end, 60)
  end)
  navKeys[b] = key
  table.insert(navButtons, b)
  return b
end

nav.addView(makeNavBtn("主页", "home"))
nav.addView(makeNavBtn("配置", "config"))
nav.addView(makeNavBtn("设置", "setting"))

-- ============================================================
--  主题切换
-- ============================================================
local themeSwitching = false

applyTheme = function(key)
  if themeSwitching then return end
  local t = findTheme(key)
  if not t then return end
  themeSwitching = true
  local snowWasRunning = toBool(snowRunning)
  if snowWasRunning then pauseSnow() end
  S.theme = t.key
  C.primary = t.primary
  C.bg = t.bg
  C.themeDeco = t.deco
  C.themeRootGrad = t.rootGrad
  C.navActiveBg = t.navActiveBg
  C.glow = t.glow
  writeLog("[THEME] 切换为: " .. t.name)
  root.setBackgroundColor(C.bg)
  pages = {}
  local keep = currentKey or "home"
  currentKey = nil
  GLOBAL_HANDLER.postDelayed(function()
    local ok, err = pcall(function() switchPage(keep) end)
    if not ok then writeErrorReport("ERROR", "applyTheme:" .. tostring(keep), err) end
    if snowWasRunning then
      GLOBAL_HANDLER.postDelayed(function()
        if S.snowOn then startSnow() end
        themeSwitching = false
      end, 80)
    else
      themeSwitching = false
    end
  end, 16)
end

activity.setContentView(root)

-- ============================================================
--  初始化
-- ============================================================
S.theme = "blue"
C.primary = THEMES[1].primary
C.bg = THEMES[1].bg
C.themeDeco = THEMES[1].deco
C.themeRootGrad = THEMES[1].rootGrad
C.navActiveBg = THEMES[1].navActiveBg
C.glow = THEMES[1].glow
root.setBackgroundColor(C.bg)

switchPage("home")
showLogin()