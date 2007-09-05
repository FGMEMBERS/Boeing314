# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ================
# SPERRY AUTOPILOT
# ================

Autopilot = {};

Autopilot.new = func {
   obj = { parents : [Autopilot],

           AUTOPILOTSEC : 2.0
         };
   return obj;
};

# pitch hold
Autopilot.appitchexport = func {
    mode = getprop("/autopilot/locks/altitude");
    if( mode != "pitch-hold" ) {
        mode = "pitch-hold";
        pitchdeg = getprop("/orientation/pitch-deg");
        setprop("/autopilot/settings/target-pitch-deg",pitchdeg);
    }
    else {
        mode = "";
    }

    setprop("/autopilot/locks/altitude",mode);
}

# heading hold
Autopilot.apheadingexport = func {
    mode = getprop("/autopilot/locks/heading");
    if( mode != "dg-heading-hold" ) {
        mode = "dg-heading-hold";
        headingdeg = getprop("/orientation/heading-magnetic-deg");
        setprop("/autopilot/settings/heading-bug-deg",headingdeg);
        mode2 = "horizontal";
    }
    else {
        mode = "";
        mode2 = "";
    }

    setprop("/autopilot/locks/heading",mode);
    setprop("/autopilot/locks/heading2",mode2);
}

# altitude hold
Autopilot.apaltitudeexport = func {
    mode = getprop("/autopilot/locks/altitude");
    if( mode != "altitude-hold" ) {
        mode = "altitude-hold";
        altitudeft = getprop("/instrumentation/altimeter/indicated-altitude-ft");
        setprop("/autopilot/settings/target-altitude-ft",altitudeft);
    }
    else {
        mode = "";
    }

    setprop("/autopilot/locks/altitude",mode);
}

# pitch horizon :
Autopilot.pitchexport = func( sign ) {
    altitudemode = getprop("/autopilot/locks/altitude");
    if( altitudemode != nil and altitudemode != "" ) {
        pitchdeg = getprop("/autopilot/settings/target-pitch-deg");
        if( pitchdeg == nil ) {
            pitchdeg = 0.0;
        }

        pitchdeg = pitchdeg + 0.15 * sign;
        if( pitchdeg > 12 ) {
            pitchdeg = 12;
        }
        elsif( pitchdeg < -12 ) {
            pitchdeg = -12;
        }
        setprop("/autopilot/settings/target-pitch-deg",pitchdeg);

        result = constant.TRUE;
    }
    else {
        result = constant.FALSE;
    }

    return result;
}

# heading bug :
# - sign
Autopilot.headingexport = func {
    sign = arg[ 0 ];

    headingdeg = getprop("/autopilot/settings/heading-bug-deg");
    if( headingdeg == nil ) {
        headingdeg = 0.0;
    }

    headingdeg = headingdeg + 1 * sign;
    if( headingdeg > 360 ) {
        headingdeg = 1;
    }
    elsif( headingdeg < 0 ) {
          headingdeg = 359;
    }
    setprop("/autopilot/settings/heading-bug-deg",headingdeg);
}

# TO DO : move to copilot
Autopilot.schedule = func {
   # adding a waypoint swaps to true heading hold
   mode = getprop("/autopilot/locks/heading");
   if( mode == "true-heading-hold" ) {
       mode2 = getprop("/autopilot/locks/heading2");

       # keeps sperry autopilot
       if( mode2 == "horizontal" ) { 
           mode =  "dg-heading-hold";
       }
       # autopilot not activated, that was a new waypoint
       else {
           mode = "";
       }
       setprop("/autopilot/locks/heading",mode);
   }
}
