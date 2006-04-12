# IMPORTANT : always uses /consumables/fuel/tank[0]/level-gal_us, because /level-lb seems not synchronized with
# level-gal_us, during the time of a procedure.

# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =========
# CONSTANTS
# =========

Constant = {};

Constant.new = func {
   obj = { parents : [Constant],

           HOURTOSECOND : 3600.0,
           MINUTETOSECOND : 60.0,
         };

   return obj;
};


# ===========
# FUEL SYSTEM
# ===========

Fuel = {};

Fuel.new = func {
   obj = { parents : [Fuel],
           SPEEDUPSEC : 2,             # refresh rate
           CLIMBFTPMIN : 1000,         # average climb rate
           CLIMBFTPSEC : 0.0,
           MAXSTEPFT : 0.0
         };

   obj.init();

   return obj;
};

Fuel.init = func {
   me.CLIMBFTPSEC = me.CLIMBFTPMIN / constant.MINUTETOSECOND;
   me.MAXSTEPFT = me.CLIMBFTPSEC * me.SPEEDUPSEC;

   me.presetfuel();
}

# fuel configuration
Fuel.presetfuel = func {
   # default is 0
   fuel = getprop("/sim/presets/fuel");
   if( fuel == nil ) {
       fuel = 0;
   }
   fillings = props.globals.getNode("/sim/presets/tanks").getChildren("filling");
   if( fuel < 0 or fuel >= size(fillings) ) {
       fuel = 0;
   } 
   presets = fillings[fuel].getChildren("tank");
   tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
   for( i=0; i < size(presets); i=i+1 ) {
        child = presets[i].getChild("level-gal_us");
        if( child != nil ) {
            level = child.getValue();
            tanks[i].getChild("level-gal_us").setValue(level);
        }
   } 
}

# speed up engine, arguments :
# - engine tank
# - fuel flow of engine
# - sponson tank
# - speed up
Fuel.speedupengine = func {
   enginetank = arg[0];
   flowgph = arg[1];
   sponsontank = arg[2];
   multiplier = arg[3];

   if( flowgph == nil ) {
       flowgph = 0;
   }

   # fuel consumed during the time step
   if( flowgph > 0 ) {
       multiplier = multiplier - 1;
       enginegal = flowgph * multiplier;
       enginegal = enginegal / constant.HOURTOSECOND;
       enginegal = enginegal * me.SPEEDUPSEC;

       tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");

       # center tank first
       tankgal = tanks[4].getValue("level-gal_us");
       if( tankgal > 0 ) {
           if( tankgal > enginegal ) {
               tankgal = tankgal - enginegal;
               enginegal = 0;
           }
           else {
               enginegal = enginegal - tankgal;
               tankgal = 0;
           }
           tanks[4].getChild("level-gal_us").setValue(tankgal);
       } 

       # then sponson tank
       if( enginegal > 0 ) {
           tankgal = tanks[sponsontank].getValue("level-gal_us");
           if( tankgal > 0 ) {
               if( tankgal > enginegal ) {
                   tankgal = tankgal - enginegal;
                   enginegal = 0;
               }
               else {
                   enginegal = enginegal - tankgal;
                   tankgal = 0;
               }
               tanks[sponsontank].getChild("level-gal_us").setValue(tankgal);
           }
       } 

       # engine tank at last
       if( enginegal > 0 ) {
           tankgal = tanks[enginetank].getValue("level-gal_us");
           if( tankgal > 0 ) {
               if( tankgal > enginegal ) {
                   tankgal = tankgal - enginegal;
                   enginegal = 0;
               }
               else {
                   enginegal = enginegal - tankgal;
                   tankgal = 0;
               }
               tanks[enginetank].getChild("level-gal_us").setValue(tankgal);
           }
       } 
   }
}

# speed up consumption
Fuel.schedule = func {
   altitudeft = getprop("/position/altitude-ft");
   speedup = getprop("/sim/speed-up");
   if( speedup > 1 ) {
       engines = props.globals.getNode("/engines/").getChildren("engine");
       galphour = engines[0].getValue("fuel-flow-gph");
       me.speedupengine( 0, galphour, 5, speedup );
       galphour = engines[1].getValue("fuel-flow-gph");
       me.speedupengine( 1, galphour, 5, speedup );
       galphour = engines[2].getValue("fuel-flow-gph");
       me.speedupengine( 2, galphour, 6, speedup );
       galphour = engines[3].getValue("fuel-flow-gph");
       me.speedupengine( 3, galphour, 6, speedup );

       # accelerate day time
       node = props.globals.getNode("/sim/time/warp");
       multiplier = speedup - 1;
       offsetsec = me.SPEEDUPSEC * multiplier;
       warp = node.getValue() + offsetsec; 
       node.setValue(warp);

       # safety
       lastft = getprop("/position/speed-up-ft");
       if( lastft != nil ) {
           stepft = me.MAXSTEPFT * speedup;
           maxft = lastft + stepft;
           minft = lastft - stepft;

           # too fast
           if( altitudeft > maxft or altitudeft < minft ) {
               setprop("/sim/speed-up",1);
           }
       }
   }

   setprop("/position/speed-up-ft",altitudeft);
}


