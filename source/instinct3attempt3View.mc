import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;
import Toybox.Position;




const UPDATE_CYCLE_MINUTES = 10; // <- only update big screen once every UPDATE_CYCLE_MINUTES minutes
const USING_45_MM_MODEL = true; // <- true: render for 45 mm model, false: render for 50 mm model.
const SHOW_BATTERY_PCT_IMMEDIATELY_UPON_RETURN_TO_SCREEN = true; // <- other option is to have sub screen show the same minute as big screen
const SUN_RETRY_SECONDS = 300;     // retry every 5 minutes until success
const SUN_EMOJI = " ☀️ "; // <- remove wihtespace if necessary
const EXP_SUN_EMOJI = "🧊🤘🔥"; // <- will only render on debug builds

/* // uncoment when i decide to also support 50 mm instinct models, save Imem and caching for now
// dimension coordinates of the 'submarine screen' of the solar 45 mm model.
const _SUB_X_45 = 115;
const _SUB_Y_45 = 5;
const _SUB_W_45 = 55;
const _SUB_H_45 = 55;

// dimension coordinates of the 'submarine screen' of the solar 50 mm model.
const _SUB_X_50 = 32; //FIXME: GET CORRECT COORDINATES
const _SUB_Y_50 = 70; //FIXME: GET CORRECT COORDINATES
const _SUB_W_50 = 112; //FIXME: GET CORRECT COORDINATES
const _SUB_H_50 = 80; //FIXME: GET CORRECT COORDINATES
*/

/* // uncoment when i decide to also support 50 mm instinct models
var _SUB_X;
var _SUB_Y;
var _SUB_W;
var _SUB_H;

// _m
var __M_X;
var __M_Y;
var __M_W;
var __M_H;

// m_
var _M__X;
var _M__Y;
var _M__W;
var _M__H;

// _h
var __H_X;
var __H_Y;
var __H_W;
var __H_H;

// h_
var _H__X;
var _H__Y;
var _H__W;
var _H__H;
*/

// V comment V when V I V decide V to V also V support V 50mm V models V
const _SUB_X = 115;
const _SUB_Y = 5;
const _SUB_W = 55;
const _SUB_H = 55;

// _m
const __M_X = 0; //FIXME: GET CORRECT COORDINATES
const __M_Y = 0; //FIXME: GET CORRECT COORDINATES
const __M_W = 0; //FIXME: GET CORRECT COORDINATES
const __M_H = 0; //FIXME: GET CORRECT COORDINATES

// m_
const _M__X = 0; //FIXME: GET CORRECT COORDINATES
const _M__Y = 0; //FIXME: GET CORRECT COORDINATES
const _M__W = 0; //FIXME: GET CORRECT COORDINATES
const _M__H = 0; //FIXME: GET CORRECT COORDINATES

// _h
const __H_X = 0; //FIXME: GET CORRECT COORDINATES
const __H_Y = 0; //FIXME: GET CORRECT COORDINATES
const __H_W = 0; //FIXME: GET CORRECT COORDINATES
const __H_H = 0; //FIXME: GET CORRECT COORDINATES

// h_
const _H__X = 0; //FIXME: GET CORRECT COORDINATES
const _H__Y = 0; //FIXME: GET CORRECT COORDINATES
const _H__W = 0; //FIXME: GET CORRECT COORDINATES
const _H__H = 0; //FIXME: GET CORRECT COORDINATES
// ^ comment ^ when ^ I ^ decide ^ to ^ also ^ support ^ 50mm ^ models ^


//TODO: create seperate updating windows for _m m_ _h h_, to keep screen updates to a minimum!
//TODO: after above rows completion, add onPartialUpdate() call to _force_redraw_entire_screen()



// Debug flags
const DEBUG_MODE                 = false; // master switch
const DEBUG_SHOW_SECONDS_IN_HH_MM = true; // DEBUG: show seconds in both HH and MM slots, set to false to restore real time
const DEBUG_INVERT_SUB_COLOR = false;
const DEBUG_INVERT_MAIN_COLOR = true;
const DEBUG_SUN_TIMES = true;  // <- update sun cache every second
const DEBUG_SUN_EMOJI = true; // <- use EXP_SUN_EMOJI

