# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =================
# AUTOMATIC MOORING
# =================

Mooring = {};

Mooring.new = func {
   var obj = { parents : [Mooring,System],

               copilotcrew : nil,

               anchor : Anchor.new(),
               dock : Dock.new(),
               landingboat : LandingBoat.new(),
               takeoffboat : Boat.new(),
               dialog : MooringDialog.new(),

               mooringlanding : constant.FALSE,

               BOATSEC : 60.0,
               MOORINGSEC : 5.0,
               AIRPORTSEC : 3.0,
               HARBOURSEC : 2.0,

               UNKNOWNDEG : 999,

               lastwinddeg : 999,

               APPROACHFT : 3000,

               EARTHKM : 20000,                                        # largest distance between 2 points on earth surface
               PORTNM : 100,                                           # distance when the boat moves

               DESCENTFTPS : -1.67                                     # 100 ft/min
         };

   obj.init();

   return obj;
};

Mooring.init = func {
   me.inherit_system("/systems/mooring");

   me.landingboat.set_relation( me.takeoffboat );

   me.presetseaplane();
}

Mooring.set_relation = func( copilot ) {
   me.copilotcrew = copilot;
}

Mooring.allowedexport = func {
   return me.anchor.allowedexport();
}

Mooring.seaportexport = func {
   me.dialog.seaportexport();
}

Mooring.orderexport = func {
   me.dialog.filldialog();
}

Mooring.schedule = func {
   me.anchor.cut();

   # work around for 2.4.0 : properties may be reset.
   if( me.itself["root"].getChild("boat-id").getValue() == "" ) {
       me.takeoffboat.restore();
       me.landingboat.restore();
       me.dock.restore();
   }
}

Mooring.slowschedule = func {
   me.towerchange();
}

Mooring.dialogexport = func {
   var moorage = me.dialog.getmoorage();

   me.findairport( moorage );
}

Mooring.repeatexport = func {
   var moorage = me.itself["root"].getChild("boat-id").getValue();
   
   me.findairport( moorage );
}

Mooring.findairport = func( moorage ) {
   var harbour = "";
   
   for(var i=0; i<size(me.itself["seaplane"]); i=i+1) {
       harbour = me.itself["seaplane"][ i ].getChild("airport-id").getValue();

       if( harbour == moorage ) {
           me.setmoorage( i, moorage );

           break;
       }
   }
}

Mooring.setmoorage = func( index, moorage ) {
    var found = constant.FALSE;
    var latitudedeg = 0.0;
    var longitudedeg = 0.0;
    var headingdeg = constant.DEG0;
    var location = nil;


    # automatic mooring is not compatible with seaport dialog
    me.dialog.disableseaport();


    # terminal independant of wind 
    var index1 = me.findterminal( index, moorage );
    if( index1 >= 0 ) {
        if( me.itself["root-ctrl"].getNode("wind").getChild("terminal").getValue() ) {
            location = me.itself["seaplane"][index].getChildren("location");

            latitudedeg = location[ index1 ].getChild("latitude-deg").getValue();
            longitudedeg = location[ index1 ].getChild("longitude-deg").getValue();
            headingdeg = location[ index1 ].getChild("heading-deg").getValue();

            found = constant.TRUE;
        }
    }

    
    # wind coherent for both views
    me.lastwinddeg = me.noinstrument["wind"].getValue();

    # best mooring according to the wind
    var index2 = me.findmoorage( index, constant.FALSE, me.lastwinddeg );
    if( index2 >= 0 and !found ) {
        location = me.itself["seaplane"][index].getChildren("location");

        latitudedeg = location[ index2 ].getChild("latitude-deg").getValue();
        longitudedeg = location[ index2 ].getChild("longitude-deg").getValue();
        headingdeg = location[ index2 ].getChild("heading-deg").getValue();

        found = constant.TRUE;
        print( "314 : moorage found near ", moorage );
    }
        
    # default dock, if no terminal
    if( index1 < 0 ) {
        index1 = index2
    }

    me.dock.setmoorage( index, index1 );

    me.takeoffboat.setmoorage( index, index2, moorage );


    # boat waiting at the landing end
    var index3 = me.findmoorage( index, constant.TRUE, me.lastwinddeg );

    me.landingboat.setmoorage( index, index3, moorage );


    # apply
    if( found ) {
        me.dependency["presets"].getChild("latitude-deg").setValue(latitudedeg);
        me.dependency["presets"].getChild("longitude-deg").setValue(longitudedeg);
        me.dependency["presets"].getChild("heading-deg").setValue(headingdeg);

    # forces the computation of ground
        me.dependency["presets"].getChild("altitude-ft").setValue(-9999);

        me.dependency["presets"].getChild("airspeed-kt").setValue(0);

    # disable runway
        me.dependency["presets"].getChild("airport-id").setValue("");
    }
}

