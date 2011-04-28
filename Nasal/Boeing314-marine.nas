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

               MOORINGSEC : 5.0,
               AIRPORTSEC : 3.0,
               HARBOURSEC : 2.0,

               BOATDEG : 0.0003,

               APPROACHFT : 3000,
               BOATFT : 10,                                            # crew in a boat
               SEAFT : 0,
           
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

Mooring.schedule = func {
   me.towerchange();
   me.anchor.cut();
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

           me.dependency["tower"].setValue(moorage);
           break;
       }
   }
}

Mooring.setmoorage = func( index, moorage ) {
    var latitudedeg = 0.0;
    var longitudedeg = 0.0;
    var headingdeg = constant.DEG0;


    # best mooring according to the wind
    var index2 = me.findmoorage( index, constant.FALSE );
    if( index2 >= 0 ) {
        var location = me.itself["seaplane"][index].getChildren("location");

        latitudedeg = location[ index2 ].getChild("latitude-deg").getValue();
        longitudedeg = location[ index2 ].getChild("longitude-deg").getValue();
        headingdeg = location[ index2 ].getChild("heading-deg").getValue();
    }

    me.setboatmoorage( index, index2, moorage );


    # apply
    me.presets.getChild("latitude-deg").setValue(latitudedeg);
    me.presets.getChild("longitude-deg").setValue(longitudedeg);
    me.presets.getChild("heading-deg").setValue(headingdeg);

    # forces the computation of ground
    me.presets.getChild("altitude-ft").setValue(-9999);

    me.presets.getChild("airspeed-kt").setValue(0);

    me.setadf( index, moorage );


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

Mooring.setadf = func( index, beacon ) {
   if( me.itself["root-ctrl"].getChild("tower-adf").getValue() ) {
       var frequency = 0.0;
       var adf = me.itself["seaplane"][ index ].getNode("adf");

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
}

Mooring.setboatmoorage = func( index, index2, tower ) {
   if( index >= 0 ) {
       var location = me.itself["seaplane"][ index ].getChildren("location");

       var latitudedeg = location[ index2 ].getChild("latitude-deg").getValue();
       var longitudedeg = location[ index2 ].getChild("longitude-deg").getValue();
       var headingdeg = location[ index2 ].getChild("heading-deg").getValue();

       me.setboatposition( latitudedeg, longitudedeg, headingdeg, tower );

       me.setboataltitude( index );
   }
}

Mooring.setboatposition = func( latitudedeg, longitudedeg, headingdeg, airport ) {
   # behind to the right of the hull
   latitudedeg = latitudedeg - me.BOATDEG * math.cos( headingdeg * constant.DEGTORAD );
   longitudedeg = longitudedeg - me.BOATDEG * math.sin( headingdeg * constant.DEGTORAD );

   me.dependency["boat"].getChild("latitude-deg").setValue( latitudedeg );
   me.dependency["boat"].getChild("longitude-deg").setValue( longitudedeg );

   me.itself["root"].getChild("boat-id").setValue(airport);
}

Mooring.setboataltitude = func( index ) {
   if( index >= 0 ) {
       # sea level, by default
       var altitudeft = me.SEAFT;

       # lake or river
       if( me.itself["seaplane"][ index ].getNode("water-ft") != nil ) {
           altitudeft = me.itself["seaplane"][ index ].getChild("water-ft").getValue();
       }

       me.setboatheight( altitudeft );
   }
}

Mooring.setboatheight = func( altitudeft ) {
   var modelft = altitudeft + me.dependency["boat"].getChild("offset-ft").getValue();
   me.dependency["boat"].getChild("water-ft").setValue( modelft );

   altitudeft = altitudeft + me.BOATFT;
   me.dependency["boat"].getChild("altitude-ft").setValue( altitudeft );

}

# tower changed by dialog (destination or airport location)
Mooring.towerchange = func {
   var change = constant.FALSE;
   var descent = constant.FALSE;
   var tower = me.dependency["tower"].getValue();


   if( tower != me.itself["root"].getChild("boat-id").getValue() ) {
       change = constant.TRUE;
   }

   elsif( me.noinstrument["agl"].getValue() < me.APPROACHFT and
          me.noinstrument["vertical"].getValue() < me.DESCENTFTPS ) {
       descent = constant.TRUE;
   }


   if( change or descent ) {
       for(var i=0; i<size(me.itself["seaplane"]); i=i+1) {
           var harbour = me.itself["seaplane"][ i ].getChild("airport-id").getValue();
           if( harbour == tower ) {
               # wind at location is changing
               var index = me.findmoorage( i, constant.TRUE );

               # boat waiting at the landing end
               me.setboatmoorage( i, index, tower );

               if( change ) {
                   me.setadf( i, tower );
               }

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
   if( me.itself["root-ctrl"].getChild("automatic").getValue() ) {
       var found = constant.FALSE;
       var airport = me.presets.getChild("airport-id").getValue();

       if( airport != nil and airport != "" ) {
           print( "searching for a moorage near ", airport );

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
           print( "no moorage found" );
       }
   }
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
