# ========================
# OVERRIDING NASAL GLOBALS
# ========================

# overrides the parking brake handler for anchoring
override_applyParkingBrake = controls.applyParkingBrake;

controls.applyParkingBrake = func(v) {
    var b = getprop("/controls/gear/brake-parking");

    # can always release
    if( b or globals.Boeing314.mooringsystem.allowedexport() ) {
        setprop("/controls/mooring/anchor", b);

        # boat or pier
        override_applyParkingBrake(v);
    }
}


# overrides the brake handler for mooring
override_applyBrakes = controls.applyBrakes;

controls.applyBrakes = func(v, which = 0) {
    # can always release
    if( !v or globals.Boeing314.mooringsystem.allowedexport() ) {
        # default
        override_applyBrakes( v, which );
    }
}
