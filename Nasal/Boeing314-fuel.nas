# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron

# IMPORTANT : always uses /consumables/fuel/tank[0]/level-gal_us,
# because /level-lbs seems not synchronized with level-gal_us, during the time of a procedure.



# ====
# FUEL
# ====

Fuel = {};

Fuel.new = func {
   var obj = { parents : [Fuel,System],

               tanksystem : Tanks.new(),

               presets : 0                                                  # saved state
         };

   obj.init();

   return obj;
};

Fuel.init = func {
   me.inherit_system("/systems/fuel");

   me.tanksystem.presetfuel();
   me.savestate();
}

Fuel.menuexport = func {
   me.tanksystem.menu();
   me.savestate();
}

Fuel.reinitexport = func {
   # restore for reinit
   me.itself["root"].getChild("presets").setValue( me.presets );

   me.tanksystem.presetfuel();
   me.savestate();
}

Fuel.savestate = func {
   # backup for reinit
   me.presets = me.itself["root"].getChild("presets").getValue();
}


# =====
# TANKS
# =====

# adds an indirection to convert the tank name into an array index.

Tanks = {};

Tanks.new = func {
# tank contents, to be initialised from XML
   var obj = { parents : [Tanks], 

               pumpsystem : Pump.new(),

               CONTENTLB : { "1" : 0.0, "2" : 0.0, "3" : 0.0, "4" : 0.0, "5" : 0.0, "6" : 0.0, "7" : 0.0 },
               TANKINDEX : { "1" : 0, "2" : 1, "3" : 2, "4" : 3, "5" : 4, "6" : 5, "7" : 6 },
               TANKNAME : [ "1", "2", "3", "4", "5", "6", "7" ],
               nb_tanks : 0,

               dialogpath : nil,
               fillingspath : nil,
               systempath : nil,
               tankspath : nil
        };

   obj.init();

   return obj;
}

Tanks.init = func {
   me.systempath = props.globals.getNode("/systems/fuel");

   me.dialogpath = me.systempath.getNode("tanks/dialog");
   me.tankspath = props.globals.getNode("/consumables/fuel").getChildren("tank");
   me.fillingspath = me.systempath.getChild("tanks").getChildren("filling");

   me.nb_tanks = size(me.tankspath);

   me.initcontent();
}

# fuel initialization
Tanks.initcontent = func {
   var densityppg = 0.0;

   for( var i=0; i < me.nb_tanks; i=i+1 ) {
        densityppg = me.tankspath[i].getChild("density-ppg").getValue();
        me.CONTENTLB[me.TANKNAME[i]] = me.tankspath[i].getChild("capacity-gal_us").getValue() * densityppg;
   }
}

# change by dialog
Tanks.menu = func {
   var value = me.dialogpath.getValue();

   for( var i=0; i < size(me.fillingspath); i=i+1 ) {
        if( me.fillingspath[i].getChild("comment").getValue() == value ) {
            me.load( i );

            # for aircraft-data
            me.systempath.getChild("presets").setValue(i);
            break;
        }
   }
}

# fuel configuration
Tanks.presetfuel = func {
   var dialog = "";
   var value = "";

   # default is 0
   var fuel = me.systempath.getChild("presets").getValue();

   if( fuel == nil ) {
       fuel = 0;
   }

   if( fuel < 0 or fuel >= size(me.fillingspath) ) {
       fuel = 0;
   } 

   # copy to dialog
   dialog = me.dialogpath.getValue();
   if( dialog == "" or dialog == nil ) {
       value = me.fillingspath[fuel].getChild("comment").getValue();
       me.dialogpath.setValue(value);
   }

   me.load( fuel );
}

Tanks.load = func( fuel ) {
   var child = nil;
   var presets = me.fillingspath[fuel].getChildren("tank");

   for( var i=0; i < size(presets); i=i+1 ) {
        child = presets[i].getChild("level-gal_us");
        if( child != nil ) {
            level = child.getValue();
        }

        # new load through dialog
        else {
            level = me.CONTENTLB[me.TANKNAME[i]] * constant.LBTOGALUS;
        } 
        me.pumpsystem.setlevel(i, level);
   } 
}


# ==========
# FUEL PUMPS
# ==========

# does the transfers between the tanks

Pump = {};

Pump.new = func {
   var obj = { parents : [Pump],

               tanks : nil 
         };

   obj.init();

   return obj;
}

Pump.init = func {
   me.tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
}

Pump.setlevel = func( index, levelgalus ) {
   me.tanks[index].getChild("level-gal_us").setValue(levelgalus);
}
