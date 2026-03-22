#=
Deterministic, mass-action ODE model of levensucrase kinetics
=#
using Pkg
Pkg.activate("/home/s2688039/Documents/Waddington-Supreme-Edi-BioHackathon26/src/MM_enzyme_model/massActionModel");
using Sundials
using ModelingToolkit
using DiffEqBase
using DiffEqBase.EnsembleAnalysis
using JumpProcesses
using DifferentialEquations
using Plots;
using Statistics;
using Catalyst;

#=
Defining the reaction network with max levan length set to 20

SPECIES:
- S: sucrase
- LS: levansucrase
- G: glucose
- F: fructose
- FLS: fructose-levansucrase complex
- L(i): levan strand of length i
=#
rn = @reaction_network begin
    k1, S + LS --> G + FLS
    k2, FLS --> F + LS

    k3, FLS + S --> L1 + LS
    k3, FLS + F --> L1 + LS

    k4, FLS + L1 --> L2 + LS
    k5, L2 + LS --> L1 + FLS
    
    k4, FLS + L2 --> L3 + LS
    k5, LS + L3 --> L2 + FLS

    k4, FLS + L3 --> L4 + LS
    k5, LS + L4 --> L3 + FLS

    k4, FLS + L4 --> L5 + LS
    k5, LS + L5 --> L4 + FLS

    k4, FLS + L5 --> L6 + LS
    k5, LS + L6 --> L5 + FLS

    k4, FLS + L6 --> L7 + LS
    k5, LS + L7 --> L6 + FLS

    k4, FLS + L7 --> L8 + LS
    k5, LS + L8 --> L7 + FLS

    k4, FLS + L8 --> L9 + LS
    k5, LS + L9 --> L8 + FLS

    k4, FLS + L9 --> L10 + LS
    k5, LS + L10 --> L9 + FLS

    k4, FLS + L10 --> L11 + LS
    k5, LS + L11 --> L10 + FLS

    k4, FLS + L11 --> L12 + LS
    k5, LS + L12 --> L11 + FLS

    k4, FLS + L12 --> L13 + LS
    k5, LS + L13 --> L12 + FLS

    k4, FLS + L13 --> L14 + LS
    k5, LS + L14 --> L13 + FLS

    k4, FLS + L14 --> L15 + LS
    k5, LS + L15 --> L14 + FLS

    k4, FLS + L15 --> L16 + LS
    k5, LS + L16 --> L15 + FLS

    k4, FLS + L16 --> L17 + LS
    k5, LS + L17 --> L16 + FLS

    k4, FLS + L17 --> L18 + LS
    k5, LS + L18 --> L17 + FLS

    k4, FLS + L18 --> L19 + LS
    k5, LS + L19 --> L18 + FLS

    k4, FLS + L19 --> L20 + LS
end;

#= 
Setting parameters and run time

HYPERPARAMETERS:
- tEnd: compute solutions on the time interval [0,tEnd]
- dt: increment in time while solving DEs
- ics: initial conditons for each species
- params: rates in reaction model
=#
tEnd = 1000;
dt = 0.01;
ics = [:S=>12000, :LS=>0.17, :G=>0, :FLS=>0, :F=>0, :L1=>0, :L2=>0, :L3=>0, :L4=>0, :L5=>0, :L6=>0, :L7=>0, :L8=>0, :L9=>0, :L10=>0, :L11=>0, :L12=>0, :L13=>0, :L14=>0, :L15=>0, :L16=>0, :L17=>0, :L18=>0, :L19=>0, :L20=>0];
params = [:k1=>100, :k2=>12.5, :k3=>2.5, :k4=>70, :k5=>1];

#= 
Solving of ODEs
=#
tSpan = (0.0, tEnd);
oprob = ODEProblem(rn, ics, tSpan, params);
sol = solve(oprob, CVODE_BDF(), saveat=dt);

#=
Plot of desired species' trajectory
=#
species = "S";
ind = findfirst(x -> string(x)[1:end-3] == species,species(rn));
plot(sol.t, sol[ind,:])