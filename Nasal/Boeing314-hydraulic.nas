# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =====
# DOORS
# =====

Doors = {};

Doors.new = func {
   var obj = { parents : [Doors,System],

               celestial : nil,
               wing : [nil,nil]
         };

   obj.init();

   return obj;
};

Doors.init = func {
   me.inherit_system( "/systems/doors" );

   me.celestial = aircraft.door.new(me.itself["root-ctrl"].getNode("celestial").getPath(), 10.0);

   var thewings = me.itself["root-ctrl"].getChildren("wing");
   for (var i=0; i<size(thewings); i=i+1) {
        me.wing[i] = aircraft.door.new(thewings[i].getPath(), 8.0);
   }

   # user customization
   if( me.itself["root-ctrl"].getNode("celestial").getChild("opened").getValue() ) {
       me.celestial.toggle();
   }
   for (var i=0; i<size(thewings); i=i+1) {
        if( thewings[i].getChild("opened").getValue() ) {
            me.wing[i].toggle();
        }
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

Doors.wingexport = func( index ) {
   var state = constant.TRUE;
   var thewings = me.itself["root-ctrl"].getChildren("wing");

   me.wing[index].toggle();

   if( thewings[index].getChild("opened").getValue() ) {
       state = constant.FALSE;
   }

   thewings[index].getChild("opened").setValue(state);
}
