@lazyglobal off.

function newELoop {
    local loop is lexicon("_events", lexicon(), "_eid", 0).

    function _iteration {
        parameter self.
        for eid in self["_events"]:keys {
            local e is self["_events"][eid].
            if e[0]() {
                if not e[1]() {
                    self["rmEvent"](eid).
                }
            }
        }.
    }
    loop:add("_iteration", _iteration@:bind(loop)).

    function addEvent {
        parameter self, cond, func.
        set self["_eid"] to self["_eid"] + 1.
        self["_events"]:add(self["_eid"], list(cond, func)).
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

    //run ship_burn_node.
}
