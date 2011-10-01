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

               presets : nil,

               mooringtower : [ "", "" ],
               mooringlocation : [ -1, -1 ],
               mooringdirection : [ -1, -1 ],
               mooringlanding : constant.FALSE,

               BOATSEC : 60.0,
               MOORINGSEC : 5.0,
               AIRPORTSEC : 3.0,
               HARBOURSEC : 2.0,

               BOATDEG : 0.0003,

               APPROACHFT : 3000,
               BOATFT : 10,                                            # crew in a boat
               SEAFT : 0,

               EARTHKM : 20000,                                        # largest distance between 2 points on earth surface
               PORTNM : 100,                                           # distance when the boat moves
               BOATMETER : 50,                                         # minimal distance between both boats
           
               DESCENTFTPS : -1.67                                     # 100 ft/min
         };

   obj.init();

   return obj;
};

Mooring.init = func {
   me.inherit_system("/systems/mooring");

   me.presets = props.globals.getNode("/sim/presets");

   me.presetseaplane();
}

Mooring.set_relation = func( copilot ) {
   me.copilotcrew = copilot;
}

Mooring.allowedexport = func {
   return me.anchor.allowedexport();
}

Mooring.seaportexport = func {
   if( me.itself["root-ctrl"].getChild("seaport").getValue() ) {
       me.enableseaport();
   }
   else {
       me.disableseaport();
   }
}

Mooring.schedule = func {
   me.anchor.cut();

   # work around for 2.4.0 : properties may be reset.
   if( me.itself["root"].getChild("boat-id").getValue() == "" ) {
       for(var i=0; i<2; i=i+1) {
           if( me.mooringtower[i] != "" ) {
               me.setboatmoorage( me.mooringlocation[i], me.mooringdirection[i], i, me.mooringtower[i] );
           }
       }
   }
}

Mooring.slowschedule = func {
   me.towerchange();
}

Mooring.dialogexport = func {
   var dialog = me.itself["root"].getChild("dialog").getValue();
   
   # KSFO  Treasure Island ==> KSFO
   var idcomment = split( " ", dialog );
   var moorage = idcomment[0];

   for(var i=0; i<size(me.itself["seaplane"]); i=i+1) {
       var harbour = me.itself["seaplane"][ i ].getChild("airport-id").getValue();

       if( harbour == moorage ) {
           me.setmoorage( i, moorage );

           break;
       }
   }
}

Mooring.setmoorage = func( index, moorage ) {
    var latitudedeg = 0.0;
    var longitudedeg = 0.0;
    var headingdeg = constant.DEG0;


    # automatic mooring is not compatible with seaport dialog
    me.disableseaport();


    # best mooring according to the wind
    var index2 = me.findmoorage( index, constant.FALSE );
    if( index2 >= 0 ) {
        var location = me.itself["seaplane"][index].getChildren("location");

        latitudedeg = location[ index2 ].getChild("latitude-deg").getValue();
        longitudedeg = location[ index2 ].getChild("longitude-deg").getValue();
        headingdeg = location[ index2 ].getChild("heading-deg").getValue();
    }

    me.setboatmoorage( index, index2, 0, moorage );


    # boat waiting at the landing end
    var index3 = me.findmoorage( index, constant.TRUE );

    me.setboatmoorage( index, index3, 1, moorage );


    # apply
    me.presets.getChild("latitude-deg").setValue(latitudedeg);
    me.presets.getChild("longitude-deg").setValue(longitudedeg);
    me.presets.getChild("heading-deg").setValue(headingdeg);

    # forces the computation of ground
    me.presets.getChild("altitude-ft").setValue(-9999);

    me.presets.getChild("airspeed-kt").setValue(0);


    # copilot feedback
    var winddeg = me.noinstrument["wind"].getValue();
    var crosswinddeg = constant.crosswinddeg( winddeg, headingdeg );
    me.copilotcrew.crosswindexport( crosswinddeg );
}

