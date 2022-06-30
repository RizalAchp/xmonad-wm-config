import XMonad
import System.Directory
import System.IO (hPutStrLn)
import System.Exit (exitSuccess)
import qualified XMonad.StackSet as W
import XMonad.Actions.CopyWindow (kill1)
import XMonad.Actions.CycleWS (Direction1D(..), moveTo, shiftTo, WSType(..), nextScreen, prevScreen)
import XMonad.Actions.GridSelect
import XMonad.Actions.MouseResize
import XMonad.Actions.Promote
import XMonad.Actions.RotSlaves (rotSlavesDown, rotAllDown)
import XMonad.Actions.WindowGo (runOrRaise)
import XMonad.Actions.WithAll (sinkAll, killAll)
import qualified XMonad.Actions.Search as S
import Data.Char (isSpace, toUpper)
import Data.Maybe (fromJust)
import Data.Monoid
import Data.Maybe (isJust)
import Data.Tree
import qualified Data.Map as M
import XMonad.Hooks.DynamicLog (dynamicLogWithPP, wrap, xmobarPP, xmobarColor, shorten, PP(..))
import XMonad.Hooks.EwmhDesktops  -- for some fullscreen events, also for xcomposite in obs.
import XMonad.Hooks.ManageDocks (avoidStruts, docksEventHook, manageDocks, ToggleStruts(..))
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat, doCenterFloat)
import XMonad.Hooks.ServerMode
import XMonad.Hooks.SetWMName
import XMonad.Hooks.WorkspaceHistory
import XMonad.Layout.Accordion
import XMonad.Layout.GridVariants (Grid(Grid))
import XMonad.Layout.SimplestFloat
import XMonad.Layout.Spiral
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import XMonad.Layout.LayoutModifier
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiToggle (mkToggle, single, EOT(EOT), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed
import XMonad.Layout.ShowWName
import XMonad.Layout.Simplest
import XMonad.Layout.Spacing
import XMonad.Layout.SubLayouts
import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
import XMonad.Layout.WindowNavigation
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))
import qualified XMonad.Layout.MultiToggle as MT (Toggle(..))
import XMonad.Util.Dmenu
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce

colorBack = "#303030"
colorFore = "#eeffff"

color01 = "#353535"
color02 = "#f07178"
color03 = "#c3e88d"
color04 = "#ffcb6b"
color05 = "#82aaff"
color06 = "#c792ea"
color07 = "#89ddff"
color08 = "#121212"
color09 = "#4a4a4a"
color10 = "#f07178"
color11 = "#c3e88d"
color12 = "#ffcb6b"
color13 = "#82aaff"
color14 = "#c792ea"
color15 = "#89ddff"
color16 = "#ffffff"

colorTrayer :: String
colorTrayer = "--tint 0x121212"

enableSystray :: Bool
enableSystray = True

myFont :: String
myFont = "xft:JetBrainsMono Nerd Font:regular:size=11:antialias=true:hinting=true"

myModMask :: KeyMask
myModMask = mod4Mask

myTerminal :: String
myTerminal = "st"

myFileManager :: String
myFileManager = "pcmanfm"

myBrowser :: String
myBrowser = "brave"

myEditor :: String
myEditor = myTerminal ++ " -e nvim "

myGuiEditor :: String
myGuiEditor = "nvim-qt"

myBorderWidth :: Dimension
myBorderWidth = 2

myNormColor :: String
myNormColor   = colorBack

myFocusColor :: String
myFocusColor  = color05

windowCount :: X (Maybe String)
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

maimcopy :: String
maimcopy = "exec ~/bin/maimsave"

maimsave :: String
maimsave = "exec ~/bin/maimsave sscp"

rofi_launcher :: String
rofi_launcher = "rofi -no-lazy-grab -show drun -theme $HOME/.config/rofi/launcher/style"

trayerCommand :: String
trayerCommand = "trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 1 --transparent true --alpha 0 --tint 0x121212 --height 20 &"

xmobarToggleCommand :: String
xmobarToggleCommand = "pkill xmobar"

