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

function dosafe {
    parameter nametag, modulename, eventname.
    local parts is ship:partstagged(nametag).
    if parts:length = 0 {
        print "No parts found by tag '" + nametag + "'".
        return.
    }
    for part in parts {
        local modules is part:modules.
        local hasmodule is false.
        for mdl in modules {
            if mdl = modulename {
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
