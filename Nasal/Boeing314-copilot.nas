# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ===============
# VIRTUAL COPILOT
# ===============

VirtualCopilot = {};

VirtualCopilot.new = func {
   var obj = { parents : [VirtualCopilot,VirtualCrew,System],

               autopilotsystem : nil,
               crewscreen : nil,
               voicecrew : nil,

               radiomanagement : RadioManagement.new(),

               COPILOTSEC : 60.0,
               COPILOTFASTSEC : 2.0,

               rates : 0.0,

               GROUNDFT : 10,

# offset visible by pilot
               COMPASSDEG : 1.0,             
               GYRODEG : 1.0,

               lastcompassdeg : 0.0
         };

   obj.init();

   return obj;
};

VirtualCopilot.init = func {
   var path = "/systems/copilot";

   me.inherit_system(path);
   me.inherit_virtualcrew(path);

   me.rates = me.COPILOTSEC;
   me.run();
}

VirtualCopilot.set_relation = func( autopilot, crew, voice ) {
   me.autopilotsystem = autopilot;
   me.crewscreen = crew;
   me.voicecrew = voice;

   me.radiomanagement.set_relation( autopilot );
}

VirtualCopilot.windexport = func {
    var aglft = me.noinstrument["altitude"].getValue();

    # not in flight
    if( aglft < me.GROUNDFT ) {
        var headingdeg = me.noinstrument["true"].getValue();
        var winddeg = me.noinstrument["wind"].getValue();

        var crosswinddeg = constant.crosswinddeg( winddeg, headingdeg );

        me.crosswindexport( crosswinddeg );
    }
}

VirtualCopilot.crosswindexport = func( crosswinddeg ) {
    var action = "";

    # round for announcement
    crosswinddeg = constant.round( crosswinddeg / 10 );
    crosswinddeg = crosswinddeg * 10;


    # direction
    if( crosswinddeg < - constant.DEG10 ) {
        action = "port";
    }
    elsif( crosswinddeg > constant.DEG10 ) {
        action = "starboard";
    }
    else {
        action = "head";
    }

    
    me.dependency["voice"].setValue( crosswinddeg );

    me.voicecrew.pilotcall( action );
}

VirtualCopilot.toggleexport = func {
   var launch = constant.FALSE;

   me.context();

   if( !me.itself["root-ctrl"].getChild("activ").getValue() ) {
       launch = constant.TRUE;
   }

   me.itself["root-ctrl"].getChild("activ").setValue(launch);
       
   if( launch and !me.is_running() ) {
       me.radiomanagement.set_task();

       me.schedule();
   }

   # clear
   else {
       me.none();
   }
}
 
VirtualCopilot.throttleexport = func {
   var throttle = constant.FALSE;
   var mode = "";

   me.context();

   # ctrl-S toggles virtual copilot
   if( !me.is_autothrottle() ) {
       me.activatecrew();

       mode = "speed-with-throttle";

       throttle = constant.TRUE;
   }


   # feedback
   me.holdthrottle( throttle );

   me.dependency["autopilot"].getChild("speed").setValue( mode );
}

VirtualCopilot.schedule = func {
   me.reset();

   if( me.dependency["crew"].getChild("serviceable").getValue() ) {
       me.supervisor();
   }

   me.run();
}

VirtualCopilot.fastschedule = func {
   me.context();

   if( me.state != "" ) {
       me.timestamp();
   }
}

VirtualCopilot.run = func {
   if( me.itself["root-ctrl"].getChild("activ").getValue() ) {
       me.set_running();

       me.rates = me.speed_ratesec( me.rates );
       settimer( func { me.schedule(); }, me.rates );
   }
}

VirtualCopilot.supervisor = func {
   me.rates = me.COPILOTSEC;

   if( me.itself["root-ctrl"].getChild("activ").getValue() ) {
       me.set_activ();

       me.gyro();

       me.radiomanagement.copilot( me );

       me.rates = me.randoms( me.rates );
       me.timestamp();
   }

   me.itself["root"].getChild("activ").setValue(me.is_activ());
}

VirtualCopilot.togglecrewexport = func {
   me.toggleexport();
   me.crewscreen.toggleexport();
}

VirtualCopilot.activatecrew = func {
   if( !me.itself["root-ctrl"].getChild("activ").getValue() ) {
       me.toggleexport();
       me.crewscreen.toggleexport();
   }
}

VirtualCopilot.holdthrottle = func( throttle ) {
   if( throttle ) {
       me.log("throttle");
   }
   else {
       me.log("no-throttle");
   }

   me.itself["root"].getChild("throttle").setValue(throttle);
   me.itself["root"].getChild("state").setValue(me.state);
}

VirtualCopilot.nothrottle = func {
   me.dependency["autopilot"].getChild("speed").setValue("");
   me.itself["root"].getChild("throttle").setValue("");
}

VirtualCopilot.none = func {
   me.nothrottle();
}

VirtualCopilot.is_autothrottle = func {
   var result = constant.FALSE;

   if( me.dependency["autopilot"].getChild("speed").getValue() == "speed-with-throttle" ) {
       result = constant.TRUE;
   }

   return result;
}

VirtualCopilot.context = func {
   me.state = "";
}

# align gyro with magnetic compass
VirtualCopilot.gyro = func {
   if( me.itself["root-ctrl"].getChild("gyro").getValue() ) {
       var diffdeg = 0.0;
       var offsetdeg = 0.0;
       var magdeg = me.dependency["compass"].getValue();
       var headingdeg = me.dependency["heading"].getChild("indicated-heading-deg").getValue();

       if( headingdeg != nil and magdeg != nil ) {
           diffdeg = magdeg - me.lastcompassdeg;

           # avoids moving of magnetic compass
           if( diffdeg > - me.COMPASSDEG and diffdeg < me.COMPASSDEG ) {
               diffdeg = headingdeg - magdeg;

               # readable by human
               if( diffdeg < - me.GYRODEG or diffdeg > me.GYRODEG ) {
                   me.log("gyro");

                   offsetdeg = me.dependency["heading"].getChild("offset-deg").getValue();
                   offsetdeg = offsetdeg - diffdeg;

                   me.dependency["heading"].getChild("offset-deg").setValue(offsetdeg);
               }
           }

           me.lastcompassdeg = magdeg;
       }
   }
}