myStartupHook :: X ()
myStartupHook = do
    if enableSystray then spawn ("pkill trayer; sleep 1 && " ++ trayerCommand) else spawn ("pkill trayer") 
    spawnOnce "$HOME/.xmonad/scripts/autostart.sh"
    setWMName "LG3D"

myColorizer :: Window -> Bool -> X (String, String)
myColorizer = colorRangeFromClassName
                  (0x28,0x2c,0x34) -- lowest inactive bg
                  (0x28,0x2c,0x34) -- highest inactive bg
                  (0xc7,0x92,0xea) -- active bg
                  (0xc0,0xa7,0x9a) -- inactive fg
                  (0x28,0x2c,0x34) -- active fg

-- gridSelect menu layout
mygridConfig :: p -> GSConfig Window
mygridConfig colorizer = (buildDefaultGSConfig myColorizer)
    { gs_cellheight   = 40
    , gs_cellwidth    = 200
    , gs_cellpadding  = 6
    , gs_originFractX = 0.5
    , gs_originFractY = 0.5
    , gs_font         = myFont
    }

spawnSelected' :: [(String, String)] -> X ()
spawnSelected' lst = gridselect conf lst >>= flip whenJust spawn
    where conf = def
                   { gs_cellheight   = 40
                   , gs_cellwidth    = 200
                   , gs_cellpadding  = 6
                   , gs_originFractX = 0.5
                   , gs_originFractY = 0.5
                   , gs_font         = myFont
                   }

myAppGrid = [ ("File Manager", "pcmanfm")
                 , ("Android Studio", "com.google.AndroidStudio")
                 , ("Brave Browser", "brave")
                 , ("Code", "code")
                 ]

myScratchPads :: [NamedScratchpad]
myScratchPads = [ NS "terminal" spawnTerm findTerm manageTerm
                , NS "mocp" spawnMocp findMocp manageMocp
                , NS "calculator" spawnCalc findCalc manageCalc
                ]
  where
    spawnTerm  = myTerminal ++ " -t scratchpad"
    findTerm   = title =? "scratchpad"
    manageTerm = customFloating $ W.RationalRect l t w h
               where
                 h = 0.9
                 w = 0.9
                 t = 0.95 -h
                 l = 0.95 -w
    spawnMocp  = myTerminal ++ " -t mocp -e mocp -M $HOME/.config/moc/"
    findMocp   = title =? "mocp"
    manageMocp = customFloating $ W.RationalRect l t w h
               where
                 h = 0.9
                 w = 0.9
                 t = 0.95 -h
                 l = 0.95 -w 
    spawnCalc  = "qalculate-gtk"
    findCalc   = className =? "Qalculate-gtk"
    manageCalc = customFloating $ W.RationalRect l t w h
               where
                 h = 0.5
                 w = 0.4
                 t = 0.75 -h
                 l = 0.70 -w

--Makes setting the spacingRaw simpler to write. The spacingRaw module adds a configurable amount of space around windows.
mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

mySpacing' :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing' i = spacingRaw True (Border i i i i) True (Border i i i i) True

tall     = renamed [Replace "tall"]
           $ smartBorders
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 7
           $ mySpacing 4
           $ ResizableTall 1 (3/100) (1/2) []
magnify  = renamed [Replace "magnify"]
           $ smartBorders
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (smartBorders Simplest)
           $ magnifier
           $ limitWindows 7
           $ mySpacing 4
           $ ResizableTall 1 (3/100) (1/2) []
monocle  = renamed [Replace "monocle"]
           $ smartBorders
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 7 Full
floats   = renamed [Replace "floats"]
           $ smartBorders
           $ limitWindows 7 simplestFloat
grid     = renamed [Replace "grid"]
           $ smartBorders
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 7
           $ mySpacing 4
           $ mkToggle (single MIRROR)
           $ Grid (16/10)
spirals  = renamed [Replace "spirals"]
           $ smartBorders
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (smartBorders Simplest)
           $ mySpacing' 4
           $ spiral (6/7)
