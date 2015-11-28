# ========================
# OVERRIDING NASAL GLOBALS
# ========================

# overrides the parking brake handler for anchoring
override_applyParkingBrake = controls.applyParkingBrake;

controls.applyParkingBrake = func(v) {
    var b = getprop("/controls/gear/brake-parking");

    if( globals.Boeing314.mooringsystem == nil ) {
        override_incElevator(arg[0], arg[1]);
    }
    # can always release
    elsif( b or globals.Boeing314.mooringsystem.allowedexport() ) {
        setprop("/controls/mooring/anchor", b);

        # boat or pier
        override_applyParkingBrake(v);
    }
}


# overrides the brake handler for mooring
override_applyBrakes = controls.applyBrakes;

controls.applyBrakes = func(v, which = 0) {
    if( globals.Boeing314.mooringsystem == nil ) {
        override_incElevator(arg[0], arg[1]);
    }
    # can always release
    elsif( !v or globals.Boeing314.mooringsystem.allowedexport() ) {
        # default
        override_applyBrakes( v, which );
    }
}



# overrides the keyboard for autopilot adjustment or floating view.

override_incElevator = controls.incElevator;

controls.incElevator = func {
    var sign = 1.0;
    
    if( arg[0] < 0.0 ) {
	sign = -1.0;
    }
    
    if( globals.Boeing314.seatsystem == nil ) {
        override_incElevator(arg[0], arg[1]);
    }
    elsif( !globals.Boeing314.seatsystem.movelengthexport(-0.01 * sign) ) {
        if( !globals.Boeing314.autopilotsystem.pitchexport(5.0 * sign) ) {
            # default
            override_incElevator(arg[0], arg[1]);
        }
    }
}

override_incAileron = controls.incAileron;

controls.incAileron = func {
    var sign = 1.0;
    
    if( arg[0] < 0.0 ) {
	sign = -1.0;
    }
    
    if( globals.Boeing314.seatsystem == nil ) {
        override_incAileron(arg[0], arg[1]);
    }
    elsif( !globals.Boeing314.seatsystem.movewidthexport(0.01 * sign) ) {
        if( !globals.Boeing314.autopilotsystem.headingexport(1.0 * sign) ) {
            # default
            override_incAileron(arg[0], arg[1]);
        }
    }
}

override_incThrottle = controls.incThrottle;

controls.incThrottle = func {
    var sign = 1.0;
    
    if( arg[0] < 0.0 ) {
	sign = -1.0;
    }
    
    if( globals.Boeing314.seatsystem == nil ) {
        override_incThrottle(arg[0], arg[1]);
    }
    elsif( !globals.Boeing314.seatsystem.moveheightexport(0.01 * sign) ) {
        # default
        override_incThrottle(arg[0], arg[1]);
    }
}
