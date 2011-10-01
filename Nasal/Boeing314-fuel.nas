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
   var obj = { parents : [Fuel],

               tanksystem : Tanks.new(),

               presets : 0                                                  # saved state
         };

   obj.init();

   return obj;
};

Fuel.init = func {
   me.tanksystem.presetfuel();
   me.savestate();
}

Fuel.menuexport = func {
   me.tanksystem.menu();
   me.savestate();
}

Fuel.reinitexport = func {
   # restore for reinit
   setprop( "/systems/fuel/presets", me.presets );

   me.tanksystem.presetfuel();
   me.savestate();
}

Fuel.savestate = func {
   # backup for reinit
   me.presets = getprop( "/systems/fuel/presets" );
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

           fillings : nil,
           tanks : nil
         };

    obj.init();

    return obj;
}

Tanks.init = func {
    me.tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
    me.fillings = props.globals.getNode("/systems/fuel/tanks").getChildren("filling");

    me.nb_tanks = size(me.tanks);

    me.initcontent();
}

# fuel initialization
Tanks.initcontent = func {
   var densityppg = 0.0;

   for( var i=0; i < me.nb_tanks; i=i+1 ) {
        densityppg = me.tanks[i].getChild("density-ppg").getValue();
        me.CONTENTLB[me.TANKNAME[i]] = me.tanks[i].getChild("capacity-gal_us").getValue() * densityppg;
   }
}

# change by dialog
Tanks.menu = func {
   var value = getprop("/systems/fuel/tanks/dialog");

   for( var i=0; i < size(me.fillings); i=i+1 ) {
        if( me.fillings[i].getChild("comment").getValue() == value ) {
            me.load( i );

            # for aircraft-data
            setprop("/systems/fuel/presets",i);
            break;
        }
   }
}

# fuel configuration
Tanks.presetfuel = func {
   var dialog = "";
   var value = "";

   # default is 0
   var fuel = getprop("/systems/fuel/presets");

   if( fuel == nil ) {
       fuel = 0;
   }

   if( fuel < 0 or fuel >= size(me.fillings) ) {
       fuel = 0;
   } 

   # copy to dialog
   dialog = getprop("/systems/fuel/tanks/dialog");
   if( dialog == "" or dialog == nil ) {
       value = me.fillings[fuel].getChild("comment").getValue();
       setprop("/systems/fuel/tanks/dialog", value);
   }

   me.load( fuel );
}

Tanks.load = func( fuel ) {
   var child = nil;
   var presets = me.fillings[fuel].getChildren("tank");

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