Mooring.findterminal = func( index, moorage ) {
    var found = constant.FALSE;
    var terminalname = "not known";
    var result = -1;
    var child = nil;

    var location = me.itself["seaplane"][index].getChildren("location");

    for( var i=0; i<size(location); i=i+1) {
         child = location[ i ].getChild("terminal");

         if( child != nil ) {
             if( child.getValue() ) {
                 result = i;
                 
                 child = location[ i ].getChild("name");
                 if( child != nil ) {
                     terminalname = child.getValue();
                 }
                 
                 found = constant.TRUE;
                 print( "314 : ", terminalname, " is terminal at ", moorage );
                 break;
             }
        }
    }

    me.itself["root"].getChild("terminal").setValue( terminalname );
    me.itself["root"].getChild("terminal-real").setValue( found );

    return result;
}

Mooring.findmoorage = func( index, landing, winddeg ) {
    var result = -1;

    if( me.itself["root-ctrl"].getNode("wind").getChild("head").getValue() or landing ) {
        # boat waiting at the landing end
        if( landing ) {
            winddeg = winddeg + constant.DEG180;
            winddeg = constant.truncatenorth( winddeg );
        }
    }
    else {
        winddeg = me.itself["root-ctrl"].getChild("heading-deg").getValue();
    }

    # best mooring according to the wind
    var crosswinddeg = constant.DEG360;
    var mooragedeg = 0;
    var offsetdeg = 0.0;

    var location = me.itself["seaplane"][index].getChildren("location");

    for( var i=0; i<size(location); i=i+1) {
         mooragedeg = location[ i ].getChild("heading-deg").getValue();
         offsetdeg = constant.crosswinddeg( winddeg, mooragedeg );

         if ( offsetdeg < crosswinddeg ) {
              crosswinddeg = offsetdeg;
              result = i;
         }
    }

    return result;
}

