@lazyglobal off.

function initELoop {
  local loop is lexicon("_events", lexicon(), "_eid", 0).

  loop:add("_iteration", {
    parameter self.
    for e in self["_events"]:values {
      if e[0]() {
        e[1]().
      }
    }.
  }:bind(loop)).

  loop:add("addEvent", {
    parameter self, cond, func.
    self["_eid"] = self["_eid"] + 1.
    self["_events"]:add(self["_eid"], list(cond, func)).
    return self["_eid"].
  }:bind(loop)).

  loop:add("rmEvent", {
    parameter self, id.
    self["_events"]:remove(id).
  }:bind(loop)).

  loop:add("waitTime", {
    parameter self, dt.
    local t0 is time:seconds.
    until false {
      self["_iteration"]().
      if time:seconds > t0 + dt {
        break.
      }
    }
  }:bind(loop)).

  loop:add("waitCond", {
    parameter self, condFunc.
    until false {
      self["_iteration"]().
      if condFunc() {
        break.
      }
    }
  }:bind(loop)).

  return loop.
}
