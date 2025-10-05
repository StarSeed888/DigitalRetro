import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application;
import Toybox.Math;

class RetroDigitalView extends WatchUi.WatchFace {
    
    // Matrix-style color palette
    private var _matrixGreen;
    private var _darkGreen;
    private var _black;
    private var _brightGreen;
    
    // Screen dimensions
    private var _screenWidth;
    private var _screenHeight;
    
    // Matrix rain effect variables
    private var _rainColumns;
    private var _rainChars;
    private var _rainPositions;
    private var _maxCharsPerColumn;
    private var _isAwake;

    // New variables for curved gauges
    private var _calorieGoal;
    private var _distanceGoal;
    private var _distanceUnit; // 0 = miles, 1 = kilometers
    private var _centerX;
    private var _centerY;
    private var _radius;




    function initialize() {
        WatchFace.initialize();
        
        // Load user's color theme preference and set colors
        loadColorTheme();
        
        // Load goal settings
        loadGoalSettings();
        // Start in awake state
        _isAwake = true;
    }

 function loadGoalSettings() as Void {
        _calorieGoal = Application.Properties.getValue("CalorieGoal");
        if (_calorieGoal == null) {
            _calorieGoal = 2000; // Default calorie goal
        }
        
        _distanceGoal = Application.Properties.getValue("DistanceGoal");
        if (_distanceGoal == null) {
            _distanceGoal = 5; // Default distance goal (5 miles/km)
        }
        
        _distanceUnit = Application.Properties.getValue("DistanceUnit");
        if (_distanceUnit == null) {
            _distanceUnit = 0; // Default to miles
        }
    }


    // Load color theme based on user settings
       function loadColorTheme() as Void {
        var colorTheme = Application.Properties.getValue("ColorTheme");
        if (colorTheme == null) {
            colorTheme = 0; // Default to Matrix Green
        }
        
        // Set colors based on selected theme
        switch (colorTheme) {
            case 0: // Matrix Green
                _matrixGreen = 0x00FF41;   // Standard matrix green
                _darkGreen = 0x008F11;     // Dark green for outlines
                _brightGreen = 0x80FF80;   // Much brighter green for highlights
                break;
            case 1: // Retro Cyan
                _matrixGreen = 0x00FFFF;   // Standard cyan
                _darkGreen = 0x008F8F;     // Dark cyan
                _brightGreen = 0x80FFFF;   // Much brighter cyan highlight
                break;
            case 2: // Retro Amber
                _matrixGreen = 0xFFB000;   // Standard amber
                _darkGreen = 0x8F6000;     // Dark amber
                _brightGreen = 0xFFE080;   // Much brighter amber highlight
                break;
            case 3: // Retro Purple
                _matrixGreen = 0xBF40FF;   // Standard purple
                _darkGreen = 0x6F258F;     // Dark purple
                _brightGreen = 0xE080FF;   // Much brighter purple highlight
                break;
            case 4: // Retro Red
                _matrixGreen = 0xFF4040;   // Standard red
                _darkGreen = 0x8F2525;     // Dark red
                _brightGreen = 0xFF8080;   // Much brighter red highlight
                break;
            case 5: // Retro Blue
                _matrixGreen = 0x4080FF;   // Standard blue
                _darkGreen = 0x25508F;     // Dark blue
                _brightGreen = 0x80B0FF;   // Much brighter blue highlight
                break;
            case 6: // Retro Orange (Commodore 64 style)
                _matrixGreen = 0xFF8000;   // Standard orange
                _darkGreen = 0x8F4000;     // Dark orange
                _brightGreen = 0xFFB050;   // Bright orange highlight
                break;
            case 7: // Retro Pink (Synthwave)
                _matrixGreen = 0xFF40A0;   // Standard hot pink
                _darkGreen = 0x8F2560;     // Dark pink
                _brightGreen = 0xFF80C0;   // Bright pink highlight
                break;
            case 8: // Retro Yellow (Amber alternative)
                _matrixGreen = 0xFFFF00;   // Standard yellow
                _darkGreen = 0x8F8F00;     // Dark yellow
                _brightGreen = 0xFFFF80;   // Bright yellow highlight
                break;
            case 9: // Retro White (Classic terminal)
                _matrixGreen = 0xE0E0E0;   // Standard light gray/white
                _darkGreen = 0x808080;     // Dark gray
                _brightGreen = 0xFFFFFF;   // Pure white highlight
                break;
            default: // Fallback to Matrix Green
                _matrixGreen = 0x00FF41;
                _darkGreen = 0x008F11;
                _brightGreen = 0x80FF80;
        }
        
        _black = 0x000000; // Black background (always the same)
    }
    // Handle settings changes
    function onSettingsChanged() as Void {
        loadColorTheme(); // Reload colors when settings change
        loadGoalSettings(); // Reload goals when settings change
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        _screenWidth = dc.getWidth();
        _screenHeight = dc.getHeight();
        // Calculate center and radius for curved gauges using proportions
        _centerX = (_screenWidth * 0.5).toNumber();
        _centerY = (_screenHeight * 0.5).toNumber();
        
        // Radius is 35% of the smaller screen dimension
        var minDimension = _screenWidth < _screenHeight ? _screenWidth : _screenHeight;
        _radius = (minDimension * 0.45).toNumber();

        // Initialize matrix rain effect
        initializeMatrixRain();
    }
    
