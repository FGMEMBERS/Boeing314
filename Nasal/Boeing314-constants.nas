# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ====================
# BOEING 314 CONSTANTS
# ====================

ConstantAero = {};

ConstantAero.new = func {
   obj = { parents : [ConstantAero],

# AGL altitude when on ground : radio altimeter is above gear
# (Z height of center of gravity minus Z height of main landing gear)
           AGLFT : 8
         };

   return obj;
}


# =========
# CONSTANTS
# =========

Constant = {};

Constant.new = func {
   obj = { parents : [Constant],

           TRUE : 1.0,                             # no boolean
           FALSE : 0.0,

# angle
           DEG180 : 180,

# time
           HOURTOSECOND : 3600.0,
           MINUTETOSECOND : 60.0,

# weight
           GALUSTOLB : 6.6,                        # 1 US gallon = 6.6 pound
           LBTOGALUS : 0.0
         };

   obj.init();

   return obj;
};

Constant.init = func {
   me.LBTOGALUS = 1 / me.GALUSTOLB;
}