threeCol = renamed [Replace "threeCol"]
           $ smartBorders
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 7
           $ ThreeCol 1 (3/100) (1/2)
threeRow = renamed [Replace "threeRow"]
           $ smartBorders
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 7
           -- Mirror takes a layout and rotates it by 90 degrees.
           -- So we are applying Mirror to the ThreeCol layout.
           $ Mirror
           $ ThreeCol 1 (3/100) (1/2)
tabs     = renamed [Replace "tabs"]
           -- I cannot add spacing to this layout because it will
           -- add spacing between window and tabs which looks bad.
           $ tabbed shrinkText myTabTheme
tallAccordion  = renamed [Replace "tallAccordion"]
           $ Accordion
wideAccordion  = renamed [Replace "wideAccordion"]
           $ Mirror Accordion

-- setting colors for tabs layout and tabs sublayout.
myTabTheme = def { fontName            = myFont
                 , activeColor         = color05
                 , inactiveColor       = color08
                 , activeBorderColor   = color05
                 , inactiveBorderColor = colorBack
                 , activeTextColor     = colorBack
                 , inactiveTextColor   = color16
                 }

-- Theme for showWName which prints current workspace when you change workspaces.
myShowWNameTheme :: SWNConfig
myShowWNameTheme = def
    { swn_font              = "xft:JetBrainsMono Nerd Font:bold:size=28"
    , swn_fade              = 1.0
    , swn_bgcolor           = colorBack
    , swn_color             = color05
    }

-- The layout hook
myLayoutHook = avoidStruts $ mouseResize $ windowArrange $ T.toggleLayouts floats
               $ mkToggle (NBFULL ?? NOBORDERS ?? EOT) myDefaultLayout
             where
               myDefaultLayout =     withBorder myBorderWidth tall
                                 ||| magnify
                                 ||| noBorders monocle
                                 ||| floats
                                 ||| noBorders tabs
                                 ||| grid
                                 ||| spirals
                                 ||| threeCol
                                 ||| threeRow
                                 ||| tallAccordion
                                 ||| wideAccordion

-- encodeCChar = map fromIntegral . B.unpack
-- myWorkspaces = ["\61612","\61899","\61947","\61635","\61502","\61501","\61705","\61564","\62150","\61872"]
-- myWorkspaces = [" 1 ", " 2 ", " 3 ", " 4 ", " 5 ", " 6 ", " 7 ", " 8 ", " 9 "]
-- myWorkspaces    = ["\63083", "\63288", "\63306", "\61723", "\63107", "\63601", "\63391", "\61713", "\61884"]
myWorkspaces    = [" \xf121 ", " \xf07c ", " \xf0c6 ", " \61723 ", " \63107 ", " \63601 ", " \63391 ", " \xf03d ", " \61884 "]
-- myWorkspaces = ["㊀ ", "㊁ ", "㊂ ", "㊃ ", "㊄ ", "㊅ ", "㊆ ", "㊇ ", "㊈ "]
-- myWorkspaces = [" ➊ ", " ➋ ", " ➌ ", " ➍ ", " ➎ ", " ➏ ", " ➐ ", " ➑ ", " ➒ "]
myWorkspaceIndices = M.fromList $ zipWith (,) myWorkspaces [1..] -- (,) == \x y -> (x,y)

clickable ws = "<action=xdotool key super+"++show i++">"++ws++"</action>"
    where i = fromJust $ M.lookup ws myWorkspaceIndices

myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
myManageHook = composeAll
     -- 'doFloat' forces a window to float.  Useful for dialog boxes and such.
     -- using 'doShift ( myWorkspaces !! 7)' sends program to workspace 8!
     -- I'm doing it this way because otherwise I would have to write out the full
     -- name of my workspaces and the names would be very long if using clickable workspaces.
     [ className =? "confirm"         --> doFloat
     , className =? "file_progress"   --> doFloat
     , className =? "dialog"          --> doFloat
     , className =? "download"        --> doFloat
     , className =? "error"           --> doFloat
     , className =? "DesktopEditors"  --> doFloat
     , className =? "Inkscape"        --> doFloat
     , className =? "notification"    --> doFloat
     , className =? "pinentry-gtk-2"  --> doFloat
     , className =? "splash"          --> doFloat
     , className =? "toolbar"         --> doFloat
     , className =? "zoom"            --> doFloat
     , className =? "virt-manager"    --> doFloat
     , className =? "pcmanfm"         --> doFloat
     , className =? "Yad"             --> doCenterFloat
     , title =? "Execute File"        --> doCenterFloat
     , className =? "DesktopEditors"  --> doShift ( myWorkspaces !! 2 )
     , className =? "Brave-browser"   --> doShift ( myWorkspaces !! 1 )
     , className =? "mpv"             --> doShift ( myWorkspaces !! 7 )
     , className =? "obs"             --> doShift ( myWorkspaces !! 7 )
     , className =? "zoom"            --> doShift ( myWorkspaces !! 7 )
     , className =? "virt-manager"    --> doShift ( myWorkspaces !! 4 )
     , className =? "DynoTest Politeknik Negeri Jember"         --> doFloat
     , (className =? "Brave-browser" <&&> resource =? "Dialog") --> doFloat
     , (className =? "firefox" <&&> resource =? "Dialog")       --> doFloat
     , isFullscreen -->  doFullFloat
     ] <+> namedScratchpadManageHook myScratchPads