# ========================
# GROUND DIRECTION FINDING
# ========================

GDF = {};

GDF.new = func {
   obj = { parents : [GDF]
         };
   return obj;
};

# cannot make a settimer on a class member
callgdfcron = func {
   GDFinstrument.call();
}

GDF.call = func {
   if( getprop("/instrumentation/gdf/called") == "on" ) {
       if( getprop("/instrumentation/gdf/calling") != "on" ) {
           setprop("/instrumentation/gdf/calling","on");
           speedup = getprop("/sim/speed-up");
           delaysec = 120.0 / speedup;

           # schedule the next call
           settimer(callgdfcron,delaysec);
       }
       else {
           waypoints = props.globals.getNode("/autopilot/route-manager").getChildren("wp");
           id = waypoints[0].getChild("id").getValue();
           if( id != nil ) {
               # magnetic heading for gyro (Sperry)
               bearingdeg = getprop("/autopilot/settings/true-heading-deg");
               magdeg = getprop("/environment/magnetic-variation-deg");
               bearingdeg = bearingdeg - magdeg;

               # north crossing
               if( bearingdeg < 0 ) {
                   bearingdeg = 360 + bearingdeg;
               }
               elsif( bearingdeg > 360 ) {
                   bearingdeg = bearingdeg - 360;
               }

               setprop("/instrumentation/gdf/heading-deg",bearingdeg);
               reception = getprop("/sim/time/gmt-string");
               setprop("/instrumentation/gdf/gmt-string",reception);
               setprop("/instrumentation/gdf/show-paper","on");
           }
           setprop("/instrumentation/gdf/called","");
           setprop("/instrumentation/gdf/calling","");
       }
   }
}


# ================
# SPERRY AUTOPILOT
# ================

Autopilot = {};

Autopilot.new = func {
   obj = { parents : [Autopilot]
         };
   return obj;
};

# pitch hold
Autopilot.appitchexport = func {
    mode = getprop("/autopilot/locks/altitude");
    if( mode != "pitch-hold" ) {
        mode = "pitch-hold";
        pitchdeg = getprop("/orientation/pitch-deg");
        setprop("/autopilot/settings/target-pitch-deg",pitchdeg);
    }
    else {
        mode = "";
    }

    setprop("/autopilot/locks/altitude",mode);
}

# heading hold
Autopilot.apheadingexport = func {
    mode = getprop("/autopilot/locks/heading");
    if( mode != "dg-heading-hold" ) {
        mode = "dg-heading-hold";
        headingdeg = getprop("/orientation/heading-magnetic-deg");
        setprop("/autopilot/settings/heading-bug-deg",headingdeg);
        mode2 = "horizontal";
    }
    else {
        mode = "";
        mode2 = "";
    }

    setprop("/autopilot/locks/heading",mode);
    setprop("/autopilot/locks/heading2",mode2);
}

# altitude hold
Autopilot.apaltitudeexport = func {
    mode = getprop("/autopilot/locks/altitude");
    if( mode != "altitude-hold" ) {
        mode = "altitude-hold";
        altitudeft = getprop("/instrumentation/altimeter/indicated-altitude-ft");
        setprop("/autopilot/settings/target-altitude-ft",altitudeft);
    }
    else {
        mode = "";
    }

    setprop("/autopilot/locks/altitude",mode);
}

# pitch horizon :
# - coefficient 
Autopilot.pitchexport = func {
    sign = arg[ 0 ];

    pitchdeg = getprop("/autopilot/settings/target-pitch-deg");
    if( pitchdeg == nil ) {
        pitchdeg = 0.0;
    }

    pitchdeg = pitchdeg + 0.15 * sign;
    if( pitchdeg > 12 ) {
        pitchdeg = 12;
    }
    elsif( pitchdeg < -12 ) {
          pitchdeg = -12;
    }
    setprop("/autopilot/settings/target-pitch-deg",pitchdeg);
}

# heading bug :
# - sign
Autopilot.headingexport = func {
    sign = arg[ 0 ];

    headingdeg = getprop("/autopilot/settings/heading-bug-deg");
    if( headingdeg == nil ) {
        headingdeg = 0.0;
    }

    headingdeg = headingdeg + 1 * sign;
    if( headingdeg > 360 ) {
        headingdeg = 1;
    }
    elsif( headingdeg < 0 ) {
          headingdeg = 359;
    }
    setprop("/autopilot/settings/heading-bug-deg",headingdeg);
}

# auto throttle
Autopilot.atexport = func{
   speed = getprop("/autopilot/locks/speed");
   if( speed == "speed-with-throttle-arm" or speed == "speed-with-throttle" ) {
       speed = "";
   }
   else {
       speed = "speed-with-throttle-arm";
   }
   setprop("/autopilot/locks/speed",speed);
}

