@lazyglobal off.
//clearscreen.

local el is newELoop().

local heatShld is ship:partstagged("heatShld")[0].
local LES is ship:partstagged("LESTower")[0].
local servMod is ship:partstagged("serviceModule")[0].
local fairingAdapter is ship:partstagged("fairingAdapter")[0].
local dockPort is ship:partstagged("dockPort")[0].

local softLandThrusters is ship:partstagged("softLandThrusters").
local fairings is ship:partstagged("fairings").
local landerChutes is ship:partstagged("landerChutes").
local drogueChutes is ship:partstagged("drogueChutes").

function dropHeatShield {
	heatShld:getmodule("ModuleDecouple"):doevent("Jettison heat shield").
}

function fireLandingThrusters {
	for thrst in softLandThrusters {
		thrst:activate.
	}
}

function fireLES {
	parameter hdg is 0.
	LES:getmodule("ModuleRCS"):doevent("enable rcs port").
	rcs on.
	LES:activate.
	lock steering to heading(hdg, 70).
}

function dropFairings {
	for fair in fairings {
		fair:getmodule("ProceduralFairingDecoupler"):doevent("jettison").
	}
	dockPort:getmodule("ModuleDockingNode"):doevent("decouple node").

	rcs off.
	unlock steering.
}

function armChutes {
	for cht in drogueChutes {
		cht:getmodule("RealChuteModule"):doevent("arm parachute").
	}
	for cht in landerChutes {
		cht:getmodule("RealChuteModule"):doevent("arm parachute").
	}
}

function abortSequence {
	servMod:getmodule("ModuleAnimatedDecoupler"):doevent("decouple").
	wait 0.1.
	fireLES(180).

	wait 3.7.
	dropFairings().

	wait until ship:verticalspeed < 0.
}

function landingSequence {
	armChutes().
	wait until ship:altitude < 1000.
	// We are landing on land
	if alt:radar < ship:altitude {
		wait until alt:radar < 250.
		dropHeatShield().
		wait until alt:radar < 2.7.
		fireLandingThrusters().
	// We are landing on water
	} else {
		wait until ship:altitude < 5.
		landerChutes[0]:getmodule("RealChuteModule"):doevent("cut chute").
		landerChutes[1]:getmodule("RealChuteModule"):doevent("cut chute").
	}
}

el["addEvent"]({
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
	stage.
	el["waitTime"](4).
	stage.
	el["waitTime"](5).
	lock steering to heading(hdg, 90).
	el["waitCond"]({ return ship:airspeed > 100. }).
	lock steering to heading(hdg, 85).
	el["waitCond"]({ return ship:airspeed > 200. }).
	lock steering to ship:srfprograde.
	el["waitCond"]({ return ship:altitude > 37000. }).
	lock steering to ship:prograde.
	el["waitCond"]({ return ship:altitude > 45000. }).
	LES:activate.
	dropFairings().
	el["waitCond"]({ return false. }).
}

// Launch on AG1
el["waitCond"]({ return ag1. }).
launchSequence(90, 100).