// Helper: only true if global DEBUG_MODE is on *and* the specific flag is true
function debug(flag) {
    return DEBUG_MODE and flag;
}


class instinct3attempt3View extends WatchUi.WatchFace {

    var _bigTimeFont; // FontReference
    var _bigTimeHalfFont;
    var _w; // <- width
    var _h; // <- height
    var _battPctX; // battery % x
    var _battPctY; // battery % y
    var _extraMinutesDigitX;
    var _extraMinutesDigitY;
    var _yTopRow;     // reference row for top texts
    var _yDateRow;     // date below
    var _dateX;
    var _yTime;  // big time center
    var _xTime;  // big time center
    var _ySunRow; // sunrise/sunset
    var _xSunRow; // sunrise/sunset
    var _hh;
    var _mm;
    var _isInitialised = false;
    var _show_battery_now = false;
    var clk;

    // --- Sun cache (updates once per day, or when forced) ---
    var _sunCacheKey = null;           // String like "2025-12-12"
    var _sunriseStrCached = "--:--";   // String
    var _sunsetStrCached  = "--:--";   // String
    var _forceSunUpdate   = true;      // Set true when you want to refresh ASAP
    var _sunLastAttempt = 0;           // seconds



    function initialize() {
        WatchUi.WatchFace.initialize();
        _bigTimeFont = WatchUi.loadResource(Rez.Fonts.BigTime);
        _bigTimeHalfFont = WatchUi.loadResource(Rez.Fonts.BigTimeHalf);
        /* // uncoment when i decide to also support 50 mm instinct models, save Imem and caching for now
        if (USING_45_MM_MODEL){
            _SUB_X = _SUB_X_45;
            _SUB_Y = _SUB_Y_45;
            _SUB_W = _SUB_W_45;
            _SUB_H = _SUB_H_45;
        } else {
            _SUB_X = _SUB_X_50;
            _SUB_Y = _SUB_Y_50;
            _SUB_W = _SUB_W_50;
            _SUB_H = _SUB_H_50;
        }
        */

        _forceSunUpdate   = true;
        _sunLastAttempt = 0;
    }

    function onLayout(dc as Dc) {
        _w = dc.getWidth();
        _h = dc.getHeight();
        _yTopRow  = 10;     // reference row for top texts
        _yDateRow = 40;     // date below
        _dateX = (_w / 2) - 80;
        _yTime    = (_h / 2)+15;  // big time center
        _xTime =  (_w / 2);
        _ySunRow  = _h - 26; // sunrise/sunset
        _xSunRow  = (_w / 2);
        _battPctX = _w - 30; // battery % x
        _battPctY = _yTopRow + 10; // battery % y
        _battPctX = _w - 30; // battery % x
        _battPctY = _yTopRow + 10; // battery % y
        _extraMinutesDigitX = _battPctX ;
        _extraMinutesDigitY = _battPctY ;
        _sunLastAttempt = 0;
        _force_redraw_entire_screen();
    }

    function onShow() {
        // We are visible again (returned from glances/notifications)
        _force_redraw_entire_screen();
    }

    function _force_redraw_entire_screen() as Void{
        _isInitialised = false;
        _show_battery_now = SHOW_BATTERY_PCT_IMMEDIATELY_UPON_RETURN_TO_SCREEN;
    }

    //var _lastDrawnSlot = -1;

    function onUpdate(dc as Dc) {
        clk = System.getClockTime();

        if (debug(DEBUG_SUN_TIMES)){_forceSunUpdate   = true;} // <- force multiple sun updates during debugging

        if (!_isInitialised){ // <- handle returning from notifications or gestures
            _redrawEntireScreen(dc);
            _isInitialised = true;
        }

        // allow every second update only while debugging
        if ((!debug(true)) && (clk.sec != 0)){return;}

        var time_meausrement = clk.min;

        if (debug(DEBUG_SHOW_SECONDS_IN_HH_MM)){time_meausrement=clk.sec;}

        if (time_meausrement % UPDATE_CYCLE_MINUTES == 0) { // <- skip draws under UPDATE_CYCLE_MINUTES minute intervals (alligned with round hours, not startup time)
            _redrawMainScreen(dc);
        }
        _redrawSubmarine(dc);

    }

