# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =====
# DOORS
# =====

Doors = {};

Doors.new = func {
   var obj = { parents : [Doors,System],

               celestial : aircraft.door.new("controls/doors/celestial", 10.0)
         };

   obj.init();

   return obj;
};

Doors.init = func {
   me.inherit_system( "/systems/doors" );

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
