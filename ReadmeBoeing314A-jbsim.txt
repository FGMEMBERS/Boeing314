Boeing 314A real data
=====================
Weight limits   : take-off 84000 lb (full load), landing 80000 lb (A).

Engine limits   : - maximum : 37.5 inhg 2300 rpm (1350 hp), at sea level; 35.8 inhg 2300 rpm (1350 hp), at 6200 ft (A).
                  - take-off (2 minutes) : 43.5 inhg 2400 rpm (1600 hp) (A).

Airspeed limits : - flaps extended (more than 40°) 91 kt true (A). 
                  - flaps extended (40° or less) 105 kt true (A).
                  - level flight or climb 155 kt true (A).
                  - maximum 199 mph [173 kt], cruise 184 mph [160 kt] (B)
                  - Vmax 201 mph [175 kt] at 6200 ft, Vcruise 184 mph [160 kt] at 11000 ft, Vstall 70 mph [61 kt] (C).
                  - max 172 kt, cruise 160 kt (D).
                  - glide or dive 184 kt true (A).

Usable ceiling (A) :

Ceiling (ft)   Weight (lb)   RPM   Manifold   True IAS  Cowl flap   De-icers
                                   pressure     (kt)     opening    installed
-----------------------------------------------------------------------------
  10000         80000       2300   Full         100     5 degrees     yes
                                   throttle
   9000         84000       2300   Full         102     5 degrees     yes
                                   throttle

Ceiling : - cruise 13400 ft, maximum 19600 ft, climb 562 ft/min (E).
          - 19600 ft (D).

Range : 5200 miles [4500 NM] (B).


Comparison of 314 with 314A
===========================
Weight limits : take-off 82500 lb (full load) (D).
Engine at 1550 hp, slightly smaller propeller (A).
Airspeed limits : max 167 kt, cruise 158 kt (D).
Ceiling : 13400 ft (D).
Range : 3500 miles [3000 NM] (B).


314 real schedule (H)
=================
In 1939, France was GMT-0, and one must suppose that Ireland was GMT-1.

Eastbound flights are longer because of westerly winds.
Probably not direct, Lisbon - Marseille is slower.

Departure              Arrival               Lag    Westbound    Eastbound    Distance          Leg            Speed 
-------------------------------------------------------------------------------------------------------------------------
Port Washington NY     Shediac NB            1 h       4h           4h          510 NM       KLGA CYQM           128 kt
Shediac NB             Botwood NF            0 h       3h           3h          410 NM       CYQM CCP2           137 kt
Botwood NF             Foynes Ireland        3 h      11h30        16h30       1740 NM       CCP2 EINN       151/105 kt
Foynes Ireland         Southampton UK        1 h       2h30         2h30        300 NM       EINN EGHI           120 kt

Port Washington NY     Horta Azores          3 h      16h          20h         2070 NM       KLGA LPHR       129/104 kt
Horta Azores           Lisbon Portugal       2 h       7h           7h          920 NM       LPHR LPPT           131 kt
Lisbon Portugal        Marseille France      0 h       8h           8h          705 NM       LPPT LFML            88 kt

Baltimore ND           Port Washington NY    0 h       1h30         1h30        160 NM       KBWI KLGA           107 kt
Port Washington NY     Bermuda Island        1 h       5h           5h30        670 NM       KLGA TXKF       134/122 kt


314A ops
========
- parking  : 700 RPM.
- taxi     : 4 or 2 outboards engines.
- turn     : - turn with throttle on 1 or 2 outboard engines.
             - "If you had to taxi to downwind, on the turn to downwind the wind could get under the upwind wing and tip
             the plane until the downwind wing dug into the water. In that condition a lot of water could flow into the
             wing, and once there could flow through the wings and into the fuselage, dousing everyone and everything.
             That never happened to me but I did hear of such cases.
             When we faced that situation we would have several of the crew walk into the upwind wing out to the outer
             nacelle, to provide balance during the turn." (F).
- take-off : - with idle throttle, let the bow align itself inside the wind.
             - full flaps, 78 kt at full load, 65 kt at empty load, full throttle 2400 RPM.
             - long (less than 6000 ft) because of water drag.
- climb    : reduce to 37.5 inhg (throttle), 2300 RPM (at first mixture until cutoff, then pitch until ineffective
             and finally throttle until ineffective).
- maximum  : 160 kt 2300 RPM 37.5 inhg (min pitch, min mixture).
- cruise   : - "One sets up the cruise at 117 mph [102 kt], until 135 mph [117 kt] as one burns off gas.
             They were never anywhere near the advertised max cruise of 193 mph [168 kt] : KSFO - PHNL [2080 NM] at an
             average speed of 126 mph [109 kt], 16 hours depending of wind" (F).
             - slow climb rate from 9000 ft (full load) to 13400 ft.
