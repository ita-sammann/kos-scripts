@lazyglobal off.

local wd is scriptpath():combine("..").

// Copy all files from archive
//copypath("0:/lib/libstd.ks", "").
copypath(wd:combine("main.ks"), "").

// Source libraries
runoncepath("archive:/lib/libstd.ks").

// Run main script
runpath("main.ks").
