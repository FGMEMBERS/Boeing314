# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =====
# SEATS
# =====

# WARNING : only works if the seats are after the preferences.xml's views.

Seats = {};

Seats.new = func {
   var obj = { parents : [Seats,System],

               sextant : Sextant.new(),

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

   me.inherit_system("/systems/seat");

   # retrieve the index as created by FG
   for( var i = 0; i < size(me.dependency["views"]); i=i+1 ) {
        child = me.dependency["views"][i].getChild("name");
        # nasal doesn't see yet the views of preferences.xml
        if( child != nil ) {
            name = child.getValue();
            if( name == "Engineer View" ) {
                me.save_lookup("engineer", i);
            }
            elsif( name == "Navigator View" ) {
                me.save_lookup("navigator", i);
                me.save_initial( "navigator", me.dependency["views"][i] );
            }
            elsif( name == "Radio View" ) {
                me.save_lookup("radio", i);
            }
            elsif( name == "Copilot View" ) {
                me.save_lookup("copilot", i);
            }
            elsif( name == "Celestial View" ) {
                me.save_lookup("celestial", i);
                me.save_initial( "celestial", me.dependency["views"][i] );
            }
            elsif( name == "Observer View" ) {
                me.save_lookup("observer", i);
                me.save_initial( "observer", me.dependency["views"][i] );
            }
            elsif( name == "Boat View" ) {
                me.save_lookup("boat", i);
            }
            elsif( name == "Boat (landing) View" ) {
                me.save_lookup("boat2", i);
            }
            elsif( name == "Dock (terminal) View" ) {
                me.save_lookup("dock", i);
                me.save_initial( "dock", me.dependency["views"][i] );
            }
        }
   }

   # default
   me.recoverfloating = me.itself["root-ctrl"].getChild("recover").getValue();
}

Seats.recoverexport = func {
   me.recoverfloating = !me.recoverfloating;
   me.itself["root-ctrl"].getChild("recover").setValue(me.recoverfloating);
}

Seats.viewexport = func( name ) {
   var index = 0;

   if( name != "captain" ) {
       index = me.lookup[name];

       # swap to view
       if( !me.itself["root"].getChild(name).getValue() ) {
           me.dependency["current-view"].getChild("view-number").setValue(index);
           me.itself["root"].getChild(name).setValue(constant.TRUE);
           me.itself["root"].getChild("captain").setValue(constant.FALSE);

           me.dependency["views"][index].getChild("enabled").setValue(constant.TRUE);
       }

       # return to captain view
       else {
           me.dependency["current-view"].getChild("view-number").setValue(me.CAPTINDEX);
           me.itself["root"].getChild(name).setValue(constant.FALSE);
           me.itself["root"].getChild("captain").setValue(constant.TRUE);

           me.dependency["views"][index].getChild("enabled").setValue(constant.FALSE);
       }

       # disable all other views
       for( var i = 0; i < me.nb_seats; i=i+1 ) {
            if( name != me.names[i] ) {
                me.itself["root"].getChild(me.names[i]).setValue(constant.FALSE);

                index = me.lookup[me.names[i]];
                me.dependency["views"][index].getChild("enabled").setValue(constant.FALSE);
            }
       }

       me.recover();
   }

   # captain view
   else {
       me.dependency["current-view"].getChild("view-number").setValue(me.CAPTINDEX);
       me.itself["root"].getChild("captain").setValue(constant.TRUE);

       # disable all other views
       for( var i = 0; i < me.nb_seats; i=i+1 ) {
            me.itself["root"].getChild(me.names[i]).setValue(constant.FALSE);

            index = me.lookup[me.names[i]];
            me.dependency["views"][index].getChild("enabled").setValue(constant.FALSE);
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
        if( me.itself["root"].getChild(name).getValue() ) {
            targetview = me.lookup[name];
            break;
        }
   }

   # ignores captain view
   if( targetview > me.CAPTINDEX ) {
       me.dependency["views"][me.CAPTINDEX].getChild("enabled").setValue(constant.FALSE);
   }

   view.stepView(step);

   # restores because of userarchive
   if( targetview > me.CAPTINDEX ) {
       me.dependency["views"][me.CAPTINDEX].getChild("enabled").setValue(constant.TRUE);
   }
}

# forwards is positiv
Seats.movelengthexport = func( step ) {
   var sign = 0;
   var headdeg = 0.0;
   var pos = "";
   var axis = "";
   var result = constant.FALSE;

   if( me.move() ) {
       headdeg = me.dependency["current-view"].getChild("goal-heading-offset-deg").getValue();

       if( headdeg <= 45 or headdeg >= 315 ) {
           prop = "z-offset-m";
           sign = 1;
           axis = "z";
       }
       elsif( headdeg >= 135 and headdeg <= 225 ) {
           prop = "z-offset-m";
           sign = -1;
           axis = "z";
       }
       elsif( headdeg > 225 and headdeg < 315 ) {
           prop = "x-offset-m";
           sign = -1;
           axis = "x";
       }
       else {
           prop = "x-offset-m";
           sign = 1;
           axis = "x";
       }

       pos = me.dependency["current-view"].getChild(prop).getValue();
       pos = pos + sign * step;
       me.dependency["current-view"].getChild(prop).setValue(pos);

       result = constant.TRUE;
   }

   return result;
}

# left is negativ
Seats.movewidthexport = func( step ) {
   var sign = 0;
   var headdeg = 0.0;
   var pos = "";
   var axis = "";
   var result = constant.FALSE;

   if( me.move() ) {
       headdeg = me.dependency["current-view"].getChild("goal-heading-offset-deg").getValue();

       if( headdeg <= 45 or headdeg >= 315 ) {
           prop = "x-offset-m";
           sign = 1;
           axis = "x";
       }
       elsif( headdeg >= 135 and headdeg <= 225 ) {
           prop = "x-offset-m";
           sign = -1;
           axis = "x";
       }
       elsif( headdeg > 225 and headdeg < 315 ) {
           prop = "z-offset-m";
           sign = 1;
           axis = "z";
       }
       else {
           prop = "z-offset-m";
           sign = -1;
           axis = "z";
       }

       pos = me.dependency["current-view"].getChild(prop).getValue();
       pos = pos + sign * step;
       me.dependency["current-view"].getChild(prop).setValue(pos);

       result = constant.TRUE;
   }

   return result;
}

# up is positiv
Seats.moveheightexport = func( step ) {
   var pos = "";
   var result = constant.FALSE;

   if( me.move() ) {
       pos = me.dependency["current-view"].getChild("y-offset-m").getValue();
       pos = pos + step;
       me.dependency["current-view"].getChild("y-offset-m").setValue(pos);

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
   var position = me.itself["position"].getNode(name);

   var posx = me.initial[name]["x"];
   var posy = me.initial[name]["y"];
   var posz = me.initial[name]["z"];

   me.dependency["current-view"].getChild("x-offset-m").setValue(posx);
   me.dependency["current-view"].getChild("y-offset-m").setValue(posy);
   me.dependency["current-view"].getChild("z-offset-m").setValue(posz);

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
       position = me.itself["position"].getNode(name);

       posx = position.getChild("x-m").getValue();
       posy = position.getChild("y-m").getValue();
       posz = position.getChild("z-m").getValue();

       if( posx != me.initial[name]["x"] or
           posy != me.initial[name]["y"] or
           posz != me.initial[name]["z"] ) {

           me.dependency["current-view"].getChild("x-offset-m").setValue(posx);
           me.dependency["current-view"].getChild("y-offset-m").setValue(posy);
           me.dependency["current-view"].getChild("z-offset-m").setValue(posz);
       }

       me.last_recover[ name ] = constant.TRUE;
   }
}

Seats.recover = func {
   var name = "";

   for( var i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.itself["root"].getChild(name).getValue() ) {
            if( me.floating[name] ) {
                me.last_position( name );
            }
            break;
        }
   }
}

Seats.move_position = func( name ) {
   var posx = me.dependency["current-view"].getChild("x-offset-m").getValue();
   var posy = me.dependency["current-view"].getChild("y-offset-m").getValue();
   var posz = me.dependency["current-view"].getChild("z-offset-m").getValue();

   var position = me.itself["position"].getNode(name);

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
        if( me.itself["root"].getChild(name).getValue() ) {
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
        if( me.itself["root"].getChild(name).getValue() ) {
            if( me.floating[name] ) {
                me.initial_position( name );
            }
            break;
        }
   }
}

# restore view pitch
Seats.restorepitchexport = func {
   var index = me.dependency["current-view"].getChild("view-number").getValue();

   if( index == me.CAPTINDEX ) {
       var headingdeg = me.dependency["views"][index].getNode("config").getChild("heading-offset-deg").getValue();
       var pitchdeg = me.dependency["views"][index].getNode("config").getChild("pitch-offset-deg").getValue();

       me.dependency["current-view"].getChild("heading-offset-deg").setValue(headingdeg);
       me.dependency["current-view"].getChild("pitch-offset-deg").setValue(pitchdeg);
   }

   # only cockpit views
   else {
       var name = "";

       for( var i = 0; i < me.nb_seats; i=i+1 ) {
            name = me.names[i];
            if( me.itself["root"].getChild(name).getValue() ) {
                var headingdeg = me.dependency["views"][index].getNode("config").getChild("heading-offset-deg").getValue();
                var pitchdeg = me.dependency["views"][index].getNode("config").getChild("pitch-offset-deg").getValue();

                me.dependency["current-view"].getChild("heading-offset-deg").setValue(headingdeg);
                me.dependency["current-view"].getChild("pitch-offset-deg").setValue(pitchdeg);
                break;
            }
        }
   }
}

Seats.polarisexport = func {
    if( !me.itself["root"].getChild("celestial").getValue() ) {
        me.viewexport("celestial");
    }

    me.sextant.polarisexport();
}


# ====
# MENU
# ====

Menu = {};

Menu.new = func {
   var obj = { parents : [Menu,System],

               autopilot : nil,
               crew : nil,
               environment : nil,
               fuel : nil,
               gdf : nil,
               immat : nil,
               moorage : nil,
               procedures : {},
               views : nil,
               voice : {},
               menu : nil
         };

   obj.init();

   return obj;
};

Menu.init = func {
   me.inherit_system("/systems/crew"); 

   me.menu = me.dialog( "menu" );
   me.autopilot = me.dialog( "autopilot" );
   me.crew = me.dialog( "crew" );
   me.environment = me.dialog( "environment" );
   me.fuel = me.dialog( "fuel" );
   me.gdf = me.dialog( "gdf" );
   me.immat = me.dialog( "immat" );
   me.moorage = me.dialog( "moorage" );

   me.array( me.procedures, 2, "procedures" );

   me.views = me.dialog( "views" );

   me.array( me.voice, 2, "voice" );

   me.immatexport();
}

Menu.immatexport = func {
   var step = 0;
   var immatsplit = [ "", "" ];
   var immat = "";
   
   for( var i = 0; i < size(me.itself["immat"]); i=i+1 )
   {
        immat = me.itself["immat"][i].getValue();

        # NC 18609 => NC + 18609
        if ( i == 0 ) {
	     immatsplit[0] = substr( immat, 0, 2 );
	     immatsplit[1] = substr( immat, 3 );
	}
	# G-AGBZ   => G-A + GBZ
	else {
	     immatsplit[0] = substr( immat, 0, 3 );
	     immatsplit[1] = substr( immat, 3 );
	}

        step = 2 * i;
        me.itself["root"].getChildren("immat")[0 + step].setValue(immatsplit[0]);
        me.itself["root"].getChildren("immat")[1 + step].setValue(immatsplit[1]);
   }
}

Menu.resetexport = func {
   me.itself["immat"][0].setValue("NC 18609");
   me.itself["immat"][1].setValue("G-AGBZ");

   me.immatexport();
}

Menu.dialog = func( name ) {
   var item = gui.Dialog.new(me.itself["dialogs"].getPath() ~ "/" ~ name ~ "/dialog",
                             "Aircraft/Boeing314/Dialogs/Boeing314-" ~ name ~ ".xml");

   return item;
}

Menu.array = func( table, max, name ) {
   var j = 0;

   for( var i = 0; i < max; i=i+1 ) {
        if( j == 0 ) {
            j = "";
        }
        else {
            j = i + 1;
        }

        table[i] = gui.Dialog.new(me.itself["dialogs"].getValue() ~ "/" ~ name ~ "[" ~ i ~ "]/dialog",
                                  "Aircraft/Boeing314/Dialogs/Boeing314-" ~ name ~ j ~ ".xml");
   }
}


# ========
# CREW BOX
# ========

Crewbox = {};

Crewbox.new = func {
   var obj = { parents : [Crewbox,System],

               MENUSEC : 3.0,

               timers : 0.0,

# left bottom, 1 line, 10 seconds.
               BOXX : 10,
               BOXY : 34,
               BOTTOMY : -768,
               LINEY : 20,

               lineindex : { "speedup" : 0, "checklist" : 1, "engineer" : 2, "copilot" : 3 },
               lasttext : [ "", "", "", "" ],
               textbox : [ nil, nil, nil, nil ],
               nblines : 4
         };

    obj.init();

    return obj;
};

Crewbox.init = func {
    me.inherit_system("/systems/crew"); 

    me.resize();

    setlistener(me.noinstrument["startup"].getPath(), crewboxresizecron);
    setlistener(me.noinstrument["speed-up"].getPath(), crewboxcron);
    setlistener(me.noinstrument["freeze"].getPath(), crewboxcron);
}

Crewbox.resize = func {
    var y = 0;
    var ysize = - me.noinstrument["startup"].getValue();

    if( ysize == nil ) {
        ysize = me.BOTTOMY;
    }

    # must clear the text, otherwise text remains after close
    me.clear();

    for( var i = 0; i < me.nblines; i = i+1 ) {
         # starts at 700 if height is 768
         y = ysize + me.BOXY + me.LINEY * i;

         # not really deleted
         if( me.textbox[i] != nil ) {
             me.textbox[i].close();
         }

         # CAUTION : duration is 0 (infinite), or one must wait that the text vanishes device;
         # otherwise, overwriting the text makes the view popup tip always visible !!!
         me.textbox[i] = screen.window.new( me.BOXX, y, 1, 0 );
    }

    me.crewtext();
    me.pausetext();
}

Crewbox.pausetext = func {
    var index = me.lineindex["speedup"];
    var speedup = 0.0;
    var red = constant.FALSE;
    var text = "";

    if( me.noinstrument["freeze"].getValue() ) {
        text = "pause";
    }
    else {
        speedup = me.noinstrument["speed-up"].getValue();
        if( speedup > 1 ) {
            text = sprintf( speedup, "3f.0" ) ~ "  t";
        }
        red = constant.TRUE;
    }

    me.sendpause( index, red, text );
}

crewboxresizecron = func {
    crewscreen.resize();
}

crewboxcron = func {
    crewscreen.pausetext();
}

Crewbox.minimizeexport = func {
    var value = me.itself["root"].getChild("minimized").getValue();

    me.itself["root"].getChild("minimized").setValue(!value);

    me.resettimer();
}

Crewbox.wakeupexport = func {
    # display is minimized by timeout, or by picking 2D clue.
    if( !me.itself["root-ctrl"].getChild("timeout").getValue() and
        !me.dependency["human"].getChild("serviceable").getValue() ) {
        # wake up display
        if( me.itself["root"].getChild("minimized").getValue() ) {
            me.itself["root"].getChild("minimized").setValue(constant.FALSE);

            me.resettimer();
        }
    }
}

Crewbox.toggleexport = func {
    # 2D feedback
    if( !me.dependency["human"].getChild("serviceable").getValue() ) {
        me.itself["root"].getChild("minimized").setValue(constant.FALSE);
        me.resettimer();
    }

    # to accelerate display
    me.crewtext();
}

Crewbox.schedule = func {
    # timeout on text box
    if( me.itself["root-ctrl"].getChild("timeout").getValue() ) {
        me.timers = me.timers + me.MENUSEC;
        if( me.timers >= me.timeoutsec() ) {
            me.itself["root"].getChild("minimized").setValue(constant.TRUE);
        }
    }

    me.crewtext();
}

Crewbox.timeoutsec = func {
    var result = me.itself["root-ctrl"].getChild("timeout-s").getValue();

    if( result < me.MENUSEC ) {
        result = me.MENUSEC;
    }

    return result;
}

Crewbox.resettimer = func {
    me.timers = 0.0;

    me.crewtext();
}

Crewbox.crewtext = func {
    if( !me.itself["root"].getChild("minimized").getValue() ) {
        me.checklisttext();
        me.copilottext();
        me.engineertext();
    }
    else {
        me.clearcrew();
    }
}

Crewbox.checklisttext = func {
    var white = constant.FALSE;
    var text = me.dependency["voice"].getChild("callout").getValue();
    var text2 = me.dependency["voice"].getChild("checklist").getValue();
    var text = "";
    var text2 = "";
    var index = me.lineindex["checklist"];

    if( text2 != "" ) {
        text = text2 ~ " " ~ text;
        white = me.dependency["voice"].getChild("real").getValue();
    }

    # real checklist is white
    me.sendtext( index, constant.TRUE, white, text );
}

Crewbox.copilottext = func {
    var green = constant.FALSE;
    var text = me.dependency["copilot"].getChild("state").getValue();
    var index = me.lineindex["copilot"];

    if( text == "" ) {
        if( me.dependency["copilot-ctrl"].getChild("activ").getValue() ) {
            text = "copilot";
        }
    }

    if( me.dependency["copilot"].getChild("activ").getValue() ) {
        green = constant.TRUE;
    }

    me.sendtext( index, green, constant.FALSE, text );
}

Crewbox.engineertext = func {
    var green = me.dependency["engineer"].getChild("activ").getValue();
    var text = me.dependency["engineer"].getChild("state").getValue();
    var index = me.lineindex["engineer"];

    if( text == "" ) {
        if( me.dependency["engineer-ctrl"].getChild("activ").getValue() ) {
            text = "engineer";
        }
    }

    me.sendtext( index, green, constant.FALSE, text );
}

Crewbox.sendtext = func( index, green, white, text ) {
    var box = me.textbox[index];

    me.lasttext[index] = text;

    # bright white
    if( white ) {
        box.write( text, 1.0, 1.0, 1.0 );
    }

    # dark green
    elsif( green ) {
        box.write( text, 0, 0.7, 0 );
    }

    # dark yellow
    else {
        box.write( text, 0.7, 0.7, 0 );
    }
}

Crewbox.sendpause = func( index, red, text ) {
    var box = me.textbox[index];

    me.lasttext[index] = text;

    # bright red
    if( red ) {
        box.write( text, 1.0, 0, 0 );
    }
    # bright yellow
    else {
        box.write( text, 1.0, 1.0, 0 );
    }
}

Crewbox.clearcrew = func {
    for( var i = 1; i < me.nblines; i = i+1 ) {
         if( me.lasttext[i] != "" ) {
             me.lasttext[i] = "";
             me.textbox[i].write( me.lasttext[i], 0, 0, 0 );
         }
    }
}

Crewbox.clear = func {
    for( var i = 0; i < me.nblines; i = i+1 ) {
         if( me.lasttext[i] != "" ) {
             me.lasttext[i] = "";
             me.textbox[i].write( me.lasttext[i], 0, 0, 0 );
         }
    }
}


# =========
# VOICE BOX
# =========

Voicebox = {};

Voicebox.new = func {
   var obj = { parents : [Voicebox,System],

               seetext : constant.TRUE,

# centered in the vision field, 1 line, 10 seconds.
               textbox : screen.window.new( nil, -200, 1, 10 )
   };

   obj.init();

   return obj;
}

Voicebox.init = func {
   me.inherit_system("/systems/voice");
}

Voicebox.schedule = func {
   me.seetext = me.itself["root-ctrl"].getChild("text").getValue();
}

Voicebox.textexport = func {
   var feedback = "";

   if( me.seetext ) {
       feedback = "crew text off";
       me.seetext = constant.FALSE;
   }
   else {
       feedback = "crew text on";
       me.seetext = constant.TRUE;
   }

   me.sendtext( feedback, !me.seetext, constant.FALSE, constant.TRUE );
   me.itself["root-ctrl"].getChild("text").setValue(me.seetext);

   return feedback;
}

Voicebox.is_on = func {
   return me.seetext;
}

Voicebox.sendtext = func( text, engineer = 0, captain = 0, force = 0 ) {
   if( me.seetext or force ) {
       # bright blue
       if( engineer ) {
           me.textbox.write( text, 0, 1, 1 );
       }

       # bright yellow
       elsif( captain ) {
           me.textbox.write( text, 1, 1, 0 );
       }

       # bright green
       else {
           me.textbox.write( text, 0, 1, 0 );
       }
   }
}


# ==============
# MOORING DIALOG
# ==============

MooringDialog = {};

MooringDialog.new = func {
   var obj = { parents : [MooringDialog,System],
               
               airports : {}

         };

   obj.init();

   return obj;
};

MooringDialog.init = func {
   me.inherit_system("/systems/mooring");
   
   me.filldialog();
}

MooringDialog.seaportexport = func {
   if( me.itself["root-ctrl"].getChild("seaport").getValue() ) {
       me.enableseaport();
   }
   else {
       me.disableseaport();
   }
}

MooringDialog.getmoorage = func {
   var result = "";
   var dialog = me.itself["root"].getChild("dialog").getValue();
   
   var idcomment = split( " ", dialog );
   
   if( me.itself["root-ctrl"].getNode("sort").getChild("name").getValue() or
       me.itself["root-ctrl"].getNode("sort").getChild("distance").getValue() ) {
       var nbstrings = size(idcomment);
       
       # last
       result = idcomment[nbstrings-1];
   }
   else {
       # KSFO  Treasure Island ==> KSFO
       result = idcomment[0];
   }
   
   return result;
}

MooringDialog.filldialog = func {
   var byDistance = constant.FALSE;
   var byName = constant.FALSE;
   var include = constant.TRUE;
   var routeAtlantic = constant.FALSE;
   var routeAtlantic2 = constant.FALSE;
   var routeAtlantic3 = constant.FALSE;
   var routeAtlantic4 = constant.FALSE;
   var routeAtlanticWinter = constant.FALSE;
   var routeAtlanticWinter2 = constant.FALSE;
   var routeAtlanticWinter3 = constant.FALSE;
   var routeAtlanticWinter4 = constant.FALSE;
   var routeOther = constant.FALSE;
   var routePacific = constant.FALSE;
   var routePacific2 = constant.FALSE;
   var routeRoundWorld = constant.FALSE;
   var distancenm = 0;
   var listLength = 0;
   var no = -1;
   var distancemeter = 0.0;
   var harbour = "";
   var name = "";
   var route = "";
   var child = nil;
   var info = nil;
   var wptStart = nil;
   var wpt = geo.Coord.new();
   var location = nil;
   var airports = {};

   
   routeAtlantic = me.itself["root-ctrl"].getNode("category").getChild("atlantic").getValue();
   routeAtlantic2 = me.itself["root-ctrl"].getNode("category").getChild("atlantic2").getValue();
   routeAtlantic3 = me.itself["root-ctrl"].getNode("category").getChild("atlantic3").getValue();
   routeAtlantic4 = me.itself["root-ctrl"].getNode("category").getChild("atlantic4").getValue();
   routeAtlanticWinter = me.itself["root-ctrl"].getNode("category").getChild("atlantic-winter").getValue();
   routeAtlanticWinter2 = me.itself["root-ctrl"].getNode("category").getChild("atlantic-winter2").getValue();
   routeAtlanticWinter3 = me.itself["root-ctrl"].getNode("category").getChild("atlantic-winter3").getValue();
   routeAtlanticWinter4 = me.itself["root-ctrl"].getNode("category").getChild("atlantic-winter4").getValue();
   routeOther = me.itself["root-ctrl"].getNode("category").getChild("other").getValue();
   routePacific = me.itself["root-ctrl"].getNode("category").getChild("pacific").getValue();
   routePacific2 = me.itself["root-ctrl"].getNode("category").getChild("pacific2").getValue();
   routeRoundWorld = me.itself["root-ctrl"].getNode("category").getChild("round-the-world").getValue();


   if( routeAtlantic ) {
       route = "atlantic";
   }
   elsif( routeAtlantic2 ) {
       route = "atlantic2";
   }
   elsif( routeAtlantic3 ) {
       route = "atlantic3";
   }
   elsif( routeAtlantic4 ) {
       route = "atlantic4";
   }
   elsif( routeAtlanticWinter ) {
       route = "atlantic-winter";
   }
   elsif( routeAtlanticWinter2 ) {
       route = "atlantic-winter2";
   }
   elsif( routeAtlanticWinter3 ) {
       route = "atlantic-winter3";
   }
   elsif( routeAtlanticWinter4 ) {
       route = "atlantic-winter4";
   }
   elsif( routePacific ) {
       route = "pacific";
   }
   elsif( routePacific2 ) {
       route = "pacific2";
   }
   elsif( routeRoundWorld ) {
       route = "round-the-world";
   }
   
   if( route != "" ) {
       wptStart = me.getGeoStart(route);
   }
   elsif( routeOther ) {
       wptStart = me.getGeoStart("other");
   }
   else {
       wptStart = me.getGeoStart("everything");
   }

   
   me.airports = {};
   
   listLength = size(me.itself["seaplane"]);
   for( var i=0; i<listLength; i=i+1 ) {
        harbour = me.itself["seaplane"][ i ].getChild("airport-id").getValue();
        
        info = airportinfo( harbour );
        if( info != nil ) {
            if( wptStart != nil ) {
                wpt.set_latlon( info.lat, info.lon );
                distancemeter = wptStart.distance_to( wpt );
                distancenm = int(distancemeter / constant.NMTOMETER);
            }

            name = me.itself["seaplane"][ i ].getChild("name").getValue();
        
            location = me.itself["seaplane"][i].getChildren("location");
        
            # identify terminals
            for( var j=0; j<size(location); j=j+1 ) {
                 child = location[ j ].getChild("terminal");

                 if( child != nil ) {
                     if( child.getValue() ) {
                         name = name ~ " *";

                         break;
                     }
                 }
            }
            
            include = constant.TRUE;      
            
            if( include and route != "" ) {
	        include = me.getRoute( i, route );
            }
            
            elsif( include and routeOther ) {
                if( me.getRoute( i, "atlantic" ) or me.getRoute( i, "atlantic2" ) or me.getRoute( i, "atlantic3" ) or me.getRoute( i, "atlantic4" ) or
                    me.getRoute( i, "atlantic-winter" ) or me.getRoute( i, "atlantic-winter2" ) or me.getRoute( i, "atlantic-winter3" ) or me.getRoute( i, "atlantic-winter4" ) or
                    me.getRoute( i, "pacific" ) or me.getRoute( i, "pacific2" ) or me.getRoute( i, "round-the-world" ) ) {
	            include = constant.FALSE;
	        }
            }
        
            if( include ) {
                no = me.getNo( i, route );
                me.airports[harbour] = { id : harbour, label : name, rangenm : distancenm, rank : no };
            }
        }
        else {
	    print( "no airport info found for ", harbour );
        }
   }
   
   
   var node = me.itself["root"].getNode("list");
   var sortedairports = {};
   
   byDistance = me.itself["root-ctrl"].getNode("sort").getChild("distance").getValue();
   byName = me.itself["root-ctrl"].getNode("sort").getChild("name").getValue();
   
   if( byDistance ) {
       sortedairports = sort (keys(me.airports), func (a,b) me.compare_distance(a,b));
   }
   elsif( byName ) {
       sortedairports = sort (keys(me.airports), func (a,b) cmp (me.airports[a].label, me.airports[b].label));
   }
   else {
       sortedairports = sort (keys(me.airports), func (a,b) cmp (me.airports[a].id, me.airports[b].id));
   }
   
   
   var k = 0;
   foreach( var ident; sortedairports ) {
       if( byDistance ) {
           name = me.airports[ident].label ~ "  " ~ me.airports[ident].rangenm ~ "  " ~ ident;
       }
       elsif( byName ) {
           name = me.airports[ident].label ~ "  " ~ ident;
       }
       else {
           name = ident ~ "  " ~ me.airports[ident].label;
       }
        
       child = node.getNode("value[" ~ k ~ "]",constant.DELAYEDNODE);
       child.setValue(name);
       
       k = k+1;
   }
   
   # remove older entries of the list on screen
   listLength = size(me.itself["root"].getNode("list").getChildren("value"));
   for( var i=listLength-1; i>=k; i=i-1 ) {
        me.itself["root"].getNode("list").removeChild("value",i);
   }
}

MooringDialog.getNo = func( index, route ) {
   var result = -1;
   var child = nil;
   
   child = me.itself["seaplane"][ index ].getChild("route-" ~ route);
   if( child != nil ) {
       result = child.getValue();
   }
            
   return result;
}

MooringDialog.getRoute = func( index, route ) {
   var result = constant.FALSE;
   var child = nil;
   
   child = me.itself["seaplane"][ index ].getChild("route-" ~ route);
   if( child != nil ) {
       result = constant.TRUE;
   }
            
   return result;
}

MooringDialog.getRouteStart = func( route ) {
   var listLength = 0;
   var result = "";
   var child = nil;
   
   listLength = size(me.itself["seaplane"]);
   for( var i=0; i<listLength; i=i+1 ) {
        child = me.itself["seaplane"][ i ].getChild("route-" ~ route);
        if( child != nil ) {
            if( child.getValue() == 0 ) {
                result = me.itself["seaplane"][ i ].getChild("airport-id").getValue();
                
                break;
            }
        }
   }
   
   return result;
}

MooringDialog.getGeoStart = func( route ) {
   var wptLast = "";
   var info = nil;
   var result = nil;
   
   
   wptLast = me.getRouteStart(route);
   
   if( wptLast != "" ) {
       info = airportinfo( wptLast );
       if( info != nil ) {
           result = geo.Coord.new();
           result.set_latlon( info.lat, info.lon );
       }
       else {
           print( "no information found for route start " ~ wptLast );
        }
   }
   else {
       print( "no start found for route " ~ route );
   }
   
   return result;
}

MooringDialog.compare_distance = func( a, b ) {
   var result = 0;
   var distancenm = 0;
   var distancenm2 = 0;
  
   result = me.compare_rank( a, b );
   
   # try distance, if no ordering
   if( result == 0 ) {
       distancenm = me.airports[a].rangenm;
       distancenm2 = me.airports[b].rangenm;
  
       if( distancenm < distancenm2 ) {
           result = -1;
       }
       elsif( distancenm > distancenm2 ) {
           result = 1;
       }
   }
   
   return result;
}

MooringDialog.compare_rank = func( a, b ) {
   var result = 0;
   var rank = 0;
   var rank2 = 0;
  
   rank = me.airports[a].rank;
   rank2 = me.airports[b].rank;
  
   if( rank < rank2 ) {
       result = -1;
   }
   elsif( rank > rank2 ) {
       result = 1;
   }
   
   return result;
}

MooringDialog.enableseaport = func {
   me.dependency["seaport"].setValue("seaplane");
}

MooringDialog.disableseaport = func {
   me.dependency["seaport"].setValue("");
}