-- START_KEYS
myKeys :: [(String, X ())]
myKeys =
    -- KB_GROUP Xmonad
        [ ("M-C-r", spawn "xmonad --recompile")         -- Recompiles xmonad
        , ("M-S-r", spawn "xmonad --restart")           -- Restarts xmonad
        , ("M-S-q", io exitSuccess)                     -- Quits xmonad
        , ("M-S-/", spawn "~/.xmonad/scripts/xmonad_keys.sh")   -- keys help keybinding
        , ("M-S-s", spawn (maimcopy))                   -- screenshots clipboard
        , ("M-<Print>", spawn "dm-maim")                -- screenshots full
        , ("M-b", if enableSystray then spawn (xmobarToggleCommand ++ " && pkill trayer || " ++ trayerCommand) else spawn (xmobarToggleCommand) )

    -- KB_GROUP Run Prompt
        , ("M-S-<Return>", spawn "dmenu_run -c -bw 2 -l 10 -g 2 -p \"Run: \"")
        , ("M-S-p", spawn (rofi_launcher))
        -- , ("M-b", spawn "exec ~/bin/bartoggle")
        , ("C-M1-b", spawn "exec ~/.xmonad/scripts/launcheww.sh -s")
        , ("C-M1-f", spawn "exec ~/.xmonad/scripts/launcheww.sh -c")
        , ("C-M1-c", spawn "exec ~/bin/eww close-all")

    -- KB_GROUP Other Dmenu Prompts
        , ("M-p c", spawn "dm-colpick")     -- pick color from our scheme
        , ("M-p e", spawn "dm-confedit")    -- edit config files
        , ("M-p i", spawn "dm-maim")        -- screenshots (images)
        , ("M-p k", spawn "dm-kill")        -- kill processes
        , ("M-p m", spawn "dm-music")       -- manpages
        , ("M-p p", spawn "passmenu")       -- passmenu
        , ("M-p q", spawn "dm-logout")      -- logout menu
        , ("M-p r", spawn "dm-record")      -- reddio (a reddit viewer)
        , ("M-p s", spawn "dm-websearch")   -- search various search engines

    -- KB_GROUP Useful programs to have a keybinding for launch
        , ("M-<Return>", spawn (myTerminal))
        , ("M-S-f", spawn (myFileManager))
        , ("M-S-b", spawn (myBrowser)) -- ++ " www.duckduckgo.com" ))
        , ("M-S-o", spawn (myGuiEditor))
        , ("M-<Esc>", spawn (myTerminal ++ " -e htop"))

    -- KB_GROUP Kill windows
        , ("M-S-c", kill1)     -- Kill the currently focused client
        , ("M-S-a", killAll)   -- Kill all windows on current workspace

    -- KB_GROUP Workspaces
        , ("M-.", nextScreen)  -- Switch focus to next monitor
        , ("M-,", prevScreen)  -- Switch focus to prev monitor
        , ("M-S-<KP_Add>", shiftTo Next nonNSP >> moveTo Next nonNSP)       -- Shifts focused window to next ws
        , ("M-S-<KP_Subtract>", shiftTo Prev nonNSP >> moveTo Prev nonNSP)  -- Shifts focused window to prev ws

    -- KB_GROUP Floating windows
        , ("M-f", sendMessage (T.Toggle "floats")) -- Toggles my 'floats' layout
        , ("M-t", withFocused $ windows . W.sink)  -- Push floating window back to tile
        , ("M-S-t", sinkAll)                       -- Push ALL floating windows to tile

    -- KB_GROUP Increase/decrease spacing (gaps)
        , ("C-M1-j", decWindowSpacing 4)         -- Decrease window spacing
        , ("C-M1-k", incWindowSpacing 4)         -- Increase window spacing
        , ("C-M1-h", decScreenSpacing 4)         -- Decrease screen spacing
        , ("C-M1-l", incScreenSpacing 4)         -- Increase screen spacing

    -- KB_GROUP Grid Select (CTR-g followed by a key)
        , ("C-g g", spawnSelected' myAppGrid)                 -- grid select favorite apps
        , ("C-g t", goToSelected $ mygridConfig myColorizer)  -- goto selected window
        , ("C-g b", bringSelected $ mygridConfig myColorizer) -- bring selected window

    -- KB_GROUP Windows navigation
        , ("M-m", windows W.focusMaster)  -- Move focus to the master window
        , ("M-j", windows W.focusDown)    -- Move focus to the next window
        , ("M-k", windows W.focusUp)      -- Move focus to the prev window
        , ("M-S-m", windows W.swapMaster) -- Swap the focused window and the master window
        , ("M-S-j", windows W.swapDown)   -- Swap focused window with next window
        , ("M-S-k", windows W.swapUp)     -- Swap focused window with prev window
        , ("M-<Backspace>", promote)      -- Moves focused window to master, others maintain order
        , ("M-S-<Tab>", rotSlavesDown)    -- Rotate all windows except master and keep focus in place
        , ("M-C-<Tab>", rotAllDown)       -- Rotate all the windows in the current stack

    -- KB_GROUP Layouts
        , ("M-<Tab>", sendMessage NextLayout)           -- Switch to next layout
        , ("M-<Space>", sendMessage (MT.Toggle NBFULL) >> sendMessage ToggleStruts) -- Toggles noborder/full

    -- KB_GROUP Increase/decrease windows in the master pane or the stack
        , ("M-S-<Up>", sendMessage (IncMasterN 1))      -- Increase # of clients master pane
        , ("M-S-<Down>", sendMessage (IncMasterN (-1))) -- Decrease # of clients master pane
        , ("M-C-<Up>", increaseLimit)                   -- Increase # of windows
        , ("M-C-<Down>", decreaseLimit)                 -- Decrease # of windows

    -- KB_GROUP Window resizing
        , ("M-h", sendMessage Shrink)                   -- Shrink horiz window width
        , ("M-l", sendMessage Expand)                   -- Expand horiz window width
        , ("M-M1-j", sendMessage MirrorShrink)          -- Shrink vert window width
        , ("M-M1-k", sendMessage MirrorExpand)          -- Expand vert window width

    -- KB_GROUP Sublayouts
        , ("M-C-h", sendMessage $ pullGroup L)
        , ("M-C-l", sendMessage $ pullGroup R)
        , ("M-C-k", sendMessage $ pullGroup U)
        , ("M-C-j", sendMessage $ pullGroup D)
        , ("M-C-m", withFocused (sendMessage . MergeAll))
        -- , ("M-C-u", withFocused (sendMessage . UnMerge))
        , ("M-C-/", withFocused (sendMessage . UnMergeAll))
        , ("M-C-.", onGroup W.focusUp')    -- Switch focus to next tab
        , ("M-C-,", onGroup W.focusDown')  -- Switch focus to prev tab

    -- KB_GROUP Scratchpads
        , ("M1-s t", namedScratchpadAction myScratchPads "terminal")
        , ("M1-s m", namedScratchpadAction myScratchPads "mocp")
        , ("M1-s c", namedScratchpadAction myScratchPads "calculator")

    -- KB_GROUP Set wallpaper
        , ("M-<F1>", spawn "sxiv -r -q -t -o ~/Pictures/Wallpapers/*")
        -- , ("M-<F2>", spawn "find ~/wallpapers/ -type f | shuf -n 1 | xargs xwallpaper --stretch")
        , ("M-<F2>", spawn "feh --randomize --bg-fill ~/Pictures/Wallpapers/*")

    -- KB_GROUP Controls for mocp music player (SUPER-u followed by a key)
        , ("M-u p", spawn "mocp --play")
        , ("M-u l", spawn "mocp --next")
        , ("M-u h", spawn "mocp --previous")
        , ("M-u <Space>", spawn "mocp --toggle-pause")

    -- KB_GROUP Multimedia Keys
        , ("C-M1-m", spawn "amixer -c 0 sset 'Auto-Mute Mode' Enabled")

        , ("<XF86AudioPlay>",           spawn "mocp --play")
        , ("<XF86AudioPrev>",           spawn "mocp --previous")
        , ("<XF86AudioNext>",           spawn "mocp --next")
        , ("<XF86AudioMute>",           spawn "amixer set Master toggle")
        , ("<XF86AudioLowerVolume>",    spawn "amixer set Master 5%- unmute")
        , ("<XF86AudioRaiseVolume>",    spawn "amixer set Master 5%+ unmute")
        , ("<XF86MonBrightnessUp>",     spawn "xbacklight -inc 10")
        , ("<XF86MonBrightnessDown>",   spawn "xbacklight -dec 10")
        , ("<XF86HomePage>",            spawn "brave  https://www.youtube.com")
        , ("<Print>",                   spawn (maimsave))
        ]
    -- The following lines are needed for named scratchpads.
          where nonNSP          = WSIs (return (\ws -> W.tag ws /= "NSP"))
                nonEmptyNonNSP  = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "NSP"))