Mooring.towerchange = func {
   var change = constant.FALSE;
   var windchange = constant.FALSE;
   var descent = constant.FALSE;
   var index = -1;
   var tower = me.takeoffboat.gettower();
   var distancemeter = 0.0;
   var nearestmeter = me.EARTHKM * constant.KMTOMETER;
   var destination = geo.Coord.new();
   var flight = geo.aircraft_position();


   # search for the nearest moorage
   for(var i=0; i<size(me.itself["seaplane"]); i=i+1) {
      var location = me.itself["seaplane"][i].getChildren("location");

      if( size(location) > 0 ) {
          destination.set_latlon( location[0].getChild("latitude-deg").getValue(),
                                  location[0].getChild("longitude-deg").getValue() );
          distancemeter = flight.distance_to( destination ); 
          if( distancemeter < nearestmeter ) {
              tower = me.itself["seaplane"][ i ].getChild("airport-id").getValue();
              nearestmeter = distancemeter;
              index = i;
          }
      }
   }


   # tower change
   change = me.takeoffboat.towerchange( tower );

   # only within vicinity
   if( nearestmeter < me.PORTNM * constant.NMTOMETER ) {
       # wind at location is changing during descent
       if( me.noinstrument["agl"].getValue() < me.APPROACHFT and
           me.noinstrument["vertical"].getValue() < me.DESCENTFTPS ) {
           descent = constant.TRUE;
       }
   }


   # wind coherent for both views
   var winddeg = me.noinstrument["wind"].getValue();

   if( me.lastwinddeg != me.UNKNOWNDEG ) {
       if( !me.is_moving() ) {
           var crosswinddeg = constant.crosswinddeg( winddeg, me.lastwinddeg );

           if( crosswinddeg > constant.DEG10 or crosswinddeg < - constant.DEG10 ) {
               me.lastwinddeg = winddeg;
               windchange = constant.TRUE;
           }
       }
   }
   else {
       me.lastwinddeg = winddeg;
       windchange = constant.TRUE;
   }


   # log change
   if( descent and descent != me.mooringlanding ) {
       print( "314 : landing at ", tower );
   }
   elsif( change ) {
       print( "314 : setting boat near ", tower );
   }
   elsif( windchange ) {
       print( "314 : wind change at ", tower );
   }

   me.mooringlanding = descent;


   if( change or descent or windchange ) {
       var index1 = me.findterminal( index, tower );
       
       var index2 = me.findmoorage( index, constant.FALSE, me.lastwinddeg );
       
       # also default dock, if no terminal
       if( index1 < 0 ) {
           index1 = index2;
       }

       me.dock.setmoorage( index, index1 );

       me.takeoffboat.setmoorage( index, index2, tower );

       # boat waiting at the landing end
       var index3 = me.findmoorage( index, constant.TRUE, me.lastwinddeg );

       me.landingboat.setmoorage( index, index3, tower );
   }
}

# change of airport
Mooring.presetairport = func {
   var airport = me.dependency["presets"].getChild("airport-id").getValue();

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
   if( me.dependency["scenery"].getValue() ) {
       settimer(func{ me.presetharbour(); },me.HARBOURSEC);
   }

   # wait for end of initialization
   else {
       settimer(func{ me.presetseaplane(); },me.HARBOURSEC);
   }
}

