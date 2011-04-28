# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



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
   settimer(func{ me.sec2cron(); },copilotcrew.COPILOTSEC);
}

# 3 s cron
BoeingMain.sec3cron = func {
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

BoeingMain.savedata = func {
   var saved_props = [ "/controls/copilot/gyro",
                       "/controls/crew/timeout",
                       "/controls/crew/timeout-s",
                       "/controls/doors/celestial/opened",
                       "/controls/mooring/automatic",
                       "/controls/mooring/heading-deg",
                       "/controls/mooring/tower-adf",
                       "/controls/mooring/wind",
                       "/controls/seat/recover",
                       "/controls/voice/sound",
                       "/controls/voice/text",
                       "/sim/model/immat",
                       "/systems/crew/immat[0]",
                       "/systems/crew/immat[1]",
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

   # schedule the 1st call
   settimer(func { me.sec1cron(); },0);
   settimer(func { me.sec2cron(); },0);
   settimer(func { me.sec3cron(); },0);
   settimer(func { me.sec5cron(); },0);

   # saved on exit, restored at launch
   me.savedata();
}


boeing314L = setlistener("/sim/signals/fdm-initialized", func { theclipper = BoeingMain.new(); removelistener(boeing314L); } );
