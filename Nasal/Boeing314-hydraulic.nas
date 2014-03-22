# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =====
# DOORS
# =====

Doors = {};

Doors.new = func {
   var obj = { parents : [Doors,System],

               celestial : nil
         };

   obj.init();

   return obj;
};

Doors.init = func {
   me.inherit_system( "/systems/doors" );

   me.celestial = aircraft.door.new(me.itself["root-ctrl"].getNode("celestial").getPath(), 10.0);

   # user customization
   if( me.itself["root-ctrl"].getNode("celestial").getChild("opened").getValue() ) {
       me.celestial.toggle();
   }
}

Doors.celestialexport = func {
   var state = constant.TRUE;

   me.celestial.toggle();

   if( me.itself["root-ctrl"].getNode("celestial").getChild("opened").getValue() ) {
       state = constant.FALSE;
   }

   me.itself["root-ctrl"].getNode("celestial").getChild("opened").setValue(state);
}
