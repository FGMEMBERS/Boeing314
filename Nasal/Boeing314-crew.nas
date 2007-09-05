# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ===============
# VIRTUAL COPILOT
# ===============

VirtualCopilot = {};

VirtualCopilot.new = func {
   obj = { parents : [VirtualCopilot],

           copilot : nil,
           crew : nil,
           crewcontrol : nil,

           CRUISESEC : 15.0,
           MINIMIZESEC : 0.0,
           COPILOTSEC : 3.0,
           NOSEC : 0.0,

           times : 0.0,

# offset visible by pilot
           COMPASSDEG : 1.0,             
           GYRODEG : 1.0,

           lastcompassdeg : 0.0,

           FLIGHTFT : 500.0,

           state : ""
         };

   obj.init();

   return obj;
};

VirtualCopilot.init = func {
   me.copilot = props.globals.getNode("/systems/crew/copilot");
   me.crew = props.globals.getNode("/systems/crew");
   me.crewcontrol = props.globals.getNode("/controls/crew");

   me.MINIMIZESEC = me.crewcontrol.getChild("minimized-s").getValue();
   if( me.MINIMIZESEC < me.COPILOTSEC ) {
      print( "/systems/crew/minimize-s should be above ", me.COPILOTSEC, " seconds : ", me.MINIMIZESEC );
   }
}

VirtualCopilot.toggleexport = func {
   if( !me.crewcontrol.getChild("copilot").getValue() ) {
       me.crewcontrol.getChild("copilot").setValue(constant.TRUE);
   }
   else {
       me.crewcontrol.getChild("copilot").setValue(constant.FALSE);
   }

   me.gyro();
   me.supervisor();
   me.maximize();
}

VirtualCopilot.minimizeexport = func {
   if( !me.crew.getChild("minimized").getValue() ) {
       me.crew.getChild("minimized").setValue(constant.TRUE);
   }
   else {
       me.maximize();
   }
}

VirtualCopilot.schedule = func {
   if( me.crew.getChild("serviceable").getValue() ) {
       me.minimize();
   }
}

VirtualCopilot.slowschedule = func {
   if( me.crew.getChild("serviceable").getValue() ) {
       me.supervisor();
   }
}

VirtualCopilot.maximize = func {
   me.crew.getChild("minimized").setValue(constant.FALSE);
   me.times = me.NOSEC;
}

VirtualCopilot.minimize = func {
   if( !me.crew.getChild("minimized").getValue() ) {
       me.times = me.times + me.COPILOTSEC;
       if( me.times >= me.MINIMIZESEC ) {
           me.minimizeexport();
       }
   }
}

# align gyro with magnetic compass
VirtualCopilot.gyro = func {
   magdeg = getprop("/orientation/heading-magnetic-deg");
   headingdeg = getprop("/instrumentation/heading-indicator/indicated-heading-deg");

   if( headingdeg != nil and magdeg != nil ) {
       diffdeg = magdeg - me.lastcompassdeg;

       # avoids moving of magnetic compass
       if( diffdeg > - me.COMPASSDEG and diffdeg < me.COMPASSDEG ) {
           diffdeg = headingdeg - magdeg;

           # readable by human
           if( diffdeg < - me.GYRODEG or diffdeg > me.GYRODEG ) {
               me.log("gyro");

               offsetdeg = getprop("/instrumentation/heading-indicator/offset-deg");
               offsetdeg = offsetdeg - diffdeg;

               setprop("/instrumentation/heading-indicator/offset-deg", offsetdeg);
           }
       }

       me.lastcompassdeg = magdeg;
   }
}

VirtualCopilot.supervisor = func {
   activ = constant.FALSE;

   if( me.crewcontrol.getChild("copilot").getValue() ) {
       me.state = "";

       # sea level
       if( getprop("/position/altitude-ft") > me.FLIGHTFT ) {
           activ = constant.TRUE;

           me.gyro();
           me.holdspeed();
       }
       else {
           me.none();
       }

       me.copilot.getChild("state").setValue(me.state);
       me.copilot.getChild("time").setValue(getprop("/sim/time/gmt-string"));
   }
   else {
       me.none();
   }

   me.copilot.getChild("activ").setValue(activ);
}

VirtualCopilot.holdspeed = func {
   mode = "speed-with-throttle";
   if( getprop("/autopilot/locks/speed") != mode ) {
       setprop("/autopilot/locks/speed",mode);
       me.log("throttle");
   }
}

VirtualCopilot.none = func {
   setprop("/autopilot/locks/speed","");
}

VirtualCopilot.log = func( message ) {
    me.state = me.state ~ " " ~ message;
}
