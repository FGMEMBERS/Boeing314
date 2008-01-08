# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =====
# SEATS
# =====

# WARNING : only works if the seats are after the preferences.xml's views.

Seats = {};

Seats.new = func {
   var obj = { parents : [Seats],

           sextant : Sextant.new(),

           controls : nil,
           positions : nil,
           theseats : nil,
           theview : nil,

           lookup : {},
           names : {},
           nb_seats : 0,

           CAPTINDEX : 0,

           floating : {},
           recoverfloating : constant.FALSE,
           last_recover : {},
           initial : {}
         };

   obj.init();

   return obj;
};

Seats.init = func {
   var name = "";
   var child = nil;

   me.controls = props.globals.getNode("/controls/seat");
   me.positions = props.globals.getNode("/systems/seat/position");
   me.theseats = props.globals.getNode("/systems/seat");
   me.theviews = props.globals.getNode("/sim").getChildren("view");

   # retrieve the index as created by FG
   for( var i = 0; i < size(me.theviews); i=i+1 ) {
        child = me.theviews[i].getChild("name");
        # nasal doesn't see yet the views of preferences.xml
        if( child != nil ) {
            name = me.theviews[i].getChild("name").getValue();
            if( name == "Engineer View" ) {
                me.save_lookup("engineer", i);
            }
            elsif( name == "Radio View" ) {
                me.save_lookup("radio", i);
            }
            elsif( name == "Copilot View" ) {
                me.save_lookup("copilot", i);
            }
            elsif( name == "Celestial View" ) {
                me.save_lookup("celestial", i);
                me.save_initial( "celestial", me.theviews[i] );
            }
            elsif( name == "Observer View" ) {
                me.save_lookup("observer", i);
                me.save_initial( "observer", me.theviews[i] );
            }
            elsif( name == "Boat View" ) {
                me.save_lookup("boat", i);
            }
        }
   }

   # default
   me.recoverfloating = me.controls.getChild("recover").getValue();
}

Seats.recoverexport = func {
   me.recoverfloating = !me.recoverfloating;
   me.controls.getChild("recover").setValue(me.recoverfloating);
}

Seats.viewexport = func( name ) {
   var index = 0;

   if( name != "captain" ) {
       index = me.lookup[name];

       # swap to view
       if( !me.theseats.getChild(name).getValue() ) {
           setprop("/sim/current-view/view-number", index);
           me.theseats.getChild(name).setValue(constant.TRUE);
           me.theseats.getChild("captain").setValue(constant.FALSE);

           me.theviews[index].getChild("enabled").setValue(constant.TRUE);
       }

       # return to captain view
       else {
           setprop("/sim/current-view/view-number", me.CAPTINDEX);
           me.theseats.getChild(name).setValue(constant.FALSE);
           me.theseats.getChild("captain").setValue(constant.TRUE);

           me.theviews[index].getChild("enabled").setValue(constant.FALSE);
       }

       # disable all other views
       for( var i = 0; i < me.nb_seats; i=i+1 ) {
            if( name != me.names[i] ) {
                me.theseats.getChild(me.names[i]).setValue(constant.FALSE);

                index = me.lookup[me.names[i]];
                me.theviews[index].getChild("enabled").setValue(constant.FALSE);
            }
       }

       me.recover();
   }

   # captain view
   else {
       setprop("/sim/current-view/view-number",me.CAPTINDEX);
       me.theseats.getChild("captain").setValue(constant.TRUE);

       # disable all other views
       for( var i = 0; i < me.nb_seats; i=i+1 ) {
            me.theseats.getChild(me.names[i]).setValue(constant.FALSE);

            index = me.lookup[me.names[i]];
            me.theviews[index].getChild("enabled").setValue(constant.FALSE);
       }
   }
}

Seats.scrollexport = func{
   me.stepView(1);
}

Seats.scrollreverseexport = func{
   me.stepView(-1);
}

Seats.stepView = func( step ) {
   var targetview = 0;
   var name = "";

   for( var i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.theseats.getChild(name).getValue() ) {
            targetview = me.lookup[name];
            break;
        }
   }

   # ignores captain view
   if( targetview > me.CAPTINDEX ) {
       me.theviews[me.CAPTINDEX].getChild("enabled").setValue(constant.FALSE);
   }

   view.stepView(step);

   # restores because of userarchive
   if( targetview > me.CAPTINDEX ) {
       me.theviews[me.CAPTINDEX].getChild("enabled").setValue(constant.TRUE);
   }
}

