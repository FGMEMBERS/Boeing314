# IMPORTANT : always uses /consumables/fuel/tank[0]/level-gal_us, because /level-lb seems not synchronized with
# level-gal_us, during the time of a procedure.

# =================
# Automatic mooring
# =================

# automatic seaplane preset
presetseaplane = func {
   moorage = getprop("/sim/presets/moorage");
   if( moorage == nil or moorage ) {
       # wait for end of trim
       if( getprop("/sim/sceneryloaded") ) {
           settimer(presetharbour,1.0);
       }

       # wait for end initialization
       else {
           settimer(presetseaplane,1.0);
       }
   }
}

# goes to the harbour, once one has the tower
presetharbour = func {
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

                # doesn't work in the same event, needs some delay
                settimer(presetwater,1.5);
                break;
            }
       }
   }
}

# computes the water level
presetwater = func {
   altitudeft = getprop("/position/altitude-ft");
   aglft = getprop("/position/altitude-agl-ft");
   altitudeft = altitudeft - aglft;
   setprop("/position/altitude-ft",altitudeft);
}

# ======================================
# Accelerate consumption during speed-up
# ======================================

SPEEDUPSEC = 2;                                               # refresh rate
CLIMBFTPMIN = 1000;                                           # average climb rate
CLIMBFTPSEC = CLIMBFTPMIN / 60;
MAXSTEPFT = CLIMBFTPSEC * SPEEDUPSEC;

# speed up engine, arguments :
# - engine tank
# - fuel flow of engine
# - sponson tank
# - speed up
speedupengine = func {
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
       enginegal = enginegal / 3600;
       enginegal = enginegal * SPEEDUPSEC;

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
speedupfuel = func {
   altitudeft = getprop("/position/altitude-ft");
   speedup = getprop("/sim/speed-up");
   if( speedup > 1 ) {
       engines = props.globals.getNode("/engines/").getChildren("engine");
       galphour = engines[0].getValue("fuel-flow-gph");
       speedupengine( 0, galphour, 5, speedup );
       galphour = engines[1].getValue("fuel-flow-gph");
       speedupengine( 1, galphour, 5, speedup );
       galphour = engines[2].getValue("fuel-flow-gph");
       speedupengine( 2, galphour, 6, speedup );
       galphour = engines[3].getValue("fuel-flow-gph");
       speedupengine( 3, galphour, 6, speedup );

       # accelerate day time
       node = props.globals.getNode("/sim/time/warp");
       multiplier = speedup - 1;
       offsetsec = SPEEDUPSEC * multiplier;
       warp = node.getValue() + offsetsec; 
       node.setValue(warp);

       # safety
       lastft = getprop("/position/speed-up-ft");
       if( lastft != nil ) {
           stepft = MAXSTEPFT * speedup;
           maxft = lastft + stepft;
           minft = lastft - stepft;

           # too fast
           if( altitudeft > maxft or altitudeft < minft ) {
               setprop("/sim/speed-up",1);
           }
       }
   }

   setprop("/position/speed-up-ft",altitudeft);

   # schedule the next call
    settimer(speedupfuel,SPEEDUPSEC);
}

# ========================
# Ground direction finding
# ========================

callgdf = func {
   if( getprop("/instrumentation/gdf/called") == 1.0 ) {
       if( getprop("/instrumentation/gdf/calling") == 0.0 ) {
           setprop("/instrumentation/gdf/calling",1.0);
           speedup = getprop("/sim/speed-up");
           delaysec = 120.0 / speedup;
       }
       else {
           waypoints = props.globals.getNode("/autopilot/route-manager").getChildren("wp");
           id = waypoints[0].getChild("id").getValue();
           if( id != nil ) {
               bearingdeg = getprop("/autopilot/settings/true-heading-deg");
               setprop("/instrumentation/gdf/true-heading-deg",bearingdeg);
           }
           setprop("/instrumentation/gdf/called",0.0);
           setprop("/instrumentation/gdf/calling",0.0);
           delaysec = 15.0;
       }
   }
   else {
       delaysec = 15.0;
   }

   # schedule the next call
    settimer(callgdf,delaysec);
}

# ==============
# Initialization
# ==============

initgdf = func {
   setprop("/instrumentation/gdf/called",0.0);
   setprop("/instrumentation/gdf/calling",0.0);
   setprop("/instrumentation/gdf/true-heading-deg",0.0);

   # schedule the 1st call
   settimer(callgdf,0.0);
}

init = func {
   initgdf();

   # schedule the 1st call
   settimer(presetseaplane,0.0);
   settimer(speedupfuel,0.0);
}

init();