- descent  : reduce throttle, increase pitch.
- approach : - level to reduce speed at 100 kt, then flaps 2/3.
             - maintain 90 kt.
- landing  : - align at 1000 ft, then full flaps.
             - maintain 80 kt.
             - land at 70-75 mph [61-65 kt] (F).
             - short because of water drag.
- stop     : shutdown 2 or 4 engines, if unable to stop alone.


Customizing
===========
When the airport ID is in Boeing314-route.xml, the seaplane is moved to its moorage, keeping the tower view.
To disable, set /sim/presets/moorage to false.

Fuel
----
Boeing314A-set.xml has 3 configurations (max payload) :
- empty weight, 50000 lb.
- maximum landing weight, 80000 lb.
- maximum takeoff weight, 84000 lb : put in comment the US gallons (inheritance from JSBSim).


Keyboard
========
- "s" swaps between Captain and Engineer 2D panels.
- "B"rake is the rope.
- starter until slightly below 500 RPM.
  If unable to start the engine, increase the throttle beforehand, or when releasing the starter.
- to hold the current heading or pitch, toggle the switch of Sperry autopilot.
- "q" resets speed up to 1.
 
Overriden
---------
- "a/A" speeds up BOTH speed and time : external view until X 10.
  Automatically resets to 1, when above 1000 ft/min.

Ground Direction Finding
------------------------
"The radio operator held the Morse key in transmit mode a minute, while the ground operator took a bearing of the
signal" (G) :
- add a waypoint (disables the autopilot heading !).
- toggle the switch "GDF" to call the ground operator : range limited to 1500 NM (G).
- within a delay of 2 minutes, the GDF needle will point towards the waypoint.

Four course radio range
-----------------------
It is emulated by the NDB.
NDB only appeared after WWII with the VOR, when they both superseded the four course radio range (I).


Consumption
===========
Maximum speed 2300 RPM (full throttle, min pitch, min mixture), for 1 engine :
- full load, > 175 kt 110 gallons/h at 9500 ft.
- empty load, 166 kt 95 gallons/h at 13400 ft.
Economic speed 34.5 gallons/h (max pitch, min mixture), for 1 engine :
- full load 1850 RPM, 120 kt at 9500 ft.
- empty load 1950 RPM, 135 kt at 13400 ft.

Example
-------
KSFO - PHNL, 2080 NM :
- takeoff at full load (5688 gallons).
- wind 270 deg 12 kt, average speed 115 kt.
- reaches 13400 ft at half way.
- after 17h15, lands with 1470 gallons.


JSBSim
======
- real propeller diameter (14.5 ft).
- hull drag.
- tilt at rest (sponsons).
- economic speed (120 kt).


TO DO
=====
- fuel transfer or tank selector.
- map the 2D instruments in a 3D cockpit.
- make 2D instruments from contemporary aircrafts.
- cross feed of tanks.
- celestial navigation.

TO DO JSBSim
-------------
- no step.
- no tank selector.
- consumption when speed up (done with Nasal).
- hull stability with cross wind (F). 


Known problems
==============
The meaning of instruments is ergonomic guess and historical crosscheck.

Known problems automatic mooring
--------------------------------
If Nasal crashes the seaplane, try to increase the delays.

Known problems JSBSim
---------------------
- not enough brake at maximum throttle : increasing the static friction, brings vibrations at rest.
- at rest 700 RPM, one may have not enough brake or engines may stop with idle throttle : not systematic, depends of
pressure and/or temperature. 
- economic speed seems slightly too high : 120 kt instead of 110 kt.

Known problems autopilot
------------------------
- at high speed (160 kt 9500 ft), autopilot heading hold may lock with roll.
 

References
==========
(A) http://www.airweb.faa.gov/Regulatory_and_Guidance_Library/rgMakeModel.nsf/MainFrame?OpenFrameSet
    (FAA certificate, TC704 - 5 february 1941, 314A).

(B) http://www.boeing.com/history/boeing/m314.html/
    (314A)

(C) http://www.hq.nasa.gov/office/pao/History/SP-468/app-a2.htm/
    (314).

(D) http://aeroweb.brooklyn.cuny.edu/locator/manufact/boeing/bng-314.htm/
    (Differences 314 / 314A).

(E) http://www.flyingclippers.com/B314.html/

(F) http://www.southernoregonwarbirds.org/fa3.html/
    (Franck Varnum flew during WWII). 

(G) http://www.petan.net/aviation/gdf.htm/
    (Marconi Adcock Direction Finder).

(H) http://bluegrassairlines.com/bgas/clip01.htm/
    (1939 PAAA schedule).

(I) http://members.aol.com/trekkspill/aerobcn.html/
    (four course radio range).


8 january 2005.