    function _redrawEntireScreen(dc as Dc) as Void {
        _redrawMainScreen(dc);
        _redrawSubmarine(dc);
    }
    
    function _redrawMainScreen(dc as Dc) as Void {
        if (debug(DEBUG_INVERT_MAIN_COLOR)){
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }        dc.clear();



        if (debug(DEBUG_SHOW_SECONDS_IN_HH_MM)) {
            _hh = clk.sec;
            _mm = clk.sec;
        } else {
            _hh = clk.hour;
            _mm = clk.min;
        }

        var timeStr = Lang.format("$1$:$2$", [
            _hh.format("%02d"),
            _mm.format("%02d")
        ]);

        // ---------- Date + DOW ----------
        var now  = Time.now();
        var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);

        //var dowNames = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ];
        var dowNames = [ "ראשון", "שני", "שלישי", "רביעי", "חמישי", "שישי", "שבת" ];
        var dow      = dowNames[info.day_of_week - 1];

        var dayStr   = info.day.format("%02d");
        var monthStr = info.month.format("%02d");
        var yearStr  = info.year.format("%02d"); // short year

        var dateStr = Lang.format("$1$/$2$/$3$", [
            dayStr,
            monthStr,
            yearStr
        ]);

        /*
        // ---------- Battery % ----------
        var stats      = System.getSystemStats();
        var battPct    = stats.battery; // 0–100
        var battPctStr = Lang.format("$1$%", [ battPct.format("%d") ]);
        */

        // ---------- Sunrise / Sunset ----------
        _updateSunCacheIfNeeded();
        // Sunset intentionally on LEFT, sunrise intentionally on RIGHT
        // Avoid emoji if your device font renders it inconsistently.
        var used_sun_emoji = SUN_EMOJI;
        if(debug(DEBUG_SUN_EMOJI)){used_sun_emoji = EXP_SUN_EMOJI;}
        //const  = true; // <- use 
        var sunLine = Lang.format("$1$$2$$3$", [
            _sunsetStrCached,
            used_sun_emoji,
            _sunriseStrCached
        ]);

        // ---------- Layout coordinates ----------



        // DOW: exactly at (61,18) with center justification
        dc.drawText(
            65,
            5,
            Graphics.FONT_LARGE,
            dow,
            Graphics.TEXT_JUSTIFY_CENTER
        );



