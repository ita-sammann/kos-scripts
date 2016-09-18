// Sources:  http://forum.kerbalspaceprogram.com/threads/40053-Estimate-the-duration-of-a-burn

clearscreen.
print "- - - - - - - - - - - - - - - - - - - -".  // line 1
print "Script:  DoNodeDV.txt".  // line 2


// Check that the current stage has liquidfuel, to avoid an error occurring at the last min.  If the stage doesn't even have the resources in the structure (which for mysterious reasons seems to sometimes happen), the script crashes here, rather than later, making it easier to correct.
if STAGE:LiquidFuel = 0 {
	print "LiquidFuel empty.".
}


// Get average ISP of all engines.
// http://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design
set ispsum to 0.
set maxthrustlimited to 0.
LIST ENGINES in MyEngines.
for engine in MyEngines {
    if engine:ISP > 0 {
        set ispsum to ispsum + (engine:MAXTHRUST / engine:ISP).
        set maxthrustlimited to maxthrustlimited + (engine:MAXTHRUST * (engine:THRUSTLIMIT / 100) ).
    }
}
set ispavg to ( maxthrustlimited / ispsum ).
set g0 to 9.82.
set ve to ispavg * g0.
set dv to NEXTNODE:DELTAV:MAG.
set m0 to SHIP:MASS.
set Th to maxthrustlimited.
set e  to CONSTANT():E.
set burntime to (m0 * ve / Th) * (1 - e^(-dv/ve)).
set tminus to burntime / 2.

print "Total burn time for maneuver:  " + ROUND(burntime,2) + " s". // line 3
print "Steering".  // line 4
SAS off.
lock steering to NEXTNODE.

print "Waiting for node".  // line 5
set rt to NEXTNODE:ETA - tminus.    // remaining time
until rt <= 0 {
    set rt to NEXTNODE:ETA - tminus.    // remaining time
    set maxwarp to 8.
    if rt < 100000 { set maxwarp to 7. }
    if rt < 10000  { set maxwarp to 6. }
    if rt < 1000   { set maxwarp to 5. }
    if rt < 100    { set maxwarp to 4. }
    if rt < 60     { set maxwarp to 3. }
    if rt < 50     { set maxwarp to 2. }
    if rt < 25     { set maxwarp to 1. }
    if rt < 8     { set maxwarp to 0. }
    print "    Remaining time:  " + rt at (0,5).  // line 6
    print "       Warp factor:  " + WARP at (0,6).  // line 7
    if WARP > maxwarp {
        set WARP to maxwarp.
    }
}
print " ".
print " ".
set WARP to 0.

set tvar to 0.
lock throttle to tvar.
print "Fast burn".
set olddv to NEXTNODE:DELTAV:MAG + 1.
until (NEXTNODE:DELTAV:MAG < 1 and STAGE:LIQUIDFUEL > 0) or (NEXTNODE:DELTAV:MAG > olddv) {
    //print "Burning".
    set da to maxthrustlimited * THROTTLE / SHIP:MASS.
    set tset to NEXTNODE:DELTAV:MAG * SHIP:MASS / maxthrustlimited.
    if NEXTNODE:DELTAV:MAG < 2*da and tset > 0.1 {
        set tvar to tset.
    }
    if NEXTNODE:DELTAV:MAG > 2*da {
        set tvar to 1.
    }
    set olddv to NEXTNODE:DELTAV:MAG.
}
// caveman debugging
if (NEXTNODE:DELTAV:MAG > olddv) {
    print "Warning:  Delta-V target exceeded during fast-burn!".
}
// compensate 1m/s due to "until" stopping short; nd:deltav:mag never gets to 0!
print "Slow burn".
if STAGE:LIQUIDFUEL > 0 and da <> 0{
    wait 1/da.
}
lock THROTTLE to 0.


unlock all.
print "Stabilizing".
SAS on.

print " ".
print "Orbit:".
print "    Ap:  " + round(SHIP:OBT:APOAPSIS).
print "    Pe:  " + round(SHIP:OBT:PERIAPSIS).
print "- - - - - - - - - - - - - - - - - - - -".
