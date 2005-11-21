Boeing 314A real data
=====================
Weight limits   : take-off 84000 lb (full load), landing 80000 lb (A).

Engine limits   : - maximum : 37.5 inhg 2300 rpm (1350 hp), at sea level; 35.8 inhg 2300 rpm (1350 hp), at 6200 ft (A).
                  - take-off (2 minutes) : 43.5 inhg 2400 rpm (1600 hp) (A).

Airspeed limits : - glide or dive 184 kt true (A).
                  - max 172 kt, cruise 160 kt (D).
                  - Vmax 201 mph [175 kt] at 6200 ft, Vcruise 184 mph [160 kt] at 11000 ft, Vstall 70 mph [61 kt] (C).
                  - maximum 199 mph [173 kt], cruise 184 mph [160 kt] (B)
                  - level flight or climb 155 kt true (A).
                  - flaps extended (40° or less) 105 kt true (A).
                  - flaps extended (more than 40°) 91 kt true (A). 

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


Operation :
- turn    : "If you had to taxi to downwind, on the turn to downwind the wind could get under the upwind wing and tip
            the plane until the downwind wing dug into the water. In that condition a lot of water could flow into the
            wing, and once there could flow through the wings and into the fuselage, dousing everyone and everything.
            That never happened to me but I did hear of such cases.
            When we faced that situation we would have several of the crew walk into the upwind wing out to the outer
            nacelle, to provide balance during the turn." (F).
- cruise  : "One sets up the cruise at 117 mph [102 kt], until 135 mph [117 kt] as one burns off gas.
            They were never anywhere near the advertised max cruise of 193 mph [168 kt] : KSFO - PHNL [2080 NM] at an
            average speed of 126 mph [109 kt], 16 hours depending of wind" (F).
- landing : 70-75 mph [61-65 kt] (F).


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
- taxi     : - increase pitch on 2 symmetrical engines.
             - turn with pitch on 1 or 2 outboard engines.
- take-off : - flaps 2/3 at full load (1/3 at empty load), full throttle 2400 RPM.
             - lift off between 80 kt (full load) and 60 kt (empty load). 
             - long (less than 6000 ft) because of water drag.
- climb    : - retract flaps before 100 kt.
             - reduce to 37.5 inhg (throttle), 2300 RPM.
- maximum  : 160 kt 2300 RPM 37.5 inhg (min pitch, min mixture).
- cruise   : - 110 kt on average.
             - slow climb rate from 9000 ft (full load) to 13400 ft.
- descent  : idle.
- approach : reduce speed at 100 kt, then flaps 1/3.
- landing  : - align at 1500 ft, reduce speed at 90 kt, then flaps 2/3.
             - at 1000 ft, reduce speed at 80 kt, then full flaps.
             - touch down behind the step, between 60 kt (empty load) and 75 kt (full load).
             - short because of water drag.
- stop     : 700 RPM, shutdown 2 or 4 engines.


Customizing
===========
If your preferences.xml doesn't have 6 views, update Boeing314-views.xml and Boeing314-keyboard.xml.

When the airport ID is in Boeing314-route.xml, the seaplane is moved to its moorage, keeping the tower view.
To disable, set /sim/presets/moorage to false.

Sounds
------
See Boeing314-b17-sound.xml to install B17 sounds (recommended).

Fuel load
---------
Default is maximum landing weight, 80000 lb.
For maximum takeoff weight, 85000 lb, set /sim/presets/fuel to 1.
For other configurations, see Boeing314A-fuel.xml.


Keyboard
========
- to hold the current heading or pitch, toggle the switch of Sperry autopilot.
- "e / E" : increases / decreases propeller pitch.
- "q"     : resets speed up to 1.

Views
-----
- "ctrl-E" : "E"ngineer view.
- "ctrl-J" : Copilot view..
- "ctrl-O" : radi"O" view.
 
Unchanged behaviour
-------------------
- "x / X"  : zooms in the small fonts; reset with "ctrl-X".
- starter until slightly below 500 RPM.
  If unable to start the engine, increase the throttle beforehand, or when releasing the starter.
- "ctrl-H" : heading hold.
- "left / right" : turns the heading hold.