Mooring.findmoorage = func( index, landing ) {
    var result = -1;
    var mooragedeg = 0;
    var winddeg = 0.0;
    var offsetdeg = 0.0;

    var crosswinddeg = constant.DEG360;

    var location = me.itself["seaplane"][index].getChildren("location");

    if( me.itself["root-ctrl"].getChild("wind").getValue() or landing ) {
        winddeg = me.noinstrument["wind"].getValue();

        # boat waiting at the landing end
        if( landing ) {
            winddeg = winddeg + constant.DEG180;
            if( winddeg > constant.DEG360 ) {
                winddeg = winddeg - constant.DEG360;
            }
        }
    }
    else {
        winddeg = me.itself["root-ctrl"].getChild("heading-deg").getValue();
    }

    # best mooring according to the wind
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

Mooring.setboatmoorage = func( index, index2, index3, tower ) {
   if( index3 == 1 ) {
       # if same moorage, 2nd boat is over 1st boat (smaller buoy)
       if( me.mooringdirection[0] == index2 ) {
       }

       elsif( index >= 0 and index2 >= 0 ) {
           var location = me.itself["seaplane"][ index ].getChildren("location");

           var boat = geo.Coord.new();
           var boat2 = geo.Coord.new();

           boat.set_latlon( location[ me.mooringdirection[0] ].getChild("latitude-deg").getValue(),
                            location[ me.mooringdirection[0] ].getChild("longitude-deg").getValue() );
           boat2.set_latlon( location[ index2 ].getChild("latitude-deg").getValue(),
                             location[ index2 ].getChild("longitude-deg").getValue() );

           # if moorage too close, 2nd boat is over 1st boat (smaller buoy)
           if( boat.distance_to( boat2 ) < me.BOATMETER ) {
               index2 = me.mooringdirection[0];
           }
       }
   }

   if( index >= 0 and index2 >= 0 ) {
       var location = me.itself["seaplane"][ index ].getChildren("location");

       # backup for restore
       me.mooringlocation[index3] = index;
       me.mooringdirection[index3] = index2;
       me.mooringtower[index3] = tower;

       var latitudedeg = location[ index2 ].getChild("latitude-deg").getValue();
       var longitudedeg = location[ index2 ].getChild("longitude-deg").getValue();
       var headingdeg = location[ index2 ].getChild("heading-deg").getValue();

       me.setboatposition( index3, latitudedeg, longitudedeg, headingdeg, tower );

       me.setboataltitude( index, index3, geo.elevation( latitudedeg, longitudedeg ) );
   }

   else {
       # clear
       me.mooringlocation[index3] = -1;
       me.mooringdirection[index3] = -1;
       me.mooringtower[index3] = "";
   }
}

Mooring.setboatposition = func( index, latitudedeg, longitudedeg, headingdeg, airport ) {
   # behind to the right of the hull
   latitudedeg = latitudedeg - me.BOATDEG * math.cos( headingdeg * constant.DEGTORAD );
   longitudedeg = longitudedeg - me.BOATDEG * math.sin( headingdeg * constant.DEGTORAD );

   me.dependency["boat"][index].getChild("latitude-deg").setValue( latitudedeg );
   me.dependency["boat"][index].getChild("longitude-deg").setValue( longitudedeg );

   me.itself["root"].getChild("boat-id").setValue(airport);
}

Mooring.setboataltitude = func( index, index2, altitudemeter ) {
   if( index >= 0 ) {
       # sea level, by default
       var altitudeft = me.SEAFT;

       # geo may returns nil
       if( altitudemeter != nil ) {
           altitudeft = altitudemeter * constant.METERTOFEET;
       }

       me.setboatheight( index2, altitudeft );
   }
}

Mooring.setboatheight = func( index, altitudeft ) {
   var modelft = altitudeft + me.dependency["boat"][index].getChild("offset-ft").getValue();
   me.dependency["boat"][index].getChild("water-ft").setValue( modelft );

   altitudeft = altitudeft + me.BOATFT;
   me.dependency["boat"][index].getChild("altitude-ft").setValue( altitudeft );

}

Mooring.towerchange = func {
   var change = constant.FALSE;
   var descent = constant.FALSE;
   var index = -1;
   var tower = me.mooringtower[0];
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
   if( tower != me.mooringtower[0] ) {
       change = constant.TRUE;
   }

   # only within vicinity
   if( nearestmeter < me.PORTNM * constant.NMTOMETER ) {
       # wind at location is changing during descent
       if( me.noinstrument["agl"].getValue() < me.APPROACHFT and
           me.noinstrument["vertical"].getValue() < me.DESCENTFTPS ) {
           descent = constant.TRUE;
       }
   }


   # log change
   if( descent and descent != me.mooringlanding ) {
       print( "314 : setting boat for landing near ", tower );
   }
   elsif( change ) {
       print( "314 : setting boat near ", tower );
   }

   me.mooringlanding = descent;


   if( change or descent ) {
       var index2 = me.findmoorage( index, constant.FALSE );

       me.setboatmoorage( index, index2, 0, tower );

       # boat waiting at the landing end
       var index3 = me.findmoorage( index, constant.TRUE );

       me.setboatmoorage( index, index3, 1, tower );
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
   if( me.itself["root-ctrl"].getChild("automatic").getValue() ) {
       var found = constant.FALSE;
       var airport = me.presets.getChild("airport-id").getValue();

       if( airport != nil and airport != "" ) {
           print( "314 : searching for a moorage near ", airport );

           for( var i=0; i<size(me.itself["seaplane"]); i=i+1 ) {
                var harbour = me.itself["seaplane"][ i ].getChild("airport-id").getValue();

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

       if( !found ) {
           me.seaportexport();
           print( "314 : no moorage found" );
       }
   }

   else {
       me.seaportexport();
   }
}

Mooring.enableseaport = func {
   me.dependency["seaport"].setValue("seaplane");
}

Mooring.disableseaport = func {
   me.dependency["seaport"].setValue("");
}


# ======
# ANCHOR
# ======

Anchor = {};

Anchor.new = func {
   var obj = { parents : [Anchor,System],

               SPEEDFPS : 25
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
    if( me.noinstrument["velocity"].getValue() < me.SPEEDFPS ) {
        result = constant.TRUE;
    }

    return result;
}

Anchor.cut =func {
   if( me.noinstrument["velocity"].getValue() >= me.SPEEDFPS ) {
       if( me.dependency["rope"].getValue() ) {
           controls.applyParkingBrake(1);
       }
   }
}
