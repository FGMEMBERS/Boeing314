# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =======
# SEXTANT
# =======

Sextant = {};

Sextant.new = func {
   var obj = { parents : [Sextant,System]
         };

   obj.init();

   return obj;
};

Sextant.init = func {
    me.inherit_system("/instrumentation/sextant");
}

Sextant.polarisexport = func {
   var headingdeg = 0.0;
   var latdeg = me.noinstrument["latitude"].getValue();

   # polaris star
   if( latdeg >= 0.0 ) {
       headingdeg = me.noinstrument["heading"].getValue();
       me.noinstrument["current-view"].getChild("goal-heading-offset-deg").setValue( headingdeg );
       me.noinstrument["current-view"].getChild("goal-pitch-offset-deg").setValue( latdeg );
   }

   # southern cross
   else {
       headingdeg = me.noinstrument["heading"].getValue() + constant.DEG180;
       me.noinstrument["current-view"].getChild("goal-heading-offset-deg").setValue( headingdeg );
       me.noinstrument["current-view"].getChild("goal-pitch-offset-deg").setValue( - latdeg );
   }
}


# =======
# GENERIC
# =======

Generic = {};

Generic.new = func {
   var obj = { parents : [Generic,System],

               generic : nil
         };

   obj.init();

   return obj;
};

Generic.init = func {
   me.inherit_system("/instrumentation/generic");

   me.generic = aircraft.light.new(me.itself["root"].getPath(),[ 1.5,0.2 ]);

   me.generic.toggle();
}

Generic.toggleclick = func {
   var sound = constant.TRUE;

   if( me.itself["root"].getChild("click").getValue() ) {
       sound = constant.FALSE;
   }

   me.itself["root"].getChild("click").setValue( sound );
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
       # safety
       var stepft = me.MAXSTEPFT * speedup;
       var maxft = me.lastft + stepft;
       var minft = me.lastft - stepft;

       # too fast
       if( altitudeft > maxft or altitudeft < minft ) {
           me.noinstrument["speed-up"].setValue(1);
       }
   }

   me.lastft = altitudeft;
}
