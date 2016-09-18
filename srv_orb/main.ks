@lazyglobal off.
//clearscreen.

set ship:control:pilotmainthrottle to 0.
local el is newELoop().

function fireLES {
    parameter hdg is 0.
	safedoevent("LESTower", "ModuleRCS", "enable rcs port").
    rcs on.
	safeactivate("LESTower").
    lock steering to heading(hdg, 70).
}

function dropFairings {
	safedoevent("fairings", "ProceduralFairingDecoupler", "jettison").
	safedoevent("dockPort", "ModuleDockingNode", "decouple node").
}

function armChutes {
    safedoevent("landerChutes", "RealChuteModule", "arm parachute").
	safedoevent("drogueChutes", "RealChuteModule", "arm parachute").
}

function abortSequence {
    safedoevent("serviceModule", "ModuleAnimatedDecoupler", "decouple").
    wait 0.1.
    fireLES(180).

    wait 3.7.
    dropFairings().
    rcs off.
    unlock steering.

    wait until ship:verticalspeed < 0.
}

function landingSequence {
    armChutes().
    wait until alt:radar < 250.
    safedoevent("heatShld", "ModuleDecouple", "Jettison heat shield").
    wait until alt:radar < 2.7.
    safeactivate("softLandThrusters").
}

local abortEvent is el["addEvent"]({
    return abort.
}, {
    unlock throttle.
    unlock steering.
    abortSequence().
    landingSequence().
    return false.
}).

function launchSequence {
    parameter hdg is 90, orbAlt is 100.
    lock throttle to 1.
    print "Start engines".
    stage. // start 1st stage engine
    el["waitTime"](4). // wait for engine to power up
    print "Liftoff".
    stage. // release launch clamps
    el["waitTime"](5). // wait for rocket to get clear of launch tower
    lock steering to heading(hdg, 90).
    el["addEvent"]({ return ship:maxthrust <= 0. }, {
        print "Staging".
        stage.
        el["waitTime"](2.5). // wait until celar of 1st stage.
        stage.
        return false.
    }).
	el["addEvent"]({ return ship:altitude > 50000. }, {
		print "Dropping fairings".
		safeactivate("LESTower").
	    dropFairings().
        el["rmEvent"](abortEvent).
	}).
    el["waitCond"]({ return ship:airspeed > 80. }).
    lock steering to heading(hdg, 82).
    el["waitCond"]({ return ship:airspeed > 160. }).
    lock steering to ship:srfprograde.
    el["waitCond"]({ return ship:altitude > 37000. }).
    lock steering to ship:prograde.
    el["waitCond"]({ return ship:apoapsis > orbAlt * 1000. }).
	print "Reached targeted apoapsis".
	lock throttle to 0.
	addnode(orbAlt).
    el["waitTime"](1).
    doNodeDV(el, ship:partstagged("2ndStageEngines")).
}

// Launch on AG1
el["waitCond"]({ return ag1. }).
launchSequence(90, 100).
el["waitCond"]({ return false. }).