-- END_KEYS

main :: IO ()
main = do
    xmproc <- spawnPipe "xmobar -x 0 $HOME/.config/xmobar/xmobarrc"
    xmonad $ ewmh def
        { manageHook         = myManageHook <+> manageDocks
        , handleEventHook    = docksEventHook
                               <+> fullscreenEventHook
        , modMask            = myModMask
        , terminal           = myTerminal
        , startupHook        = myStartupHook
        , layoutHook         = myLayoutHook
        , workspaces         = myWorkspaces
        , borderWidth        = myBorderWidth
        , normalBorderColor  = myNormColor
        , focusedBorderColor = myFocusColor
        , logHook = dynamicLogWithPP $ namedScratchpadFilterOutWorkspacePP $ xmobarPP
              { ppOutput = \x -> hPutStrLn xmproc x
              , ppCurrent = xmobarColor color06 "" . wrap
                            ("<box type=Bottom width=2 mb=2 color=" ++ color06 ++ ">") "</box>"
              , ppVisible = xmobarColor color06 "" . clickable
              , ppHidden = xmobarColor color05 "" . wrap
                           ("<box type=Top width=2 mt=2 color=" ++ color05 ++ ">") "</box>" . clickable
              , ppHiddenNoWindows = xmobarColor color05 ""  . clickable
              , ppTitle = xmobarColor color16 "" . shorten 60
              , ppSep =  "<fc=" ++ color09 ++ "> <fn=1>|</fn> </fc>"
              , ppUrgent = xmobarColor color02 "" . wrap "!" "!"
              , ppExtras  = [windowCount]
              , ppOrder  = \(ws:l:t:ex) -> [ws,l]++ex++[t]
              }
        } `additionalKeysP` myKeys
