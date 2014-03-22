# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ============
# VIRTUAL CREW
# ============

VirtualCrew = {};

VirtualCrew.new = func {
   var obj = { parents : [VirtualCrew,System], 

               generic : Generic.new(),

               GROUNDSEC : 15.0,                               # to reach the ground
               CREWSEC : 10.0,                                 # to complete the task
               TASKSEC : 2.0,                                  # between 2 tasks
               DELAYSEC : 1.0,                                 # random delay

               task : constant.FALSE,
               taskend : constant.TRUE,
               taskground : constant.FALSE,
               taskcrew : constant.FALSE,

               activ : constant.FALSE,
               running : constant.FALSE,

               state : ""
         };

    return obj;
}

VirtualCrew.inherit_virtualcrew = func( path ) {
    me.inherit_system( path );

    var obj = VirtualCrew.new();

    me.generic = obj.generic;

    me.GROUNDSEC = obj.GROUNDSEC;
    me.CREWSEC = obj.CREWSEC;
    me.TASKSEC = obj.TASKSEC;
    me.DELAYSEC = obj.DELAYSEC;

    me.task = obj.task;
    me.taskend = obj.taskend;
    me.taskground = obj.taskground;
    me.taskcrew = obj.taskcrew;

    me.activ = obj.activ;
    me.running = obj.running;
    me.state = obj.state;
}

VirtualCrew.toggleclick = func( message = "" ) {
    me.done( message );

    me.generic.toggleclick();
}

VirtualCrew.done = func( message = "" ) {
    if( message != "" ) {
        me.log( message );
    }

    # first task to do.
    me.task = constant.TRUE;
}

VirtualCrew.done_ground = func( message = "" ) {
    # procedure to execute with delay
    me.taskground = constant.TRUE;

    me.done( message );
}

VirtualCrew.done_crew = func( message = "" ) {
    # procedure to execute with delay
    me.taskcrew = constant.TRUE;

    me.done( message );
}

VirtualCrew.log = func( message ) {
    me.state = me.state ~ " " ~ message;
}

VirtualCrew.getlog = func {
    return me.state;
}

VirtualCrew.reset = func {
    me.state = "";
    me.activ = constant.FALSE;
    me.running = constant.FALSE;

    me.task = constant.FALSE;
    me.taskend = constant.TRUE;
}

VirtualCrew.set_activ = func {
    me.activ = constant.TRUE;
}

VirtualCrew.is_activ = func {
    return me.activ;
}

VirtualCrew.set_running = func {
    me.running = constant.TRUE;
}

VirtualCrew.is_running = func {
    return me.running;
}

VirtualCrew.wait_ground = func {
    return me.taskground;
}

VirtualCrew.reset_ground = func {
    me.taskground = constant.FALSE;
}

VirtualCrew.wait_crew = func {
    return me.taskcrew;
}

VirtualCrew.reset_crew = func {
    me.taskcrew = constant.FALSE;
}

VirtualCrew.can = func {
    # still something to do, must wait.
    if( me.task ) {
        me.taskend = constant.FALSE;
    }

    return !me.task;
}

VirtualCrew.randoms = func( steps ) {
    # doesn't overwrite, if no task to do
    if( !me.taskend ) {
        var margins  = rand() * me.DELAYSEC;

        if( me.taskground ) {
            steps = me.GROUNDSEC;
        }

        elsif( me.taskcrew ) {
            steps = me.CREWSEC;
        }

        else {
            steps = me.TASKSEC;
        }

        steps = steps + margins;
    }

    return steps;
} 

VirtualCrew.timestamp = func {
    var action = me.itself["root"].getChild("state").getValue();

    # save last real action
    if( action != "" ) {
        me.itself["root"].getChild("state-last").setValue(action);
    }

    me.itself["root"].getChild("state").setValue(me.getlog());
    me.itself["root"].getChild("time").setValue(me.noinstrument["time"].getChild("gmt-string").getValue());
}

