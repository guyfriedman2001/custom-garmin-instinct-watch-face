import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;


// Debug flags
const DEBUG_MODE                 = false; // master switch
const DEBUG_SHOW_SECONDS_IN_HH_MM = false; // DEBUG: show seconds in both HH and MM slots, set to false to restore real time

// Helper: only true if global DEBUG_MODE is on *and* the specific flag is true
function debug(flag) {
    return DEBUG_MODE and flag;
}

class instinct3attempt3View extends WatchUi.WatchFace {

    var _bigTimeFont; // FontReference

    function initialize() {
        WatchUi.WatchFace.initialize();
        _bigTimeFont = WatchUi.loadResource(Rez.Fonts.BigTime);
    }

    function onLayout(dc as Dc) {
        // We draw everything manually in onUpdate
    }

    function onUpdate(dc as Dc) {

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        /* TODO: uncomment after debugging digits!
        // ---------- Time (HH:MM, big number font) ----------
        var clk = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [
            clk.hour.format("%02d"),
            clk.min.format("%02d")
        ]);
        */

        // ---------- Time (HH:MM, big number font) ----------
        var clk = System.getClockTime();



        var hh;
        var mm;

        if (debug(DEBUG_SHOW_SECONDS_IN_HH_MM)) {
            hh = clk.sec;
            mm = clk.sec;
        } else {
            hh = clk.hour;
            mm = clk.min;
        }

        var timeStr = Lang.format("$1$:$2$", [
            hh.format("%02d"),
            mm.format("%02d")
        ]);


        /*
        // Largest built-in numeric font available on this device
        var timeFont = Graphics.FONT_NUMBER_HOT;
        */

        
        // Custom bitmap font for big time digits
        //var timeFont = Rez.Fonts.BigTime;
        

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

        // ---------- Battery % ----------
        var stats      = System.getSystemStats();
        var battPct    = stats.battery; // 0–100
        var battPctStr = Lang.format("$1$%", [ battPct.format("%d") ]);

        // ---------- Sunrise / Sunset ----------
        var sun = _getSunTimes();
        var sunLine = Lang.format("$1$ ◊ $2$", [
            sun[:sunrise],
            sun[:sunset]
        ]);

        // ---------- Layout coordinates ----------

        var yTopRow  = 10;     // reference row for top texts
        var yDateRow = 26;     // date below
        var yTime    = h / 2;  // big time center
        var ySunRow  = h - 26; // sunrise/sunset

        // DOW: exactly at (61,18) with center justification
        dc.drawText(
            65,
            5,
            Graphics.FONT_LARGE,
            dow,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        /*
        // Battery %: keep near top-right
        dc.drawText( // <- use this after getting the battery icon to work
            w - 30,
            yTopRow + 25,
            Graphics.FONT_SMALL,
            battPctStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        */

        // Battery %: middle of 'submarine screen'
        dc.drawText( // <- use this after getting the battery icon to work
            w - 30,
            yTopRow + 10,
            Graphics.FONT_SMALL,
            battPctStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Date: a bit left of center
        var dateX = (w / 2) - 80;
        dc.drawText(
            dateX,
            yDateRow + 15,
            Graphics.FONT_SMALL,
            dateStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Big time in center
        dc.drawText(
            w / 2,
            yTime + 15,
            _bigTimeFont,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Sunrise / sunset: slightly to the right of center
        dc.drawText(
            (w / 2) + 4,
            ySunRow,
            Graphics.FONT_SMALL,
            sunLine,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    // Helper: get sunrise/sunset as "HH:MM", with safe fallbacks
    function _getSunTimes() {
        var result = {
            :sunrise => "--:--",
            :sunset  => "--:--"
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
