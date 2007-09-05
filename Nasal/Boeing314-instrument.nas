# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ========================
# GROUND DIRECTION FINDING
# ========================

GDF = {};

GDF.new = func {
   obj = { parents : [GDF],

           CALLSEC : 120.0,

           waypoints : nil,

           RANGENM : 1500
         };

   obj.init();

   return obj;
};

GDF.init = func {
   me.waypoints = props.globals.getNode("/autopilot/route-manager").getChildren("wp");
}

GDF.callexport = func {
   if( !getprop("/instrumentation/gdf/calling") ) {
       # no waypoint
       id = me.waypoints[0].getChild("id").getValue();
       if( id == nil or id == "" ) {
           state = "Add a waypoint as station"
       }

       # out of range
       elsif( getprop("/autopilot/route-manager/wp/dist") > me.RANGENM ) {
           state = "Station is out of range"
       }

       else {
           state = "Calling station operator";

           setprop("/instrumentation/gdf/called",constant.TRUE);
           setprop("/instrumentation/gdf/calling",constant.TRUE);

           speedup = getprop("/sim/speed-up");
           delaysec = me.CALLSEC / speedup;

           # schedule the next call
           settimer(func{ me.callexport(); },delaysec);
       }

       setprop("/instrumentation/gdf/state",state);
   }

   elsif( getprop("/instrumentation/gdf/called") ) {
       id = me.waypoints[0].getChild("id").getValue();
       if( id != nil ) {

           # magnetic heading for gyro (Sperry)
           bearingdeg = getprop("/autopilot/settings/true-heading-deg");
           magdeg = getprop("/environment/magnetic-variation-deg");
           bearingdeg = bearingdeg - magdeg;

           # north crossing
           if( bearingdeg < 0 ) {
               bearingdeg = 360 + bearingdeg;
           }
           elsif( bearingdeg > 360 ) {
               bearingdeg = bearingdeg - 360;
           }

           # rounding
           bearingdeg = sprintf( "%3d", bearingdeg );

           setprop("/instrumentation/gdf/heading-deg",bearingdeg);

           # remove seconds
           reception = getprop("/sim/time/gmt-string");
           reception = substr( reception, 1, 5 );

           setprop("/instrumentation/gdf/gmt-string",reception);
           setprop("/instrumentation/gdf/show-paper",constant.TRUE);
       }

       setprop("/instrumentation/gdf/called",constant.FALSE);
       setprop("/instrumentation/gdf/calling",constant.FALSE);
       setprop("/instrumentation/gdf/state","");
   }
}


# =======
# SEXTANT
# =======

Sextant = {};

Sextant.new = func {
   obj = { parents : [Sextant]
         };
   return obj;
};

Sextant.polarisexport = func {
   latdeg = getprop("/position/latitude-deg");

   # polaris star
   if( latdeg >= 0.0 ) {
       headingdeg = getprop("/orientation/heading-deg");
       setprop("/sim/current-view/goal-heading-offset-deg", headingdeg );
       setprop("/sim/current-view/goal-pitch-offset-deg", latdeg );
   }

   # southern cross
   else {
       headingdeg = getprop("/orientation/heading-deg") + constant.DEG180;
       setprop("/sim/current-view/goal-heading-offset-deg", headingdeg );
       setprop("/sim/current-view/goal-pitch-offset-deg", - latdeg );
   }
}


# =============
# SPEED UP TIME
# =============

DayTime = {};

DayTime.new = func {
   obj = { parents : [DayTime],

           altitudenode : nil,
           thesim : nil,
           warpnode : nil,

           SPEEDUPSEC : 1.0,

           CLIMBFTPMIN : 1000,                                       # average climb rate
           MAXSTEPFT : 0.0,                                          # altitude change for step

           lastft : 0.0
         };

   obj.init();

   return obj;
}

DayTime.init = func {
    climbftpsec = me.CLIMBFTPMIN / constant.MINUTETOSECOND;
    me.MAXSTEPFT = climbftpsec * me.SPEEDUPSEC;

    me.altitudenode = props.globals.getNode("/position/altitude-ft");
    me.thesim = props.globals.getNode("/sim");
    me.warpnode = props.globals.getNode("/sim/time/warp");
}

DayTime.schedule = func {
   altitudeft = me.altitudenode.getValue();

   speedup = me.thesim.getChild("speed-up").getValue();
   if( speedup > 1 ) {
       # accelerate day time
       multiplier = speedup - 1;
       offsetsec = me.SPEEDUPSEC * multiplier;
       warp = me.warpnode.getValue() + offsetsec; 
       me.warpnode.setValue(warp);

       # safety
       stepft = me.MAXSTEPFT * speedup;
       maxft = me.lastft + stepft;
       minft = me.lastft - stepft;

       # too fast
       if( altitudeft > maxft or altitudeft < minft ) {
           me.thesim.getChild("speed-up").setValue(1);
       }
   }

   me.lastft = altitudeft;
}