        // Date: a bit left of center
        dc.drawText(
            _dateX,
            _yDateRow,
            Graphics.FONT_SMALL,
            dateStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Big time in center
        dc.drawText(
            _xTime,
            _yTime,
            _bigTimeFont,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Sunrise / sunset: slightly to the right of center
        dc.drawText(
            _xSunRow,
            _ySunRow,
            Graphics.FONT_SMALL,
            sunLine,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }


    function _redrawSubmarine(dc as Dc) as Void {
        dc.setClip(_SUB_X, _SUB_Y, _SUB_W, _SUB_H);

        // Clear ONLY that region (clear respects clip)
        if (debug(DEBUG_INVERT_SUB_COLOR)){
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }

        dc.clear();

    
        var extraMin = clk.min % UPDATE_CYCLE_MINUTES;

        if (debug(DEBUG_SHOW_SECONDS_IN_HH_MM)){ extraMin = clk.sec % UPDATE_CYCLE_MINUTES; }
        
        if (extraMin == 0 || _show_battery_now){
            // Battery %: middle of 'submarine screen'
            dc.drawText(
                _battPctX,
                _battPctY,
                Graphics.FONT_LARGE,
                _getBatteryPctStr(),
                Graphics.TEXT_JUSTIFY_CENTER
            );
            _show_battery_now = false;
        } else {
            // Extra minute digit
            dc.drawText(
                _extraMinutesDigitX,
                _extraMinutesDigitY,
                _bigTimeHalfFont,
                extraMin,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        dc.clearClip();
    }

    function _getBatteryPctStr() as String {
        var stats   = System.getSystemStats();
        var battPct = stats.battery; // 0–100
        return Lang.format("$1$%", [ battPct.format("%d") ]);
    }

    /*
    // Helper: get sunrise/sunset as "HH:MM", with safe fallbacks
    function _getSunTimes() {
        var result = {
            :sunset => "--:--",
            :sunrise  => "--:--"
        };

        if (!(Toybox has :Weather)) {
            return result;
        }

        var cond = Weather.getCurrentConditions();
        if (cond == null) {
            return result;
        }

        var loc  = cond.observationLocationPosition;
        var date = cond.observationTime;

        if (loc == null || date == null) {
            return result;
        }

        var sr = Weather.getSunrise(loc, date);
        var ss = Weather.getSunset(loc, date);

        if (sr != null) {
            var gsr = Time.Gregorian.info(sr, Time.FORMAT_SHORT);
            result[:sunrise] = Lang.format("$1$:$2$", [
                gsr.hour.format("%02d"),
                gsr.min.format("%02d")
            ]);
        }

        if (ss != null) {
            var gss = Time.Gregorian.info(ss, Time.FORMAT_SHORT);
            result[:sunset] = Lang.format("$1$:$2$", [
                gss.hour.format("%02d"),
                gss.min.format("%02d")
            ]);
        }

        return result;
    }
    */

    function _todayKey() as String {
        var now = Time.now();
        var gi  = Time.Gregorian.info(now, Time.FORMAT_SHORT);

        // YYYY-MM-DD
        return Lang.format("$1$-$2$-$3$", [
            gi.year.format("%04d"),
            gi.month.format("%02d"),
            gi.day.format("%02d")
        ]);
    }

    function _updateSunCacheIfNeeded() as Void {
        var key = _todayKey();
        var nowSec = Time.now().value();

        var missing = (_sunriseStrCached == "--:--" || _sunsetStrCached == "--:--");
        var retryDue = missing && ((nowSec - _sunLastAttempt >= SUN_RETRY_SECONDS)||(!_isInitialised)); // <- if missing, try every 5 minutes and every screen redrawing

        if (_forceSunUpdate || _sunCacheKey == null || _sunCacheKey != key || retryDue ) {
            _sunCacheKey = key;
            _forceSunUpdate = false;
            _sunLastAttempt = nowSec;

            _computeSunTimesIntoCache();
        }
    }


    function _computeSunTimesIntoCache() as Void {
        var sunriseStr = "--:--";
        var sunsetStr  = "--:--";

        if (!(Toybox has :Weather)) {
            _sunriseStrCached = sunriseStr;
            _sunsetStrCached  = sunsetStr;
            return;
        }

        var loc = null;

        // 1) Weather observation location (best if present)
        try {
            var cond = Weather.getCurrentConditions();
            if (cond != null) {
                loc = cond.observationLocationPosition;
            }
        } catch (ex) { }

        // 2) Fallback: last known device position
        if (loc == null && (Toybox has :Position)) {
            try {
                var pinfo = Position.getInfo();
                if (pinfo != null) {
                    loc = pinfo.position;
                }
            } catch (ex2) { }
        }

        if (loc == null) {
            // keep cached values; retry later (via throttle)
            return;
        }

        // Anchor = today at noon
        var now = Time.now();
        var gi  = Time.Gregorian.info(now, Time.FORMAT_SHORT);

        var anchor = Time.Gregorian.moment({
            :year  => gi.year,
            :month => gi.month,
            :day   => gi.day,
            :hour  => 12,
            :min   => 0,
            :sec   => 0
        });

        try {
            var sr = Weather.getSunrise(loc, anchor);
            var ss = Weather.getSunset(loc, anchor);

            if (sr != null) {
                var gsr = Time.Gregorian.info(sr, Time.FORMAT_SHORT);
                sunriseStr = Lang.format("$1$:$2$", [
                    gsr.hour.format("%02d"),
                    gsr.min.format("%02d")
                ]);
            }

            if (ss != null) {
                var gss = Time.Gregorian.info(ss, Time.FORMAT_SHORT);
                sunsetStr = Lang.format("$1$:$2$", [
                    gss.hour.format("%02d"),
                    gss.min.format("%02d")
                ]);
            }
        } catch (ex3) { }

        _sunriseStrCached = sunriseStr;
        _sunsetStrCached  = sunsetStr;
    }

}
