// Sources:  http://forum.kerbalspaceprogram.com/threads/40053-Estimate-the-duration-of-a-burn


clearscreen.
print "- - - - - - - - - - - - - - - - - - - -".  // line 1
print "Script:  BurnTime.txt".  // line 2


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
set burnlength to (m0 * ve / Th) * (1 - e^(-dv/ve)).

print "Total burn time for maneuver:  " + ROUND(burnlength,2) + " s". 

print "- - - - - - - - - - - - - - - - - - - -".