# forwards is positiv
Seats.movelengthexport = func( name, step ) {
   var sign = 0;
   var headdeg = 0.0;
   var pos = "";
   var axis = "";
   var result = constant.FALSE;

   if( me.move() ) {
       headdeg = getprop("/sim/current-view/goal-heading-offset-deg");

       if( headdeg <= 45 or headdeg >= 315 ) {
           prop = "/sim/current-view/z-offset-m";
           sign = 1;
           axis = "z";
       }
       elsif( headdeg >= 135 and headdeg <= 225 ) {
           prop = "/sim/current-view/z-offset-m";
           sign = -1;
           axis = "z";
       }
       elsif( headdeg > 225 and headdeg < 315 ) {
           prop = "/sim/current-view/x-offset-m";
           sign = -1;
           axis = "x";
       }
       else {
           prop = "/sim/current-view/x-offset-m";
           sign = 1;
           axis = "x";
       }

       pos = getprop(prop);
       pos = pos + sign * step;
       setprop(prop,pos);

       result = constant.TRUE;
   }

   return result;
}

# left is negativ
Seats.movewidthexport = func( name, step ) {
   var sign = 0;
   var headdeg = 0.0;
   var pos = "";
   var axis = "";
   var result = constant.FALSE;

   if( me.move() ) {
       headdeg = getprop("/sim/current-view/goal-heading-offset-deg");

       if( headdeg <= 45 or headdeg >= 315 ) {
           prop = "/sim/current-view/x-offset-m";
           sign = 1;
           axis = "x";
       }
       elsif( headdeg >= 135 and headdeg <= 225 ) {
           prop = "/sim/current-view/x-offset-m";
           sign = -1;
           axis = "x";
       }
       elsif( headdeg > 225 and headdeg < 315 ) {
           prop = "/sim/current-view/z-offset-m";
           sign = 1;
           axis = "z";
       }
       else {
           prop = "/sim/current-view/z-offset-m";
           sign = -1;
           axis = "z";
       }

       pos = getprop(prop);
       pos = pos + sign * step;
       setprop(prop,pos);

       result = constant.TRUE;
   }

   return result;
}

# up is positiv
Seats.moveheightexport = func( name, step ) {
   var pos = "";
   var result = constant.FALSE;

   if( me.move() ) {
       pos = getprop("/sim/current-view/y-offset-m");
       pos = pos + step;
       setprop("/sim/current-view/y-offset-m",pos);

       result = constant.TRUE;
   }

   return result;
}

Seats.save_lookup = func( name, index ) {
   me.names[me.nb_seats] = name;

   me.lookup[name] = index;

   me.floating[name] = constant.FALSE;

   me.nb_seats = me.nb_seats + 1;
}

# backup initial position
Seats.save_initial = func( name, view ) {
   var pos = {};
   var config = view.getNode("config");

   pos["x"] = config.getChild("x-offset-m").getValue();
   pos["y"] = config.getChild("y-offset-m").getValue();
   pos["z"] = config.getChild("z-offset-m").getValue();

   me.initial[name] = pos;

   me.floating[name] = constant.TRUE;
   me.last_recover[name] = constant.FALSE;
}

Seats.initial_position = func( name ) {
   var posx = 0.0;
   var posy = 0.0;
   var posz = 0.0;
   var position = me.positions.getNode(name);

   posx = me.initial[name]["x"];
   posy = me.initial[name]["y"];
   posz = me.initial[name]["z"];

   setprop("/sim/current-view/x-offset-m",posx);
   setprop("/sim/current-view/y-offset-m",posy);
   setprop("/sim/current-view/z-offset-m",posz);

   position.getChild("x-m").setValue(posx);
   position.getChild("y-m").setValue(posy);
   position.getChild("z-m").setValue(posz);
}

Seats.last_position = func( name ) {
   var posx = 0.0;
   var posy = 0.0;
   var posz = 0.0;
   var position = nil;

   # 1st restore
   if( !me.last_recover[ name ] and me.recoverfloating ) {
       position = me.positions.getNode(name);

       posx = position.getChild("x-m").getValue();
       posy = position.getChild("y-m").getValue();
       posz = position.getChild("z-m").getValue();

       if( posx != me.initial[name]["x"] or
           posy != me.initial[name]["y"] or
           posz != me.initial[name]["z"] ) {

           setprop("/sim/current-view/x-offset-m",posx);
           setprop("/sim/current-view/y-offset-m",posy);
           setprop("/sim/current-view/z-offset-m",posz);
       }

       me.last_recover[ name ] = constant.TRUE;
   }
}

Seats.recover = func {
   var name = "";

   for( var i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.theseats.getChild(name).getValue() ) {
            if( me.floating[name] ) {
                me.last_position( name );
            }
            break;
        }
   }
}

Seats.move_position = func( name ) {
   var posx = getprop("/sim/current-view/x-offset-m");
   var posy = getprop("/sim/current-view/y-offset-m");
   var posz = getprop("/sim/current-view/z-offset-m");

   var position = me.positions.getNode(name);

   position.getChild("x-m").setValue(posx);
   position.getChild("y-m").setValue(posy);
   position.getChild("z-m").setValue(posz);
}

