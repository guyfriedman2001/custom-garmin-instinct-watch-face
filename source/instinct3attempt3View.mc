import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;



const UPDATE_CYCLE_MINUTES = 10; // <- only update big screen once every UPDATE_CYCLE_MINUTES minutes
const USING_45_MM_MODEL = true; // <- true: render for 45 mm model, false: render for 50 mm model.

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


var _SUB_X;
var _SUB_Y;
var _SUB_W;
var _SUB_H;



// Debug flags
const DEBUG_MODE                 = false; // master switch
const DEBUG_SHOW_SECONDS_IN_HH_MM = true; // DEBUG: show seconds in both HH and MM slots, set to false to restore real time
const DEBUG_INVERT_SUB_COLOR = true;
const DEBUG_INVERT_MAIN_COLOR = true;

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
    var clk;


    function initialize() {
        WatchUi.WatchFace.initialize();
        _bigTimeFont = WatchUi.loadResource(Rez.Fonts.BigTime);
        _bigTimeHalfFont = WatchUi.loadResource(Rez.Fonts.BigTimeHalf);
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
        _isInitialised = false;
    }

    function onShow() {
        // We are visible again (returned from glances/notifications)
        _isInitialised = false;
    }

    //var _lastDrawnSlot = -1;

    function onUpdate(dc as Dc) {
        clk = System.getClockTime();

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
        var sun = _getSunTimes();
        var sunLine = Lang.format("$1$ ☀️ $2$", [
            sun[:sunset],
            sun[:sunrise]
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
        
        if (extraMin == 0){
            // Battery %: middle of 'submarine screen'
            dc.drawText(
                _battPctX,
                _battPctY,
                Graphics.FONT_LARGE,
                _getBatteryPctStr(),
                Graphics.TEXT_JUSTIFY_CENTER
            );
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
}
