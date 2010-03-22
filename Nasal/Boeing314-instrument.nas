# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =======
# SEXTANT
# =======

Sextant = {};

Sextant.new = func {
   var obj = { parents : [Sextant]
         };
   return obj;
};

Sextant.polarisexport = func {
   var headingdeg = 0.0;
   var latdeg = getprop("/position/latitude-deg");

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


# =======
# GENERIC
# =======

Generic = {};

Generic.new = func {
   var obj = { parents : [Generic],

           click : nil,

           generic : aircraft.light.new("/instrumentation/generic",[ 1.5,0.2 ])
         };

   obj.init();

   return obj;
};

Generic.init = func {
   me.click = props.globals.getNode("/instrumentation/generic/click");

   me.generic.toggle();
}

Generic.toggleclick = func {
   var sound = constant.TRUE;

   if( me.click.getValue() ) {
       sound = constant.FALSE;
   }

   me.click.setValue( sound );
}


# =============
# SPEED UP TIME
# =============

DayTime = {};

DayTime.new = func {
   var obj = { parents : [DayTime,System],

               SPEEDUPSEC : 1.0,

               CLIMBFTPMIN : 1000,                                           # average climb rate
               MAXSTEPFT : 0.0,                                              # altitude change for step

               lastft : 0.0
         };

   obj.init();

   return obj;
}

DayTime.init = func {
    me.inherit_system("/instrumentation/clock");

    var climbftpsec = me.CLIMBFTPMIN / constant.MINUTETOSECOND;

    me.MAXSTEPFT = climbftpsec * me.SPEEDUPSEC;
}

DayTime.schedule = func {
   var altitudeft = me.noinstrument["altitude"].getValue();
   var speedup = me.noinstrument["speed-up"].getValue();

   if( speedup > 1 ) {
       var multiplier = 0.0;
       var offsetsec = 0.0;
       var warp = 0.0;
       var stepft = 0.0;
       var maxft = 0.0;
       var minft = 0.0;

       # accelerate day time
       multiplier = speedup - 1;
       offsetsec = me.SPEEDUPSEC * multiplier;
       warp = me.noinstrument["warp"].getValue() + offsetsec; 
       me.noinstrument["warp"].setValue(warp);

       # safety
       stepft = me.MAXSTEPFT * speedup;
       maxft = me.lastft + stepft;
       minft = me.lastft - stepft;

       # too fast
       if( altitudeft > maxft or altitudeft < minft ) {
           me.noinstrument["speed-up"].setValue(1);
       }
   }

   me.lastft = altitudeft;
}
