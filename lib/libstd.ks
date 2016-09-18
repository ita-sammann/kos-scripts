@lazyglobal off.

function newELoop {
    local loop is lexicon("_events", lexicon(), "_eid", 0).

    function _iteration {
        parameter self.
        for eid in self["_events"]:keys {
            local e is self["_events"][eid].
            if e["cond"]() {
                if not e["func"]() {
                    self["rmEvent"](eid).
                }
            }
        }.
    }
    loop:add("_iteration", _iteration@:bind(loop)).

    function addEvent {
        parameter self, cond, func.
        set self["_eid"] to self["_eid"] + 1.
        self["_events"]:add(self["_eid"], lexicon("cond", cond, "func", func)).
        return self["_eid"].
    }
    loop:add("addEvent", addEvent@:bind(loop)).

    function rmEvent {
        parameter self, id.
        self["_events"]:remove(id).
    }
    loop:add("rmEvent", rmEvent@:bind(loop)).

    function waitTime {
        parameter self, dt.
        local t0 is time:seconds.
        until false {
            self["_iteration"]().
            if time:seconds > t0 + dt {
                break.
            }
        }
    }
    loop:add("waitTime", waitTime@:bind(loop)).

    function waitCond {
        parameter self, condFunc.
        until false {
            self["_iteration"]().
            if condFunc() {
                break.
            }
        }
    }
    loop:add("waitCond", waitCond@:bind(loop)).

    function doUntil {
        parameter self, cond, func.
        local condfunc is { return not cond(). }.
        self["addEvent"]({ return true. }, {
            func().
            if cond() {
                return false.
            } else {
                return true.
            }
        }).
        self["waitCond"](cond).
    }
    loop:add("doUntil", doUntil@:bind(loop)).


    return loop.
}

function safedoevent {
    parameter nametag, modulename, eventname.
    local parts is ship:partstagged(nametag).
    if parts:length = 0 {
        print "No parts found by tag '" + nametag + "'".
        return.
    }
    for part in parts {
        local modnames is part:modules.
        local hasmodule is false.
        for mn in modnames {
            if mn = modulename {
                set hasmodule to true.
                break.
            }
        }
        if hasmodule {
            local mdl is part:getmodule(modulename).
            if mdl:hasevent(eventname) {
                mdl:doevent(eventname).
            } else {
                print "Part " + nametag + ": module " + modulename + " has no event '" + eventname + "'".
            }
        } else {
            print "No module named '" + modulename + "' in part " + nametag.
        }
    }
}

function safeactivate {
    parameter nametag.
    local parts is ship:partstagged(nametag).
    if parts:length = 0 {
        print "No parts found by tag '" + nametag + "'".
        return.
    }
    for part in parts {
        part:activate.
    }
}

function addnode {
    //in km
    parameter new_otherapsis, on_apo is true.
    set new_otherapsis to new_otherapsis * 1000.
    local node_time is 0.
    local otherapsis is 0.
    local burnapsis is 0.

    if on_apo {
      set node_time to time:seconds + eta:apoapsis.
      set otherapsis to periapsis.
      set burnapsis to apoapsis.
    } else {
      set node_time to time:seconds + eta:periapsis.
      set otherapsis to apoapsis.
      set burnapsis to periapsis.
    }

    print "Setting up maneuver node. ETA=" + (node_time - time:seconds).
    local burn is node(node_time, 0,0,0).
    add burn.

    local v_old is sqrt(body:mu * (2/(burnapsis+body:radius) -
                                 1/ship:obt:semimajoraxis)).
    local v_new is sqrt(body:mu * (2/(burnapsis+body:radius) -
                     1/(body:radius+(new_otherapsis+burnapsis)/2))).
    local dv is v_new - v_old.
    set burn:prograde to dv.
}

function doNodeDV {
    parameter el, nodeEngines.
    if stage:liquidfuel = 0 {
    	print "LiquidFuel empty".
        return.
    }
    if nodeEngines:length = 0 {
    	print "No engines".
        return.
    }
    print "Executing maneuver node".

    local ispsum is 0.
    local maxthrustlimited is 0.
    for engine in nodeEngines {
        if engine:isp > 0 {
            set ispsum to ispsum + (engine:maxthrust / engine:isp).
            set maxthrustlimited to maxthrustlimited + (engine:maxthrust * (engine:thrustlimit / 100) ).
        }
    }
    local ispavg is ( maxthrustlimited / ispsum ).
    local g0 is 9.82.
    local ve is ispavg * g0.
    local dv is nextnode:deltav:mag.
    local m0 is ship:mass.
    local Th is maxthrustlimited.
    local e  is constant:e.
    local burntime is (m0 * ve / Th) * (1 - e^(-dv/ve)).
    local tminus is burntime / 2.

    print "Total burn time for maneuver:  " + round(burntime, 2) + " s".
    print "Steering".
    sas off.
    lock steering to nextnode.

    print "Waiting for node".
    local rt is nextnode:eta - tminus.
    el["doUntil"]({ return rt <= 0. }, {
        set rt to nextnode:eta - tminus.
        local maxwarp is 8.
        if rt < 100000 { set maxwarp to 7. }
        if rt < 10000  { set maxwarp to 6. }
        if rt < 1000   { set maxwarp to 5. }
        if rt < 100    { set maxwarp to 4. }
        if rt < 60     { set maxwarp to 3. }
        if rt < 50     { set maxwarp to 2. }
        if rt < 25     { set maxwarp to 1. }
        if rt < 8      { set maxwarp to 0. }
        if warp > maxwarp {
            set warp to maxwarp.
            print "Remaining time: " + rt + ", warp factor: " + warp.
        }
    }).
    set warp to 0.

    local tvar is 0.
    lock throttle to tvar.
    print "Fast burn".
    local olddv is nextnode:deltav:mag.
    local da is maxthrustlimited * throttle / ship:mass.

    el["doUntil"]({ return (nextnode:deltav:mag < 1 and stage:liquidfuel > 0) or (nextnode:deltav:mag > (olddv + 1)) }, {
        set da to maxthrustlimited * throttle / ship:mass.
        local tset is nextnode:deltav:mag * ship:mass / maxthrustlimited.
        if nextnode:deltav:mag < 2*da and tset > 0.1 {
            set tvar to tset.
        }
        if nextnode:deltav:mag > 2*da {
            set tvar to 1.
        }
        set olddv to nextnode:deltav:mag.
    }).

    // poor man's debugging
    if (nextnode:deltav:mag > olddv) {
        print "Warning: Delta-V target exceeded during fast-burn!".
    }

    // compensate 1m/s due to "until" stopping short; nd:deltav:mag never gets to 0!
    print "Slow burn".
    if stage:liquidfuel > 0 and da <> 0{
        el["waitTime"](1/da).
    }
    lock throttle to 0.

    set ship:control:pilotmainthrottle to 0.
    unlock throttle.
    unlock steering.
    print "Stabilizing".
    sas on.

    print " ".
    print "Orbit:".
    print "    Ap:  " + round(ship:obt:apoapsis).
    print "    Pe:  " + round(ship:obt:periapsis).
    print "- - - - - - - - - - - - - - - - - - - -".
}
