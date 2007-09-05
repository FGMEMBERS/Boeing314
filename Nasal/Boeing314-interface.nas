# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =====
# SEATS
# =====

# WARNING : only works if the seats are after the preferences.xml's views.

Seats = {};

Seats.new = func {
   obj = { parents : [Seats],

           sextant : Sextant.new(),

           controls : nil,
           positions : nil,
           theseats : nil,

           lookup : {},
           names : {},
           nb_seats : 0,

           floating : {},
           recoverfloating : constant.FALSE,
           last_recover : {},
           initial : {}
         };

   obj.init();

   return obj;
};

Seats.init = func {
   me.controls = props.globals.getNode("/controls/seat");
   me.positions = props.globals.getNode("/systems/seat/position");
   me.theseats = props.globals.getNode("/systems/seat");

   theviews = props.globals.getNode("/sim").getChildren("view");
   last = size(theviews);

   # retrieve the index as created by FG
   for( i = 0; i < last; i=i+1 ) {
        child = theviews[i].getChild("name");
        # nasal doesn't see yet the views of preferences.xml
        if( child != nil ) {
            name = theviews[i].getChild("name").getValue();
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
                me.save_initial( "celestial", theviews[i] );
            }
            elsif( name == "Observer View" ) {
                me.save_lookup("observer", i);
                me.save_initial( "observer", theviews[i] );
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
   if( name != "captain" ) {

       # swap to view
       if( !me.theseats.getChild(name).getValue() ) {
           index = me.lookup[name];
           setprop("/sim/current-view/view-number", index);
           me.theseats.getChild(name).setValue(constant.TRUE);
           me.theseats.getChild("captain").setValue(constant.FALSE);
       }

       # return to captain view
       else {
           setprop("/sim/current-view/view-number", 0);
           me.theseats.getChild(name).setValue(constant.FALSE);
           me.theseats.getChild("captain").setValue(constant.TRUE);
       }

       # disable all other views
       for( i = 0; i < me.nb_seats; i=i+1 ) {
            if( name != me.names[i] ) {
                me.theseats.getChild(me.names[i]).setValue(constant.FALSE);
            }
       }

       me.recover();
   }

   # captain view
   else {
       setprop("/sim/current-view/view-number",0);
       me.theseats.getChild("captain").setValue(constant.TRUE);

        # disable all other views
        for( i = 0; i < me.nb_seats; i=i+1 ) {
             me.theseats.getChild(me.names[i]).setValue(constant.FALSE);
        }
   }
}

Seats.scrollexport = func{
   # number of views = 11
   nbviews = size(props.globals.getNode("/sim").getChildren("view"));

   # by default, returns to captain view
   targetview = nbviews;

   # if specific view, step once more to ignore captain view 
   for( i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.theseats.getChild(name).getValue() ) {
            targetview = me.lookup[name];
            break;
        }
   }

   # number of default views (preferences.xml) = 6
   nbdefaultviews = nbviews - me.nb_seats;

   # last default view (preferences.xml) = 5
   lastview = nbdefaultviews - 1;

   # moves to seat
   if( getprop("/sim/current-view/view-number") == lastview ) {
       step = targetview - nbdefaultviews;
       view.stepView(step);
       view.stepView(1);
   }

   # returns to captain
   elsif( getprop("/sim/current-view/view-number") == targetview ) {
       step = nbviews - targetview;
       view.stepView(step);
       view.stepView(1);
   }

   # default
   else {
       view.stepView(1);
   }
}

Seats.scrollreverseexport = func{
   # number of views = 11
   nbviews = size(props.globals.getNode("/sim").getChildren("view"));

   # by default, returns to captain view
   targetview = 0;

   # if specific view, step once more to ignore captain view 
   for( i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.theseats.getChild(name).getValue() ) {
            targetview = me.lookup[name];
            break;
        }
   }

   # number of default views (preferences.xml) = 6
   nbdefaultviews = nbviews - me.nb_seats;

   # last view = 10
   lastview = nbviews - 1;

   # moves to seat
   if( getprop("/sim/current-view/view-number") == 1 ) {
       # to 0
       view.stepView(-1);
       # to last
       view.stepView(-1);
       step = targetview - lastview;
       view.stepView(step);
    }

   # returns to captain
    elsif( getprop("/sim/current-view/view-number") == targetview ) {
        step = nbdefaultviews - targetview;
        view.stepView(step);
        view.stepView(-1);
    }

    # default
    else {
        view.stepView(-1);
    }
}