# goes to the harbour, once one has the tower
Mooring.presetharbour = func {
   if( me.itself["root-ctrl"].getChild("automatic").getValue() ) {
       var found = constant.FALSE;
       var search = constant.FALSE;
       var airport = me.dependency["presets"].getChild("airport-id").getValue();

       if( airport != nil and airport != "" ) {
           search = constant.TRUE;
           print( "314 : searching for a moorage near ", airport );

           for( var i=0; i<size(me.itself["seaplane"]); i=i+1 ) {
                var harbour = me.itself["seaplane"][ i ].getChild("airport-id").getValue();

                if( harbour == airport ) {
                    me.setmoorage( i, airport );

                    fgcommand("presets-commit", props.Node.new());

                    # presets cuts the engines
                    var eng = me.dependency["engines"];
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

       if( !found ) {
           me.seaportexport();
           if ( search ) {
                print( "314 : no moorage found" );
           }
       }
   }

   else {
       me.seaportexport();
   }
}


# ========
# FLOATING
# ========

Floating = {};

Floating.new = func {
   var obj = { parents : [Floating,System],

               mooringlocation : -1,
               mooringdirection : -1,

               BOATDEG : 0.0003,

               SEAFT : 0   
             };

   obj.init();

   return obj;
};

Floating.init = func {
}

Floating.inherit_floating = func {
   # child will also have to inherit from System
   me.inherit_system("/systems/mooring");

   var obj = Floating.new();

   me.BOATDEG = obj.BOATDEG;
   me.SEAFT = obj.SEAFT;

   me.mooringlocation = obj.mooringlocation;
   me.mooringdirection = obj.mooringdirection;
}


# ====
# BOAT
# ====

Boat = {};

Boat.new = func {
   var obj = { parents : [Boat,Floating,System],

               mooringtower : "",
               mooringindex : 0,

               BOATFT : 10                                            # crew in a boat
             };

   obj.init();

   return obj;
};

Boat.init = func {
   me.inherit_floating();
}

Boat.inherit_boat = func {
   # child will also have to inherit from System
   me.inherit_system("/systems/mooring");

   var obj = Boat.new();

   me.BOATFT = obj.BOATFT;

   me.mooringtower = obj.mooringtower;
   me.mooringindex = obj.mooringindex;
}

Boat.getdirection = func {
   return me.mooringdirection;
}

Boat.gettower = func {
   return me.mooringtower;
}

Boat.has_tower = func {
   var result = constant.FALSE;

   if( me.mooringtower != "" ) {
       result = constant.TRUE;
   }

   return result;
}

Boat.towerchange = func( tower ) {
   var result = constant.FALSE;

   if( me.mooringtower != tower ) {
       result = constant.TRUE;
   }

   return result;
}

Boat.restore = func {
   if( me.has_tower() ) {
       me.setmoorage( me.mooringlocation, me.mooringdirection, me.mooringtower );
   }
}

Boat.moorage = func( index, index2, tower ) {
   if( index >= 0 and index2 >= 0 ) {
       var location = me.itself["seaplane"][ index ].getChildren("location");

       # backup for restore
       me.mooringlocation = index;
       me.mooringdirection = index2;
       me.mooringtower = tower;

       var latitudedeg = location[ index2 ].getChild("latitude-deg").getValue();
       var longitudedeg = location[ index2 ].getChild("longitude-deg").getValue();
       var headingdeg = location[ index2 ].getChild("heading-deg").getValue();

       me.setposition( latitudedeg, longitudedeg, headingdeg, tower );

       me.setaltitude( index, geo.elevation( latitudedeg, longitudedeg ) );
   }

   else {
       me.clear();
   }
}

Boat.setmoorage = func( index, index2, tower ) {
   me.moorage( index, index2, tower );
}

Boat.clear = func {
   me.mooringlocation = -1;
   me.mooringdirection = -1;
   me.mooringtower = "";
}

Boat.setposition = func( latitudedeg, longitudedeg, headingdeg, airport ) {
   # behind to the right of the hull
   latitudedeg = latitudedeg - me.BOATDEG * math.cos( headingdeg * constant.DEGTORAD );
   longitudedeg = longitudedeg - me.BOATDEG * math.sin( headingdeg * constant.DEGTORAD );

   me.dependency["boat"][me.mooringindex].getChild("latitude-deg").setValue( latitudedeg );
   me.dependency["boat"][me.mooringindex].getChild("longitude-deg").setValue( longitudedeg );

   me.itself["root"].getChild("boat-id").setValue(airport);
}

Boat.setaltitude = func( index, altitudemeter ) {
   if( index >= 0 ) {
       # sea level, by default
       var altitudeft = me.SEAFT;

       # geo may returns nil
       if( altitudemeter != nil ) {
           altitudeft = altitudemeter * constant.METERTOFEET;
       }

       me.setheight( altitudeft );
   }
}

Boat.setheight = func( altitudeft ) {
   var modelft = altitudeft + me.dependency["boat"][me.mooringindex].getChild("offset-ft").getValue();
   me.dependency["boat"][me.mooringindex].getChild("water-ft").setValue( modelft );

   altitudeft = altitudeft + me.BOATFT;
   me.dependency["boat"][me.mooringindex].getChild("altitude-ft").setValue( altitudeft );

}


# ============
# LANDING BOAT
# ============

LandingBoat = {};

LandingBoat.new = func {
   var obj = { parents : [LandingBoat,Boat,Floating,System],

               takeoffboat : nil,

               BOATMETER : 50                                         # minimal distance between both boats
             };

   obj.init();

   return obj;
};

LandingBoat.init = func {
   me.inherit_floating();
   me.inherit_boat();

   me.mooringindex = 1;
}

LandingBoat.set_relation = func( boat ) {
   me.takeoffboat = boat;
}

LandingBoat.restore = func {
   if( me.has_tower() ) {
       me.setmoorage( me.mooringlocation, me.mooringdirection, me.mooringtower );
   }
}

LandingBoat.mooragefrom = func( index, index2, tower ) {
   var direction = me.takeoffboat.getdirection();

   # if same moorage, 2nd boat is over 1st boat (smaller buoy)
   if( direction == index2 ) {
   }

   elsif( index >= 0 and index2 >= 0 ) {
       var location = me.itself["seaplane"][ index ].getChildren("location");

       var boat = geo.Coord.new();
       var boat2 = geo.Coord.new();

       boat.set_latlon( location[ direction ].getChild("latitude-deg").getValue(),
                        location[ direction ].getChild("longitude-deg").getValue() );
       boat2.set_latlon( location[ index2 ].getChild("latitude-deg").getValue(),
                         location[ index2 ].getChild("longitude-deg").getValue() );

        # if moorage too close, 2nd boat is over 1st boat (smaller buoy)
        if( boat.distance_to( boat2 ) < me.BOATMETER ) {
            index2 = direction;
        }
   }

   return index2;
}

LandingBoat.setmoorage = func( index, index2, tower ) {
   index2 = me.mooragefrom( index, index2, tower );

   me.moorage( index, index2, tower );
}


# ====
# DOCK
# ====

Dock = {};

Dock.new = func {
   var obj = { parents : [Dock,Floating,System],

               DOCKFT : 8                                             # walk on a dock
             };

   obj.init();

   return obj;
};

Dock.init = func {
   me.inherit_floating();
}

Dock.restore = func {
   if( me.mooringlocation != -1 ) {
       me.setmoorage( me.mooringlocation, me.mooringdirection );
   }
}

Dock.setmoorage = func( index, index2 ) {
   if( index >= 0 and index2 >= 0 ) {
       var location = me.itself["seaplane"][ index ].getChildren("location");

       # backup for restore
       me.mooringlocation = index;
       me.mooringdirection = index2;

       var latitudedeg = location[ index2 ].getChild("latitude-deg").getValue();
       var longitudedeg = location[ index2 ].getChild("longitude-deg").getValue();
       var headingdeg = location[ index2 ].getChild("heading-deg").getValue();

       me.setposition( latitudedeg, longitudedeg, headingdeg );

       me.setaltitude( index, geo.elevation( latitudedeg, longitudedeg ) );
   }
}

Dock.setposition = func( latitudedeg, longitudedeg, headingdeg ) {
   # behind to the right of the hull
   latitudedeg = latitudedeg - 2 * me.BOATDEG * math.cos( headingdeg * constant.DEGTORAD );
   longitudedeg = longitudedeg - 2 * me.BOATDEG * math.sin( headingdeg * constant.DEGTORAD );

   me.dependency["dock"].getChild("latitude-deg").setValue( latitudedeg );
   me.dependency["dock"].getChild("longitude-deg").setValue( longitudedeg );
   me.dependency["dock"].getChild("heading-deg").setValue( headingdeg );
}

Dock.setaltitude = func( index, altitudemeter ) {
   if( index >= 0 ) {
       # sea level, by default
       var altitudeft = me.SEAFT;

       # geo may returns nil
       if( altitudemeter != nil ) {
           altitudeft = altitudemeter * constant.METERTOFEET;
       }

       me.setheight( altitudeft );
   }
}

Dock.setheight = func( altitudeft ) {
   var modelft = altitudeft + me.dependency["dock"].getChild("offset-ft").getValue();
   me.dependency["dock"].getChild("water-ft").setValue( modelft );

   altitudeft = altitudeft + me.DOCKFT;
   me.dependency["dock"].getChild("altitude-ft").setValue( altitudeft );
}


# ======
# ANCHOR
# ======

Anchor = {};

Anchor.new = func {
   var obj = { parents : [Anchor,System]
             };

   obj.init();

   return obj;
};

Anchor.init = func {
   me.inherit_system("/systems/mooring");

   var park = me.dependency["rope"].getValue();

   # external reaction
   me.itself["root-ctrl"].getChild("anchor").setValue( park );
}

Anchor.allowedexport = func {
    var result = constant.FALSE;

    # airspeed may be greater than 15 kt at rest.
    if( !me.is_moving() ) {
        result = constant.TRUE;
    }

    return result;
}

Anchor.cut =func {
   if( me.is_moving() ) {
       if( me.dependency["rope"].getValue() ) {
           controls.applyParkingBrake(1);
       }
   }
}