Same behaviour
--------------
- "s"      : swaps between Captain and Engineer 2D panels.
- "ctrl-A" : altitude hold (disable pitch hold before).
- "ctrl-P" : pitch hold (disable altitude hold before).
- "ctrl-S" : autothrottle (speed-up only).
 
Improved behaviour
------------------
- "b / B"      : is the rope (brakes), only below 15 kt.
- "up / down"  : increases / decreases pitch hold (fast).
- "home / end"  : increases / decreases pitch hold (slow).
- "a / A"      : speeds up BOTH speed and time : external view until X 10.
  Automatically resets to 1, when above 1000 ft/min.

Ground Direction Finding
------------------------
"The radio operator held the Morse key in transmit mode a minute, while the ground operator took a bearing of the
signal" (G) :
- add a waypoint (WARNING disables the autopilot heading !).
- toggle the switch "GDF" to call the ground operator : range limited to 1500 NM (G)(J).
- within a delay of 2 minutes, the radio returns on a paper the magnetic heading towards the waypoint.

Four course radio range
-----------------------
Emulated by the NDB.
NDB only appeared after WWII with the VOR, when they both superseded the four course radio range (I).


Consumption
===========
Maximum speed 2300 RPM (full throttle, min pitch, min mixture), for 1 engine :
- full load, > 170 kt 78 gallons/h at 9000 ft (J = 1.08).
- empty load, > 160 kt 71 gallons/h at 13400 ft (J = 1.10).
Cruise speed 160 kt (max pitch, min mixture), for 1 engine :
- full load 2200 RPM, 71 gallons/h at 9000 ft (J = 1.07).
- empty load 2300 RPM, 71 gallons/h at 13400 ft (J = 1.10).
Economic speed, 110 kt (max pitch, min mixture), for 1 engine :
- full load 1800 RPM, 47 gallons/h at 9000 ft (J = 0.89).
- empty load 1700 RPM, 36 gallons/h at 13400 ft (J = 1.01).

As the real fuel is 1 US gal = 6 lb (A), multiply by 6.6 / 6 to compare with the real consumption.
 
All with lateral wind.
Min mixture : before engine cutoff.
Max/min pitch : before influence on RPM.

Example
-------
KSFO - PHNL, 2080 NM :
- at 0h10 zulu (afternoon), takeoff at full load (5171 gallons), heading 237 deg.
- average wind 270 deg 15 kt, speed 110 kt indicated, 39 gallons/h.
- cruise starts at 9000 ft, +1000 ft every 5 h, to reach 12000 ft before arrival.
- after 18h00, lands in the morning with 2300 gallons or 18 h.

At 160 kt indicated, the cruise will last 2080 NM / 166 kt = 12.5 h.
And the remaining fuel will be 5171 - 12.5 x 4 x 71 gallons/h = 1600 gallons or 5h30.  


JSBSim
======
- real propeller diameter (14.5 ft).
- real gear ratio 16:9.
- tilt at rest (sponsons).
- economic speed (110 kt).
- planing over step.
- rebound at landing.


TO DO
=====
- fuel transfer or tank selector.
- make 2D instruments from contemporary aircrafts.
- cross feed tanks, fuel per hour gauge.
- celestial navigation.

TO DO JSBSim
-------------
- no weathervaning at rest.
- hull stability (waterloop) with cross wind (F). 
- no propoising at takeoff.
- no tank selector.
- consumption when speed up (done with Nasal).


Known problems
==============
The meaning of instruments is ergonomic guess and historical crosscheck.

Known problems automatic mooring
--------------------------------
- If Nasal crashes the seaplane, try to delay/advance the event.
- Nasal hangs on PCIS (Canton Island) latitude and longitude.

Known problems JSBSim
---------------------
- not enough brake at empty load : cut 2 or 4 engines.
- not enough brake at maximum throttle : increasing the static friction, brings vibrations at rest.
- fakes the displacement to get the real range.
 

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

(J) http://www.panam.org/
    (Adcock Direction Finder).

(K) http://www.pilotfriend.com/flight_training/frames2/seaplane_main_frame.htm/
    (how to fly seaplanes and amphibians).

    http://www.seaplanes.org/library/govtpubs/AC61-21A.pdf
    (seaplane operations : like (K) in pdf).


17 November 2005.
