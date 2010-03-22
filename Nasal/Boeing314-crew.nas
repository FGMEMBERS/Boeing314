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
    me.itself["root"].getChild("time").setValue(getprop("/sim/time/gmt-string"));
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

   me.workaround();

   if( !me.itself["root"].getChild("calling").getValue() ) {
       var state = "";

       # no waypoint
       id = me.noinstrument["waypoint"][0].getChild("id").getValue();
       if( id == nil or id == "" ) {
           state = "Add a waypoint as station"
       }

       # out of range
       elsif( me.noinstrument["waypoint"][0].getChild("dist").getValue() > me.RANGENM ) {
           state = "Station is out of range"
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

       me.itself["root"].getChild("state").setValue(state);
   }

   elsif( me.itself["root"].getChild("called").getValue() ) {
       id = me.noinstrument["waypoint"][0].getChild("id").getValue();
       if( id != nil ) {

           # magnetic heading for gyro (Sperry)
           var bearingdeg = me.noinstrument["bearing"].getValue();
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

       me.itself["root"].getChild("called").setValue(constant.FALSE);
       me.itself["root"].getChild("calling").setValue(constant.FALSE);
       me.itself["root"].getChild("state").setValue("");
   }
}

GDF.workaround = func {
   var id = "";


   # TEMPORARY work around for 2.0.0
   if( me.route_active() ) {
       # each time, because the route can change
       var wp = me.noinstrument["route"].getChildren("wp");
       var nb_wp = size(wp);

       # route manager doesn't update these fields
       if( nb_wp >= 1 ) {
           id = wp[0].getChild("id").getValue();
       }
   }

   me.noinstrument["waypoint"][0].getChild("id").setValue( id );
}

GDF.route_active = func {
   var result = constant.FALSE;

   # autopilot/route-manager/wp is updated only once airborne
   if( me.noinstrument["route-manager"].getChild("active").getValue() and
       me.noinstrument["route-manager"].getChild("airborne").getValue() ) {
       result = constant.TRUE;
   }

   return result;
}