Seats.move = func {
   var name = "";
   var result = constant.FALSE;

   # saves previous position
   for( var i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.theseats.getChild(name).getValue() ) {
            if( me.floating[name] ) {
                me.move_position( name );
                result = constant.TRUE;
            }
            break;
        }
   }

   return result;
}

# restore view
Seats.restoreexport = func {
   var name = "";

   for( var i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.theseats.getChild(name).getValue() ) {
            if( me.floating[name] ) {
                me.initial_position( name );
            }
            break;
        }
   }
}

Seats.polarisexport = func {
    if( !me.theseats.getChild("celestial").getValue() ) {
        me.viewexport("celestial");
    }

    me.sextant.polarisexport();
}


# ====
# MENU
# ====

Menu = {};

Menu.new = func {
   var obj = { parents : [Menu],

           crew : nil,
           fuel : nil,
           gdf : nil,
           menu : nil,
           moorage : nil
         };

   obj.init();

   return obj;
};

Menu.init = func {
   me.menu = gui.Dialog.new("/sim/gui/dialogs/Boeing314/menu/dialog",
                            "Aircraft/Boeing314/Dialogs/Boeing314-menu.xml");
   me.crew = gui.Dialog.new("/sim/gui/dialogs/Boeing314/crew/dialog",
                            "Aircraft/Boeing314/Dialogs/Boeing314-crew.xml");
   me.gdf = gui.Dialog.new("/sim/gui/dialogs/Boeing314/gdf/dialog",
                            "Aircraft/Boeing314/Dialogs/Boeing314-gdf.xml");
   me.fuel = gui.Dialog.new("/sim/gui/dialogs/Boeing314/fuel/dialog",
                            "Aircraft/Boeing314/Dialogs/Boeing314-fuel.xml");
   me.moorage = gui.Dialog.new("/sim/gui/dialogs/Boeing314/moorage/dialog",
                               "Aircraft/Boeing314/Dialogs/Boeing314-moorage.xml");
}


# =================
# AUTOMATIC MOORING
# =================

Mooring = {};

Mooring.new = func {
   var obj = { parents : [Mooring],

           mooring : nil,
           presets : nil,
           seaplanes : nil,

           MOORINGSEC : 5.0,
           AIRPORTSEC : 3.0,
           HARBOURSEC : 2.0,

           BOATDEG : 0.0001,

           FLIGHTFT : 20,
           BOATFT : 10,                                            # crew in a boat
           
           boataltitude : constant.FALSE
         };

   obj.init();

   return obj;
};

Mooring.init = func {
   me.mooring = props.globals.getNode("/systems/mooring");
   me.presets = props.globals.getNode("/sim/presets");
   me.seaplanes = props.globals.getNode("/systems/mooring/route").getChildren("seaplane");

   me.presetseaplane();
}

Mooring.schedule = func {
   me.towerchange();
   me.mooragechange();
}

Mooring.dialogexport = func {
   var harbour = "";
   var dialog = me.mooring.getChild("dialog").getValue();
   
   # KSFO  Treasure Island ==> KSFO
   var idcomment = split( " ", dialog );
   var moorage = idcomment[0];

   for(var i=0; i<size(me.seaplanes); i=i+1) {
       harbour = me.seaplanes[ i ].getChild("airport-id").getValue();

       if( harbour == moorage ) {
           me.setmoorage( i, moorage );

           setprop("/sim/tower/airport-id",moorage);
           break;
       }
   }
}

Mooring.setmoorage = func( index, moorage ) {
    var latitudedeg = me.seaplanes[ index ].getChild("latitude-deg").getValue();
    var longitudedeg = me.seaplanes[ index ].getChild("longitude-deg").getValue();
    var headingdeg = me.seaplanes[ index ].getChild("heading-deg").getValue();

    me.presets.getChild("latitude-deg").setValue(latitudedeg);
    me.presets.getChild("longitude-deg").setValue(longitudedeg);

    me.setboatposition( latitudedeg, longitudedeg, moorage );

    me.presets.getChild("heading-deg").setValue(headingdeg);

    # forces the computation of ground
    me.presets.getChild("altitude-ft").setValue(-9999);

    me.presets.getChild("airspeed-kt").setValue(0);

    me.setadf( index, moorage );
}

