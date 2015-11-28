# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =================
# OVERRIDING JSBSIM
# =================

BoeingJSBsim = {};

BoeingJSBsim.new = func {
   var obj = { parents : [BoeingJSBsim,System]
         };

   obj.init();

   return obj;
}

BoeingJSBsim.init = func {
  me.inherit_system( "/systems/environment" );
}

BoeingJSBsim.wavescron = func {
  var groundft = me.noinstrument["ground"].getValue();
  var waveft = me.dependency["fdm-environment"].getChild("wave-amplitude-ft").getValue();
    
  # Send the current ground level to the JSBSim hydrodynamics model.
  me.dependency["fdm-environment"].getChild("water-level-ft").setValue( groundft + waveft );

  # Connect the JSBSim hydrodynamics wave model with the custom water shader.
  me.itself["waves"].getChild("time-sec").setValue( me.dependency["fdm-simulation"].getChild("sim-time-sec").getValue() );
  me.itself["waves"].getChild("from-deg").setValue( me.dependency["fdm-environment"].getChild("waves-from-deg").getValue() );
  me.itself["waves"].getChild("length-ft").setValue( me.dependency["fdm-environment"].getChild("wave-length-ft").getValue() );
  me.itself["waves"].getChild("amplitude-ft").setValue( me.dependency["fdm-environment"].getChild("wave-amplitude-ft").getValue() );
  
  me.itself["waves"].getChild("angular-frequency-rad_sec").setValue( me.dependency["fdm-wave"].getChild("angular-frequency-rad_sec").getValue() );
  me.itself["waves"].getChild("wave-number-rad_ft").setValue( me.dependency["fdm-wave"].getChild("wave-number-rad_ft").getValue() );
  
  settimer(func{ me.wavescron(); }, 0.0);
}

BoeingJSBsim.specific = func {
  settimer(func{ me.wavescron(); }, 0.0);
}


# ==============
# Initialization
# ==============

BoeingMain = {};

BoeingMain.new = func {
   var obj = { parents : [BoeingMain]
         };

   obj.init();

   return obj;
}

BoeingMain.putinrelation = func {
   copilotcrew.set_relation( autopilotsystem, crewscreen, voicecrew );

   mooringsystem.set_relation( copilotcrew );
}

# 1 s cron
BoeingMain.sec1cron = func {
   daytimeinstrument.schedule();

   # schedule the next call
   settimer(func{ me.sec1cron(); },daytimeinstrument.SPEEDUPSEC);
}

# 2 s cron
BoeingMain.sec2cron = func {
   copilotcrew.fastschedule();

   # schedule the next call
   settimer(func{ me.sec2cron(); },copilotcrew.COPILOTFASTSEC);
}

# 3 s cron
BoeingMain.sec3cron = func {
   autopilotsystem.schedule();
   crewscreen.schedule();

   # schedule the next call
   settimer(func{ me.sec3cron(); },crewscreen.MENUSEC);
}

# 5 s cron
BoeingMain.sec5cron = func {
   mooringsystem.schedule();

   # schedule the next call
   settimer(func{ me.sec5cron(); },mooringsystem.MOORINGSEC);
}

# 60 s cron
BoeingMain.sec60cron = func {
   mooringsystem.slowschedule();

   # schedule the next call
   settimer(func{ me.sec60cron(); },mooringsystem.BOATSEC);
}