# autopilot help testing during speed-up
Autopilot.schedule = func {
   speed = getprop("/autopilot/locks/speed");

   # activate speed-up mode
   speedup = getprop("/sim/speed-up");
   if( speedup > 1 ) {
       # keep the target speed
       if( speed == "speed-with-throttle-arm" ) {
           setprop("/autopilot/locks/speed","speed-with-throttle");
       }
   }

   # restore default modes
   else {
       if( speed == "speed-with-throttle" ) {
           setprop("/autopilot/locks/speed","speed-with-throttle-arm");
       }
   }

   # adding a waypoint swaps to true heading hold
   mode = getprop("/autopilot/locks/heading");
   if( mode == "true-heading-hold" ) {
       mode2 = getprop("/autopilot/locks/heading2");

       # keeps sperry autopilot
       if( mode2 == "horizontal" ) { 
           mode =  "dg-heading-hold";
       }
       # autopilot not activated, that was a new waypoint
       else {
           mode = "";
       }
       setprop("/autopilot/locks/heading",mode);
   }
}


# =================
# AUTOMATIC MOORING
# =================

Mooring = {};

Mooring.new = func {
   obj = { parents : [Mooring],
           AIRPORTSEC : 3.0
         };

   obj.init();

   return obj;
};

Mooring.init = func {
   me.presetseaplane();
}

# cannot make a settimer on a class member
presetairportcron = func {
   mooringsystem.presetairport();
}

# change of airport
Mooring.presetairport = func {
   airport = getprop("/sim/presets/airport-id");
   runway = getprop("/sim/presets/runway");

   if( getprop("/sim/presets/mooring/airport-id") != airport or
       getprop("/sim/presets/mooring/runway") != runway ) {
       altitude = getprop("/sim/presets/altitude-ft");

       if( altitude <= 0 ) {
           settimer(presetseaplanecron,1.0);
       }
       
       # in flight
       else {
           settimer(presetairportcron,me.AIRPORTSEC);
       }
   }

   # unchanged
   else {
       settimer(presetairportcron,me.AIRPORTSEC);
   }
}

# cannot make a settimer on a class member
presetseaplanecron = func {
   mooringsystem.presetseaplane();
}

# automatic seaplane preset
Mooring.presetseaplane = func {
   moorage = getprop("/sim/presets/moorage");
   if( moorage == nil or moorage ) {
       # wait for end of trim
       if( getprop("/sim/sceneryloaded") ) {
           settimer(presetharbourcron,1.0);
       }

       # wait for end initialization
       else {
           settimer(presetseaplanecron,1.0);
       }
   }

   # no automatic mooring
   else {
       settimer(presetairportcron,me.AIRPORTSEC);
   }
}

# cannot make a settimer on a class member
presetharbourcron = func {
   mooringsystem.presetharbour();
}

# goes to the harbour, once one has the tower
Mooring.presetharbour = func {
   found = "false";
   airport = getprop("/sim/presets/airport-id");
   if( airport != nil and airport != "" ) {
       seaplanes = props.globals.getNode("/sim/presets/mooring").getChildren("seaplane");
       for(i=0; i<size(seaplanes); i=i+1) {
            harbour = seaplanes[ i ].getChild("airport-id").getValue();
            if( harbour == airport ) {
                latitudedeg = seaplanes[ i ].getChild("latitude-deg").getValue();
                setprop("/position/latitude-deg",latitudedeg);
                longitudedeg = seaplanes[ i ].getChild("longitude-deg").getValue();
                setprop("/position/longitude-deg",longitudedeg);
                headingdeg = seaplanes[ i ].getChild("heading-deg").getValue();
                setprop("/orientation/heading-deg",headingdeg);
                adf = seaplanes[ i ].getNode("adf");
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

                runway = getprop("/sim/presets/runway");
                setprop("/sim/presets/mooring/airport-id",airport);
                setprop("/sim/presets/mooring/runway",runway);

                found = "true";

                # doesn't work in the same event, needs some delay
                settimer(presetwatercron,1.5);
                break;
            }
       }
   }

   # moorage not found
   if( found == "false" ) {
       settimer(presetairportcron,me.AIRPORTSEC);
   }
}

# cannot make a settimer on a class member
presetwatercron = func {
   mooringsystem.presetwater();
}

# computes the water level
Mooring.presetwater = func {
   altitudeft = getprop("/position/altitude-ft");
   aglft = getprop("/position/altitude-agl-ft");
   altitudeft = altitudeft - aglft;
   setprop("/position/altitude-ft",altitudeft);

   # scan airport change
   settimer(presetairportcron,me.AIRPORTSEC);
}


# ==============
# Initialization
# ==============

# 2 s cron
sec2cron = func {
   fuelsystem.schedule();
   autopilotsystem.schedule();

   # schedule the next call
   settimer(sec2cron,fuelsystem.SPEEDUPSEC);
}

init = func {
   # schedule the 1st call
   sec2cron();
}

# objects must be here, otherwise local to init()
constant = Constant.new();
fuelsystem = Fuel.new();
mooringsystem = Mooring.new();
autopilotsystem = Autopilot.new();

GDFinstrument = GDF.new();

init();