    // Initialize the matrix rain effect
    function initializeMatrixRain() as Void {
        // Create columns every 20 pixels across the screen (wider spacing for visibility)
        var numColumns = (_screenWidth / 20).toNumber();
        _rainColumns = numColumns;
        
        // Calculate total characters needed (each column has multiple chars)
        _maxCharsPerColumn = 5; // More characters per stream
        var totalChars = numColumns * _maxCharsPerColumn;
        
        // Arrays to track all characters
        _rainChars = new Lang.Array[totalChars];
        _rainPositions = new Lang.Array[totalChars];
        
        // Retro computer characters for the rain
        var retroChars = ["0", "1", "|", "-", "+", "*", "=", ".", ":", ";", "#", "@", "%"];
        
        // Initialize each column with a stream of characters
        for (var i = 0; i < numColumns; i++) {
            // Initialize characters for this column
            for (var j = 0; j < _maxCharsPerColumn; j++) {
                var charIndex = (i * _maxCharsPerColumn) + j;
                _rainChars[charIndex] = retroChars[(i + j) % retroChars.size()];
                _rainPositions[charIndex] = (i * -40) - (j * 20); // Wider stagger for visibility
            }
        }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Clear screen with black background
        dc.setColor(_black, _black);
        dc.clear();
        
        // Draw the retro digital interface
        if (_isAwake) {
            drawMatrixRain(dc);  // Only draw rain when awake
        }
        drawCurvedGauges(dc);     // Draw the new curved gauges
        drawDigitalTime(dc);
        drawStatusBars(dc);
        drawDataElements(dc);
    }
    
    function calculateDistance(steps as Number) as Float {
        // Average stride length: 2.5 feet for men, 2.2 feet for women
        // Using 2.35 feet (0.716 meters) as a reasonable average
        var strideLength = 2.35; // feet
        var totalFeet = steps * strideLength;
        
        if (_distanceUnit == 0) {
            // Convert to miles (5280 feet per mile)
            return totalFeet / 5280.0;
        } else {
            // Convert to kilometers (feet to meters to kilometers)
            var totalMeters = totalFeet * 0.3048; // feet to meters
            return totalMeters / 1000.0; // meters to kilometers
        }
    }

