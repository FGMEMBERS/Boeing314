# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ================
# SPERRY AUTOPILOT
# ================

Autopilot = {};

Autopilot.new = func {
   var obj = { parents : [Autopilot,System]
             };

   obj.init();

   return obj;
};

Autopilot.init = func {
   me.inherit_system("/systems/autopilot");
}

# pitch hold
Autopilot.appitchexport = func {
    var pitchdeg = 0.0;
    var mode = me.itself["autopilot"].getChild("altitude").getValue();

    if( mode != "pitch-hold" ) {
        mode = "pitch-hold";
        pitchdeg = me.noinstrument["pitch"].getValue();
        me.itself["autopilot-set"].getChild("target-pitch-deg").setValue(pitchdeg);
    }
    else {
        mode = "";
    }

    me.itself["autopilot"].getChild("altitude").setValue(mode);
}

# heading hold
Autopilot.apheadingexport = func {
    var headingdeg = 0.0;
    var mode = me.itself["autopilot"].getChild("heading").getValue();

    if( mode != "dg-heading-hold" ) {
        mode = "dg-heading-hold";
        headingdeg = me.noinstrument["heading"].getValue();
        me.itself["autopilot-set"].getChild("heading-bug-deg").setValue(headingdeg);
    }
    else {
        mode = "";
    }

    me.itself["autopilot"].getChild("heading").setValue(mode);
}

# altitude hold
Autopilot.apaltitudeexport = func {
    var altitudeft = 0.0;
    var mode = me.itself["autopilot"].getChild("altitude").getValue();

    if( mode != "altitude-hold" ) {
        mode = "altitude-hold";
        altitudeft = me.dependency["altimeter"].getValue();
        me.itself["autopilot-set"].getChild("target-altitude-ft").setValue(altitudeft);

        me.itself["autopilot"].getChild("altitude").setValue(mode);
    }
    else {
        me.appitchexport();
    }
}

# manual setting of heading
Autopilot.headingexport = func( coef ) {
    var headingmode = me.itself["autopilot"].getChild("heading").getValue();
    var result = constant.FALSE;

    if( headingmode != nil and headingmode == "dg-heading-hold" ) {
        var headingdeg = me.itself["autopilot-set"].getChild("heading-bug-deg").getValue();

        headingdeg = headingdeg + 1.0 * coef;
        headingdeg = constant.truncatenorth(headingdeg);
        
        me.itself["autopilot-set"].getChild("heading-bug-deg").setValue(headingdeg);

        result = constant.TRUE;
    }

    return result;
}

# manual setting of pitch
Autopilot.pitchexport = func( sign ) {
    var pitchdeg = 0.0;
    var altitudemode = me.itself["autopilot"].getChild("altitude").getValue();
    var result = constant.FALSE;

    if( altitudemode != nil and altitudemode != "" ) {
        pitchdeg = me.itself["autopilot-set"].getChild("target-pitch-deg").getValue();
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
        me.itself["autopilot-set"].getChild("target-pitch-deg").setValue(pitchdeg);

        result = constant.TRUE;
    }

    return result;
}

# heading bug
Autopilot.headingexport = func( sign ) {
    var headingdeg = me.itself["autopilot-set"].getChild("heading-bug-deg").getValue();

    if( headingdeg == nil ) {
        headingdeg = 0.0;
    }

    headingdeg = headingdeg + 1 * sign;
    headingdeg = constant.truncatenorth( headingdeg );
    
    me.itself["autopilot-set"].getChild("heading-bug-deg").setValue(headingdeg);
}

Autopilot.schedule = func {
   # TEMPORARY work around for heading modes PID :
   # heading modes banks into the direction, before engagement.
   if( me.itself["autopilot"].getChild("heading").getValue() != "dg-heading-hold" ) {
       # sets the value early.
       var headingdeg = me.noinstrument["heading"].getValue();
       me.itself["autopilot-set"].getChild("heading-bug-deg").setValue(headingdeg);
   }
}