# forwards is positiv
Seats.movelengthexport = func( name, step ) {
   if( !me.move() ) {
       result = constant.FALSE;
   }

   else {
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
   if( !me.move() ) {
       result = constant.FALSE;
   }

   else {
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
   if( !me.move() ) {
       result = constant.FALSE;
   }

   else {
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

   config = view.getNode("config");

   pos["x"] = config.getChild("x-offset-m").getValue();
   pos["y"] = config.getChild("y-offset-m").getValue();
   pos["z"] = config.getChild("z-offset-m").getValue();

   me.initial[name] = pos;

   me.floating[name] = constant.TRUE;
   me.last_recover[name] = constant.FALSE;
}

Seats.initial_position = func( name ) {
   position = me.positions.getNode(name);

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
   for( i = 0; i < me.nb_seats; i=i+1 ) {
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
   posx = getprop("/sim/current-view/x-offset-m");
   posy = getprop("/sim/current-view/y-offset-m");
   posz = getprop("/sim/current-view/z-offset-m");

   position = me.positions.getNode(name);

   position.getChild("x-m").setValue(posx);
   position.getChild("y-m").setValue(posy);
   position.getChild("z-m").setValue(posz);
}

Seats.move = func {
   result = constant.FALSE;

   # saves previous position
   for( i = 0; i < me.nb_seats; i=i+1 ) {
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
   for( i = 0; i < me.nb_seats; i=i+1 ) {
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
   obj = { parents : [Menu],

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
   obj = { parents : [Mooring],

           mooring : nil,
           presets : nil,
           seaplanes : nil,

           MOORINGSEC : 5.0,
           AIRPORTSEC : 3.0,
           HARBOURSEC : 1.0,

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
   dialog = me.mooring.getChild("dialog").getValue();
   
   # KSFO  Treasure Island ==> KSFO
   idcomment = split( " ", dialog );
   moorage = idcomment[0];

   for(i=0; i<size(me.seaplanes); i=i+1) {
       harbour = me.seaplanes[ i ].getChild("airport-id").getValue();

       if( harbour == moorage ) {
           me.setmoorage( i, moorage );

           me.presets.getChild("altitude-ft").setValue(-9999);
           me.presets.getChild("airspeed-kt").setValue(0);

           setprop("/sim/tower/airport-id",moorage);
           break;
       }
   }
}

Mooring.setmoorage = func( index, moorage ) {
    latitudedeg = me.seaplanes[ index ].getChild("latitude-deg").getValue();
    me.presets.getChild("latitude-deg").setValue(latitudedeg);
    longitudedeg = me.seaplanes[ index ].getChild("longitude-deg").getValue();
    me.presets.getChild("longitude-deg").setValue(longitudedeg);

    me.setboatposition( latitudedeg, longitudedeg, moorage );

    headingdeg = me.seaplanes[ index ].getChild("heading-deg").getValue();
    me.presets.getChild("heading-deg").setValue(headingdeg);

    me.setadf( index, moorage );
}

Mooring.setadf = func( index, beacon ) {
   adf = me.seaplanes[ index ].getNode("adf");

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
   latitudedeg = latitudedeg + me.BOATDEG;
   longitudedeg = longitudedeg + me.BOATDEG;

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
   airport = me.presets.getChild("airport-id").getValue();
   latitudedeg = getprop("/position/latitude-deg");
   longitudedeg = getprop("/position/longitude-deg");

   me.setboatposition( latitudedeg, longitudedeg, airport );

   me.setboatsea();
}

Mooring.setboatsea = func {
   altitudeft = getprop("/position/altitude-ft");
   aglft = getprop("/position/altitude-agl-ft");

   # sea level
   altitudeft = altitudeft - aglft - constantaero.AGLFT;

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
   tower = getprop("/sim/tower/airport-id");
   if( tower != me.mooring.getChild("boat-id").getValue() ) {

       for(i=0; i<size(me.seaplanes); i=i+1) {
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
   airport = me.presets.getChild("airport-id").getValue();
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
   found = constant.FALSE;

   if( getprop("/controls/mooring/automatic") ) {
       # on sea
       if( getprop("/position/altitude-agl-ft") < me.FLIGHTFT ) {
           airport = me.presets.getChild("airport-id").getValue();
           if( airport != nil and airport != "" ) {
               for(i=0; i<size(me.seaplanes); i=i+1) {
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