 // Draw curved gauges for calories and distance using retro characters
   function drawCurvedGauges(dc as Dc) as Void {
        var activityInfo = ActivityMonitor.getInfo();
        if (activityInfo == null) {
            return;
        }
        
        // Calorie gauge (left side - from 135° to 225°)
        if (activityInfo has :calories && activityInfo.calories != null) {
            var calories = activityInfo.calories;
            var calorieProgress = calories.toFloat() / _calorieGoal.toFloat();
            if (calorieProgress > 1.0) { calorieProgress = 1.0; }
            
            var calorieColor = calorieProgress >= 1.0 ? _brightGreen : _matrixGreen;
            // Make label color consistent with STP - use main color normally, bright when goal reached
            var calorieLabelColor = calorieProgress >= 1.0 ? _brightGreen : _matrixGreen;
            drawRetroGauge(dc, 135, 90, calorieProgress, calorieColor, "CAL", calorieLabelColor);
        }
        
        // Distance gauge (right side - from 315° to 45°)
        if (activityInfo has :steps && activityInfo.steps != null) {
            var steps = activityInfo.steps;
            var actualDistance = calculateDistance(steps);
            var distanceProgress = actualDistance / _distanceGoal.toFloat();
            if (distanceProgress > 1.0) { distanceProgress = 1.0; }
            
            var distanceColor = distanceProgress >= 1.0 ? _brightGreen : _matrixGreen;
            // Make label color consistent with STP - use main color normally, bright when goal reached
            var distanceLabelColor = distanceProgress >= 1.0 ? _brightGreen : _matrixGreen;
            var distanceLabel = _distanceUnit == 0 ? "MI" : "KM";
            drawRetroGauge(dc, 315, 90, distanceProgress, distanceColor, distanceLabel, distanceLabelColor);
        }
    }