VirtualCrew.completed = func {
    if( me.can() ) {
        me.set_completed();
    }
}

VirtualCrew.has_completed = func {
    var result = constant.FALSE;

    if( me.can() ) {
        result = me.is_completed();
    }

    return result;
}


# ========================
# GROUND DIRECTION FINDING
# ========================

GDF = {};

GDF.new = func {
   var obj = { parents : [GDF,System],

               CALLSEC : 120.0,
  
               RANGENM : 1300
         };

   obj.init();

   return obj;
};

GDF.init = func {
   me.inherit_system( "/instrumentation/gdf" );
}

GDF.callexport = func {
   var id = "";
   var airport = nil;

   if( !me.itself["root"].getChild("calling").getValue() ) {
       var state = "";

       # no waypoint
       id = me.itself["root"].getChild("airport").getValue();
       if( id == nil or id == "" ) {
           state = "Add an airport as station";
       }

       else {
           airport = airportinfo(id);
           if( airport != nil ) {
               var destination = geo.Coord.new();
               var flight = geo.aircraft_position();

               # out of range
               destination.set_latlon( airport.lat, airport.lon );
               if( flight.distance_to( destination ) > me.RANGENM * constant.NMTOMETER ) {
                   state = "Station is out of range";
               }

               else {
                   state = "Calling station operator";

                   me.itself["root"].getChild("called").setValue(constant.TRUE);
                   me.itself["root"].getChild("calling").setValue(constant.TRUE);

                   var speedup = me.noinstrument["speed-up"].getValue();
                   var delaysec = me.CALLSEC / speedup;

                   # schedule the next call
                   settimer(func{ me.callexport(); },delaysec);
               }
           }

           else {
                state ="Airport not found";
           }
       }

       me.itself["root"].getChild("state").setValue(state);
   }

   elsif( me.itself["root"].getChild("called").getValue() ) {
       id = me.itself["root"].getChild("airport").getValue();
       if( id != nil ) {
           airport = airportinfo(id);
           if( airport != nil ) {
               var destination = geo.Coord.new();
               var flight = geo.aircraft_position();

               destination.set_latlon( airport.lat, airport.lon );

               # magnetic heading for gyro (Sperry)
               var bearingdeg = flight.course_to( destination );
               var magdeg = me.dependency["mag-variation"].getValue();

               bearingdeg = bearingdeg - magdeg;

               # north crossing
               if( bearingdeg < 0 ) {
                   bearingdeg = 360 + bearingdeg;
               }
               elsif( bearingdeg > 360 ) {
                   bearingdeg = bearingdeg - 360;
               }

               # rounding
               bearingdeg = sprintf( "%3d", bearingdeg );

               me.itself["root"].getChild("heading-deg").setValue(bearingdeg);

               # remove seconds
               var reception = me.dependency["clock"].getValue();

               reception = substr( reception, 0, 5 );

               me.itself["root"].getChild("gmt-string").setValue(reception);
               me.itself["root"].getChild("show-paper").setValue(constant.TRUE);
           }
       }

       me.itself["root"].getChild("called").setValue(constant.FALSE);
       me.itself["root"].getChild("calling").setValue(constant.FALSE);
       me.itself["root"].getChild("state").setValue("");
   }
}


# ===================
# ASYNCHRONOUS CHECKS
# ===================

AsynchronousCheck = {};

AsynchronousCheck.new = func {
   var obj = { parents : [AsynchronousCheck],

               completed : constant.TRUE
             };

   return obj;
}

AsynchronousCheck.inherit_asynchronouscheck = func( path ) {
   me.inherit_system( path );

   var obj = AsynchronousCheck.new();

   me.completed = obj.completed;
}

AsynchronousCheck.is_change = func {
   var change = constant.FALSE;

   return change;
}

# once night lighting, virtual crew must switch again lights.
AsynchronousCheck.set_task = func {
   me.completed = constant.FALSE;
}