Mooring.setadf = func( index, beacon ) {
   var frequency = 0.0;
   var adf = me.seaplanes[ index ].getNode("adf");

   if( adf != nil ) {
       frequency = adf.getChild("selected-khz");
       if( frequency != nil ) {
           frequencykz = frequency.getValue();
           setprop("/instrumentation/adf/frequencies/selected-khz",frequencykz);
       }
       frequency = adf.getChild("standby-khz");
       if( frequency != nil ) {
           frequencykz = frequency.getValue();
           setprop("/instrumentation/adf/frequencies/standby-khz",frequencykz);
       }
   }
}

Mooring.setboatposition = func( latitudedeg, longitudedeg, airport ) {
   # offset to be outside the hull
   var latitudedeg = latitudedeg + me.BOATDEG;
   var longitudedeg = longitudedeg + me.BOATDEG;

   setprop( "/systems/seat/position/boat-view/latitude-deg", latitudedeg );
   setprop( "/systems/seat/position/boat-view/longitude-deg", longitudedeg );

   me.mooring.getChild("boat-id").setValue(airport);

   me.boataltitude = constant.TRUE;
}

Mooring.setboatheight = func( altitudeft ) {
   setprop( "/systems/seat/position/boat-view/altitude-ft", altitudeft );

   me.boataltitude = constant.FALSE;
}

Mooring.setboatdefault = func {
   var airport = me.presets.getChild("airport-id").getValue();
   var latitudedeg = getprop("/position/latitude-deg");
   var longitudedeg = getprop("/position/longitude-deg");

   me.setboatposition( latitudedeg, longitudedeg, airport );

   me.setboatsea();
}

Mooring.setboatsea = func {
   var altitudeft = getprop("/position/altitude-ft");
   var aglft = getprop("/position/altitude-agl-ft");

   # sea level
   var altitudeft = altitudeft - aglft - constantaero.AGLFT;

   # boat level
   altitudeft = altitudeft + me.BOATFT;

   me.setboatheight( altitudeft );
}

# computes boat altitude, once seaplane on the water
Mooring.mooragechange = func {
   if( me.boataltitude ) {
       me.setboatsea();
   }
}

# tower changed by dialog (destination or airport location)
Mooring.towerchange = func {
   var latitudedeg = 0.0;
   var longitudedeg = 0.0;
   var altitudeft = 0.0;
   var harbour = "";
   var tower = getprop("/sim/tower/airport-id");

   if( tower != me.mooring.getChild("boat-id").getValue() ) {

       for(var i=0; i<size(me.seaplanes); i=i+1) {
           harbour = me.seaplanes[ i ].getChild("airport-id").getValue();
           if( harbour == tower ) {

               # boat corresponding to the tower
               latitudedeg = me.seaplanes[ i ].getChild("latitude-deg").getValue();
               longitudedeg = me.seaplanes[ i ].getChild("longitude-deg").getValue();

               me.setboatposition( latitudedeg, longitudedeg, tower );

               # rough guess of boat altitude from tower !
               altitudeft = getprop("/sim/tower/altitude-ft" );
               me.setboatheight( altitudeft );
               break;
           }
       }
   }
}

# change of airport
Mooring.presetairport = func {
   var airport = me.presets.getChild("airport-id").getValue();

   if( airport != nil and airport != "" ) {
       settimer(func{ me.presetseaplane(); },me.HARBOURSEC);
   }

   # unchanged
   else {
       settimer(func{ me.presetairport(); },me.AIRPORTSEC);
   }
}

# automatic seaplane preset
Mooring.presetseaplane = func {
   # wait for end of trim
   if( getprop("/sim/sceneryloaded") ) {
       settimer(func{ me.presetharbour(); },me.HARBOURSEC);
   }

   # wait for end of initialization
   else {
       settimer(func{ me.presetseaplane(); },me.HARBOURSEC);
   }
}

# goes to the harbour, once one has the tower
Mooring.presetharbour = func {
   var aglft = 0.0;
   var airport = "";
   var harbour = "";
   var found = constant.FALSE;

   if( getprop("/controls/mooring/automatic") ) {
       aglft = getprop("/position/altitude-agl-ft");

       # on sea
       if( aglft < me.FLIGHTFT ) {
           airport = me.presets.getChild("airport-id").getValue();
           if( airport != nil and airport != "" ) {
               for(var i=0; i<size(me.seaplanes); i=i+1) {
                   harbour = me.seaplanes[ i ].getChild("airport-id").getValue();

                   if( harbour == airport ) {
                       me.setmoorage( i, airport );

                       fgcommand("presets-commit", props.Node.new());

                       # presets cuts the engines
                       var eng = props.globals.getNode("/controls/engines");
                       if (eng != nil) {
                           foreach (var c; eng.getChildren("engine")) {
                                    c.getNode("magnetos", 1).setIntValue(3);
                           }
                       }

                       found = constant.TRUE;
                       break;
                   }
               }
           }
       }
   }

   # in flight
   if( !found ) {
       me.setboatdefault();
   }
}
