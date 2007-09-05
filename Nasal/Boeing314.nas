# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ==============
# Initialization
# ==============

BoeingMain = {};

BoeingMain.new = func {
   obj = { parents : [BoeingMain]
         };

   obj.init();

   return obj;
}

# 1 s cron
BoeingMain.sec1cron = func {
   daytimeinstrument.schedule();

   # schedule the next call
   settimer(func{ me.sec1cron(); },daytimeinstrument.SPEEDUPSEC);
}

# 2 s cron
BoeingMain.sec2cron = func {
   autopilotsystem.schedule();

   # schedule the next call
   settimer(func{ me.sec2cron(); },autopilotsystem.AUTOPILOTSEC);
}

# 3 s cron
BoeingMain.sec3cron = func {
   copilotcrew.schedule();

   # schedule the next call
   settimer(func{ me.sec3cron(); },copilotcrew.COPILOTSEC);
}

# 5 s cron
BoeingMain.sec5cron = func {
   mooringsystem.schedule();

   # schedule the next call
   settimer(func{ me.sec5cron(); },mooringsystem.MOORINGSEC);
}

# 15 s cron
BoeingMain.sec15cron = func {
   copilotcrew.slowschedule();

   # schedule the next call
   settimer(func{ me.sec15cron(); },copilotcrew.CRUISESEC);
}

BoeingMain.savedata = func {
   aircraft.data.add("/controls/mooring/automatic");
   aircraft.data.add("/controls/seat/recover");
   aircraft.data.add("/sim/presets/fuel");
   aircraft.data.add("/systems/seat/position/celestial/x-m");
   aircraft.data.add("/systems/seat/position/celestial/y-m");
   aircraft.data.add("/systems/seat/position/celestial/z-m");
   aircraft.data.add("/systems/seat/position/observer/x-m");
   aircraft.data.add("/systems/seat/position/observer/y-m");
   aircraft.data.add("/systems/seat/position/observer/z-m");
}

# global variables in Boeing314 namespace, for call by XML
BoeingMain.instantiate = func {
   globals.Boeing314.constant = Constant.new();
   globals.Boeing314.constantaero = ConstantAero.new();
   globals.Boeing314.fuelsystem = Fuel.new();
   globals.Boeing314.autopilotsystem = Autopilot.new();

   globals.Boeing314.daytimeinstrument = DayTime.new();

   globals.Boeing314.mooringsystem = Mooring.new();
   globals.Boeing314.seatsystem = Seats.new();
   globals.Boeing314.menusystem = Menu.new();

   globals.Boeing314.GDFinstrument = GDF.new();

   globals.Boeing314.copilotcrew = VirtualCopilot.new();
}

BoeingMain.init = func {
   me.instantiate();

   # schedule the 1st call
   settimer(func { me.sec1cron(); },0);
   settimer(func { me.sec2cron(); },0);
   settimer(func { me.sec3cron(); },0);
   settimer(func { me.sec5cron(); },0);
   settimer(func { me.sec15cron(); },0);

   # saved on exit, restored at launch
   me.savedata();
}


boeing314L = setlistener("/sim/signals/fdm-initialized", func { theclipper = BoeingMain.new(); removelistener(boeing314L); } );