    function drawRetroGauge(dc as Dc, startAngle as Number, arcLength as Number, 
                           progress as Float, color as Number, label as String, labelColor as Number) as Void {
        
        var numSegments = 10; // Number of character segments in the gauge
        var angleStep = arcLength / numSegments;
        
        // Draw each segment of the gauge
        for (var i = 0; i < numSegments; i++) {
            var angle = startAngle + (i * angleStep);
            
            // Calculate position using proportional radius (right against the edge)
            var x = _centerX + (_radius * Math.cos(Math.toRadians(angle)));
            var y = _centerY + (_radius * Math.sin(Math.toRadians(angle)));
            
            // Determine if this segment should be filled
            var segmentProgress = (i + 1).toFloat() / numSegments.toFloat();
            var character = "";
            var segmentColor = _darkGreen;
            
            if (segmentProgress <= progress) {
                character = "|";  // Filled segment - same as battery/steps
                segmentColor = color;
            } else {
                character = "-";  // Empty segment - using dash for visibility
                segmentColor = _darkGreen;
            }
            
            // Draw the character
            dc.setColor(segmentColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x.toNumber(), y.toNumber(), Graphics.FONT_XTINY, character, 
                       Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw label using the passed labelColor (now matches STP behavior)
        var labelAngle = startAngle + (arcLength / 2); // Center the label
        var labelRadius = (_radius * 0.85).toNumber(); // Inside the arc
        var labelX = _centerX + (labelRadius * Math.cos(Math.toRadians(labelAngle)));
        var labelY = _centerY + (labelRadius * Math.sin(Math.toRadians(labelAngle)));
        
        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);  // Use the dynamic label color
        dc.drawText(labelX.toNumber(), labelY.toNumber(), Graphics.FONT_XTINY, label, 
                   Graphics.TEXT_JUSTIFY_CENTER);
    }



    // Draw Matrix-style falling rain effect with multiple character streams
    function drawMatrixRain(dc as Dc) as Void {
        if (_rainChars == null) {
            return; // Not initialized yet
        }
        
        // Draw and update each column's stream
        for (var i = 0; i < _rainColumns; i++) {
            var x = i * 20 + 10; // Column position (wider spacing)
            
            // Draw each character in this column's stream
            for (var j = 0; j < _maxCharsPerColumn; j++) {
                var charIndex = (i * _maxCharsPerColumn) + j;
                var y = _rainPositions[charIndex];
                
                // Draw character if it's on screen
                if (y > -20 && y < _screenHeight + 20) {
                    // First character in stream is brighter
                    if (j == 0) {
                        dc.setColor(_matrixGreen, Graphics.COLOR_TRANSPARENT);
                    } else {
                        dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
                    }
                    dc.drawText(x, y, Graphics.FONT_TINY, _rainChars[charIndex], Graphics.TEXT_JUSTIFY_CENTER);
                }
                
                // Update position - much faster movement for visibility during short wake periods
                _rainPositions[charIndex] = _rainPositions[charIndex] + 12;
            }
            
            // Reset stream when lead character falls off screen
            var leadCharIndex = i * _maxCharsPerColumn;
            if (_rainPositions[leadCharIndex] > _screenHeight + 40) {
                // Reset all characters in this column's stream
                var retroChars = ["0", "1", "|", "-", "+", "*", "=", ".", ":", ";", "#", "@", "%"];
                for (var k = 0; k < _maxCharsPerColumn; k++) {
                    var charIndex = (i * _maxCharsPerColumn) + k;
                    _rainPositions[charIndex] = -40 - (k * 20); // Space characters 20 pixels apart
                    // Change character more frequently
                    if (System.getClockTime().sec % 2 == 0) {
                        _rainChars[charIndex] = retroChars[(i + k + System.getClockTime().sec) % retroChars.size()];
                    }
                }
            }
        }
    }
    
    // Draw large digital time with block wireframe style
    function drawDigitalTime(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        var minute = clockTime.min;
        var second = clockTime.sec;
        
        // Convert to 12-hour format if needed
        var is24Hour = System.getDeviceSettings().is24Hour;
        var amPm = "";
        if (!is24Hour) {
            amPm = (hour >= 12) ? "PM" : "AM";
            if (hour == 0) {
                hour = 12;
            } else if (hour > 12) {
                hour = hour - 12;
            }
        }
        
        // Build time string with explicit formatting
        var hourStr = hour.toString();
        if (hour < 10) { hourStr = "0" + hourStr; }
        
        var minuteStr = minute.toString();
        if (minute < 10) { minuteStr = "0" + minuteStr; }
        
        var timeString = hourStr + ":" + minuteStr;
        
        // Draw large block-style time in center of screen
        var centerX = (_screenWidth / 2).toNumber();
        var centerY = (_screenHeight / 2).toNumber();
        drawBlockText(dc, timeString, centerX , centerY * 0.70, 28, _matrixGreen);
        
        // Draw seconds in smaller text below main time
        var secondString = second.toString();
        if (second < 10) { secondString = "0" + secondString; }
        //drawBlockText(dc, secondString, centerX, centerY + 25, 16, _darkGreen);
        
        // Draw AM/PM if needed - small indicator positioned upper right
        if (!is24Hour && amPm.length() > 0) {
            dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX * 1.55, centerY * 0.75, Graphics.FONT_TINY, amPm,
                       Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
    
    // Draw status bars using ASCII-style characters
    function drawStatusBars(dc as Dc) as Void {
        dc.setColor(_matrixGreen, Graphics.COLOR_TRANSPARENT);
        
        // Battery status bar
        var battery = System.getSystemStats().battery;
        var batteryBars = (battery / 100.0 * 10).toNumber();
        var batteryString = "BAT:[";
        for (var i = 0; i < 10; i++) {
            if (i < batteryBars) {
                batteryString += "|";
            } else {
                batteryString += " ";
            } 
        }
        batteryString += "]";

     // Change battery color based on charge level
        var batteryColor;
        if (battery >= 60) {
            batteryColor = _matrixGreen;    // High battery - normal theme color
        } else if (battery >= 30) {
            batteryColor = _brightGreen;    // Medium battery - bright color (warning)
        } else {
            batteryColor = 0xFF0000;        // Low battery - red (critical warning)
        }
        
        dc.setColor(batteryColor, Graphics.COLOR_TRANSPARENT);


        // Position battery at upper 10% of screen
        var batteryY = (_screenHeight * 0.10).toNumber();
        dc.drawText((_screenWidth / 2).toNumber(), batteryY, Graphics.FONT_XTINY, batteryString, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Steps status bar (if available)
        var activityInfo = ActivityMonitor.getInfo();
        if (activityInfo has :steps && activityInfo.steps != null) {
            var steps = activityInfo.steps;
            var stepGoal = activityInfo.stepGoal != null ? activityInfo.stepGoal : 10000;
            var stepBars = (steps.toFloat() / stepGoal.toFloat() * 10).toNumber();
            if (stepBars > 10) { stepBars = 10; }
            
            var stepString = "STP:[";
            for (var i = 0; i < 10; i++) {
                if (i < stepBars) {
                    stepString += "|";
                } else {
                    stepString += " ";
                }
            }
            stepString += "]";

            // Change color based on whether step goal is reached
            var stepProgress = steps.toFloat() / stepGoal.toFloat();
            var stepColor = stepProgress >= 1.0 ? _brightGreen : _matrixGreen;
            dc.setColor(stepColor, Graphics.COLOR_TRANSPARENT);

            // Position steps at lower 15% of screen (85% down from top)
            var stepsY = (_screenHeight * 0.75).toNumber();
            dc.drawText((_screenWidth / 2).toNumber(), stepsY, Graphics.FONT_XTINY, stepString, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
    
    // Draw additional data elements with retro styling
    function drawDataElements(dc as Dc) as Void {
        dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
        
        // Current date - simplified approach
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        
        // Simple date display without complex formatting
        var dateString = today.day.toString() + "." + today.month.toString() + "." + (today.year % 100).toString();
        
        // Position date at lower 15% of screen (90% down from top)
        var centerX = (_screenWidth / 2).toNumber();
        var dateY = (_screenHeight * 0.90).toNumber();
        dc.drawText(centerX, dateY, Graphics.FONT_XTINY, dateString, Graphics.TEXT_JUSTIFY_CENTER);
        
        // System status indicators - move connection status to header position
        var settings = System.getDeviceSettings();
        var connectionString = settings.phoneConnected ? ">> CONN:ON <<" : ">> CONN:OFF <<";
        
        // Display connection status at header position (30% from top)
        dc.setColor(_brightGreen, Graphics.COLOR_TRANSPARENT);
        var headerY = (_screenHeight * 0.30).toNumber();
        dc.drawText((_screenWidth / 2).toNumber(), headerY, Graphics.FONT_XTINY, connectionString, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Custom function to draw block-style text with wireframe effect
    function drawBlockText(dc as Dc, text as String, x as Number, y as Number, size as Number, color as Number) as Void {
        // Select font based on size parameter
        var font;
        if (size >= 24) {
            font = Graphics.FONT_NUMBER_HOT;        // Large numbers for main time
        } else if (size >= 16) {
            font = Graphics.FONT_LARGE;             // Medium size for seconds
        } else {
            font = Graphics.FONT_MEDIUM;            // Small size for AM/PM
        }
        
        // Draw outline/shadow effect first
        dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + 2, y + 2, font, text, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw main text
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Add wireframe border effect
        dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        var textDimensions = dc.getTextDimensions(text, font);
        var textWidth = textDimensions[0];
        var textHeight = textDimensions[1];
        
        // Draw border around text
        var borderX = x - textWidth / 2 - 5;
        var borderY = y - textHeight / 2 - 5;
        var borderWidth = textWidth + 10;
        var borderHeight = textHeight + 10;
        
        //dc.drawRectangle(borderX, borderY, borderWidth, borderHeight);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        _isAwake = true;
        // Don't reinitialize - just resume where we left off for immediate visibility
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        _isAwake = false;
        // Rain will stop drawing but arrays remain in memory
    }

}