BoeingMain.savedata = func {
   var saved_props = [ "/controls/copilot/gyro",
                       "/controls/crew/radio",
                       "/controls/crew/timeout",
                       "/controls/crew/timeout-s",
                       "/controls/doors/celestial/opened",
                       "/controls/doors/wing[0]/opened",
                       "/controls/doors/wing[1]/opened",
                       "/controls/environment/effects",
                       "/controls/fuel/reinit",
                       "/controls/mooring/automatic",
                       "/controls/mooring/category/atlantic",
                       "/controls/mooring/category/atlantic2",
                       "/controls/mooring/category/atlantic3",
                       "/controls/mooring/category/atlantic4",
                       "/controls/mooring/category/atlantic-winter",
                       "/controls/mooring/category/atlantic-winter2",
                       "/controls/mooring/category/atlantic-winter3",
                       "/controls/mooring/category/atlantic-winter4",
                       "/controls/mooring/category/everything",
                       "/controls/mooring/category/other",
                       "/controls/mooring/category/pacific",
                       "/controls/mooring/category/pacific2",
                       "/controls/mooring/category/round-the-world",
                       "/controls/mooring/heading-deg",
                       "/controls/mooring/seaport",
                       "/controls/mooring/sort/distance",
                       "/controls/mooring/sort/ident",
                       "/controls/mooring/sort/name",
                       "/controls/mooring/tower-adf",
                       "/controls/mooring/wind/head",
                       "/controls/mooring/wind/terminal",
                       "/controls/seat/recover",
                       "/controls/voice/sound",
                       "/controls/voice/text",
                       "/sim/model/immat[0]",
                       "/sim/model/immat[1]",
                       "/systems/fuel/presets",
                       "/systems/seat/position/celestial/x-m",
                       "/systems/seat/position/celestial/y-m",
                       "/systems/seat/position/celestial/z-m",
                       "/systems/seat/position/navigator/x-m",
                       "/systems/seat/position/navigator/y-m",
                       "/systems/seat/position/navigator/z-m",
                       "/systems/seat/position/observer/x-m",
                       "/systems/seat/position/observer/y-m",
                       "/systems/seat/position/observer/z-m" ];

   for( var i = 0; i < size(saved_props); i = i + 1 ) {
        aircraft.data.add(saved_props[i]);
   }
}

# global variables in Boeing314 namespace, for call by XML
BoeingMain.instantiate = func {
   globals.Boeing314.constant = Constant.new();
   globals.Boeing314.constantaero = ConstantAero.new();
   globals.Boeing314.FDM = BoeingJSBsim.new();
   
   globals.Boeing314.fuelsystem = Fuel.new();
   globals.Boeing314.autopilotsystem = Autopilot.new();

   globals.Boeing314.daytimeinstrument = DayTime.new();

   globals.Boeing314.mooringsystem = Mooring.new();

   globals.Boeing314.doorsystem = Doors.new();
   globals.Boeing314.seatsystem = Seats.new();

   globals.Boeing314.menusystem = Menu.new();
   globals.Boeing314.crewscreen = Crewbox.new();

   globals.Boeing314.copilotcrew = VirtualCopilot.new();
   globals.Boeing314.voicecrew = Voice.new();
   globals.Boeing314.GDFcrew = GDF.new();
}

BoeingMain.init = func {
   aircraft.livery.init( "Aircraft/Boeing314/Models/Liveries",
                         "sim/model/livery/name",
                         "sim/model/livery/index" );

   me.instantiate();
   me.putinrelation();

   # JSBSim specific
   #FDM.specific();

   # schedule the 1st call
   settimer(func { me.sec1cron(); },0);
   settimer(func { me.sec2cron(); },0);
   settimer(func { me.sec3cron(); },0);
   settimer(func { me.sec5cron(); },0);
   settimer(func { me.sec60cron(); },0);

   # saved on exit, restored at launch
   me.savedata();
}

# state reset
BoeingMain.reinit = func {
   if( getprop("/controls/fuel/reinit") ) {
       # default is JSBSim state, which loses fuel selection.
       globals.Boeing314.fuelsystem.reinitexport();
   }
}


# object creation
boeing314L  = setlistener("/sim/signals/fdm-initialized", func { globals.Boeing314.main = BoeingMain.new(); removelistener(boeing314L); } );

# state reset
boeing314L2 = setlistener("/sim/signals/reinit", func { globals.Boeing314.main.reinit(); });