AsynchronousCheck.has_task = func {
   var result = constant.FALSE;

   if( me.is_change() or !me.completed ) {
       result = constant.TRUE;
   }
   else {
       result = constant.FALSE;
   }

   return result;
}

AsynchronousCheck.set_completed = func {
   me.completed = constant.TRUE;
}


# ================
# RADIO MANAGEMENT
# ================

RadioManagement = {};

RadioManagement.new = func {
   var obj = { parents : [RadioManagement,AsynchronousCheck,System],

               autopilotsystem : nil,

               EARTHKM : 20000,                  # largest distance between 2 points on earth surface
               RANGENM : 200,                    # range to change the radio frequencies

               target : "",
               tower : "",

               NOENTRY : -1,
               entry : -1
         };

   obj.init();

   return obj;
};

RadioManagement.init = func {
   me.inherit_asynchronouscheck("/systems/human");
}

RadioManagement.set_relation = func( autopilot ) {
    me.autopilotsystem = autopilot;
}

RadioManagement.copilot = func( task ) {
   # optional
   if( me.dependency["crew"].getChild("radio").getValue() ) {
       if( me.has_task() ) {
           me.set_task();

           # ADF 1
           if( task.can() ) {
               me.set_adf( 0, task );
           }

           if( task.can() ) {
               me.set_completed();
           }
       }
   }
}

RadioManagement.set_adf = func( index, task ) {
    var phase = me.get_phase();

    if( phase != nil ) {
        var adf = phase.getChildren("adf");

        if( index < size( adf ) ) {
            var frequency = nil;
            var frequencykhz = 0;
            var currentkhz = 0;

            # not real : no ADF standby frequency
            frequency = adf[ index ].getChild("standby-khz");
            if( frequency != nil ) {
                frequencykhz = frequency.getValue();
                currentkhz = me.dependency["adf"][index].getNode("frequencies/standby-khz").getValue();

                if( currentkhz != frequencykhz ) {
                    me.dependency["adf"][index].getNode("frequencies/standby-khz").setValue(frequencykhz);
                }
            }

            frequency = adf[ index ].getChild("selected-khz");
            if( frequency != nil ) {
                frequencykhz = frequency.getValue();
                currentkhz = me.dependency["adf"][index].getNode("frequencies/selected-khz").getValue();

                if( currentkhz != frequencykhz ) {
                    me.dependency["adf"][index].getNode("frequencies/selected-khz").setValue(frequencykhz);
                    task.toggleclick("adf " ~ index);
                }
            }
        }
    }
}

RadioManagement.get_phase = func {
    var phase = nil;

    if( me.entry > me.NOENTRY ) {
        phase = me.itself["airport"][ me.entry ];
    }

    return phase;
}

RadioManagement.is_change = func {
   var result = constant.FALSE;
   var index = me.NOENTRY;
   var distancemeter = 0.0;
   var nearestmeter = me.EARTHKM * constant.KMTOMETER;
   var airport = "";
   var info = nil;
   var flight = geo.aircraft_position();
   var destination = geo.Coord.new();


   # nearest airport
   me.target = "";
   for(var i=0; i<size(me.itself["airport"]); i=i+1) {
       airport = me.itself["airport"][ i ].getChild("airport-id").getValue();
       info = airportinfo( airport );

       if( info != nil ) {
           destination.set_latlon( info.lat, info.lon );
           distancemeter = flight.distance_to( destination ); 
           if( distancemeter < nearestmeter ) {
               me.target = airport;
               nearestmeter = distancemeter;
               index = i;
           }
       }
   }


   # only within radio range
   if( nearestmeter < me.RANGENM * constant.NMTOMETER ) {
       if( me.tower != me.target ) {
           me.entry = index;

           me.itself["root"].getChild("airport-id").setValue( me.target );

           result = constant.TRUE;
       }
   }

   return result;
}

RadioManagement.set_completed = func {
   me.tower = me.target;

   me.completed = constant.TRUE;
}
