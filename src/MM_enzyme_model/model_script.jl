#=
Levansucrase Reaction Network Model
====================================
Ping-pong mechanism with explicit fructosyl-enzyme intermediate (F-LS).
Levan chain population tracked via moment method (μ₀, μ₁, μ₂).

Reaction network:
  1.  S + LS     → G + F-LS              (sucrose cleavage)
  2.  S + F-LS   → L₁ + LS              (initiation, sucrose acceptor; Glc capped)
  3.  F + F-LS   → L₁ + LS              (initiation, fructose acceptor)
  4a. F-LS + Lₙ  → Lₙ₊₁ + LS           (elongation, β-2,6)
  4b. F-LS + Lₙ  → Lₙ(br) + LS         (branching, β-2,1)
  5.  Lₙ + LS    → Lₙ₋₁ + F-LS         (depolymerisation)
  6.  F-LS       → LS + F               (hydrolysis)

Conservation: [LS] + [F-LS] = E_total
State vector: [S, G, F, F_LS, μ₀, μ₁, μ₂, B]
=#

using DifferentialEquations
using Plots

# ═══════════════════════════════════════════════════════════════
# MODEL PARAMETERS
# ═══════════════════════════════════════════════════════════════

"""
Kinetic parameters for B. subtilis levansucrase at 37°C, pH 6.
All concentrations in M, time in s.
"""
Base.@kwdef struct LevanParams
    # Enzyme
    E_total::Float64 = 1e-6          # Total enzyme concentration [M]

    # Rxn 1: S + LS → G + F-LS (sucrose cleavage)
    k_suc::Float64   = 150.0         # Turnover number [1/s]
    Km_suc::Float64  = 0.025         # Km for sucrose binding to LS [M]

    # Rxn 6: F-LS → LS + F (hydrolysis)
    k_hyd::Float64   = 30.0          # First-order rate constant [1/s]

    # Rxn 2: S + F-LS → L₁ + LS (initiation, sucrose acceptor)
    k_init_suc::Float64  = 20.0      # Turnover number [1/s]
    Km_init_suc::Float64 = 0.05      # Km for sucrose as acceptor [M]

    # Rxn 3: F + F-LS → L₁ + LS (initiation, fructose acceptor)
    k_init_fru::Float64  = 5.0       # Turnover number [1/s]
    Km_init_fru::Float64 = 0.10      # Km for fructose as acceptor [M]

    # Rxn 4a: F-LS + Lₙ → Lₙ₊₁ + LS (elongation, β-2,6)
    k_elong::Float64  = 80.0         # Turnover number [1/s]
    Km_elong::Float64 = 0.01         # Km for chain NRE as acceptor [M]

    # Rxn 4b: F-LS + Lₙ → Lₙ(br) + LS (branching, β-2,1)
    k_branch::Float64  = 5.0         # Turnover number [1/s]
    Km_branch::Float64 = 0.02        # Km for internal units as acceptor [M]

    # Rxn 5: Lₙ + LS → Lₙ₋₁ + F-LS (depolymerisation)
    k_depol::Float64  = 2.0          # Turnover number [1/s]
    Km_depol::Float64 = 0.005        # Km for chain binding [M]

    # Branching regulators
    n_thresh::Float64    = 5.0        # DP threshold for branching activation
    beta_max::Float64    = 0.15       # Maximum branch fraction (β-2,1 linkages)

    # Temperature / pH effects
    T::Float64       = 310.15         # Temperature [K]
    pH::Float64      = 6.0            # pH
    E_a::Float64     = 45000.0        # Activation energy [J/mol]
    T_ref::Float64   = 310.15         # Reference temperature [K]
    pH_opt::Float64  = 6.0            # Optimal pH
    pH_width::Float64 = 1.5           # pH bell-curve width
end

"Arrhenius temperature correction factor."
function temp_factor(p::LevanParams)
    R = 8.314
    abs(p.T - p.T_ref) < 0.01 && return 1.0
    return exp(-p.E_a / R * (1.0 / p.T - 1.0 / p.T_ref))
end

"Gaussian pH activity factor."
function ph_factor(p::LevanParams)
    return exp(-0.5 * ((p.pH - p.pH_opt) / p.pH_width)^2)
end

"Combined environmental correction factor."
env_factor(p::LevanParams) = temp_factor(p) * ph_factor(p)

# ═══════════════════════════════════════════════════════════════
# INITIAL CONDITIONS
# ═══════════════════════════════════════════════════════════════

"""
Initial concentrations [M] and simulation settings.
"""
Base.@kwdef struct LevanConditions
    S_0::Float64     = 0.5            # Initial sucrose [M]
    G_0::Float64     = 0.0            # Initial glucose [M]
    F_0::Float64     = 0.0            # Initial free fructose [M]
    FLS_0::Float64   = 0.0            # Initial fructosyl-enzyme [M]
    mu0_0::Float64   = 0.0            # Initial chain count [M]
    mu1_0::Float64   = 0.0            # Initial levan mass (fru units) [M]
    mu2_0::Float64   = 0.0            # Initial second moment [M·DP²]
    B_0::Float64     = 0.0            # Initial branch points [M]
    t_end::Float64   = 3600.0         # Simulation end time [s]
end

"Pack initial conditions into a state vector."
function initial_state(c::LevanConditions)
    return [c.S_0, c.G_0, c.F_0, c.FLS_0,
            c.mu0_0, c.mu1_0, c.mu2_0, c.B_0]
end

# State vector indices
const iS    = 1
const iG    = 2
const iF    = 3
const iFLS  = 4
const iMU0  = 5
const iMU1  = 6
const iMU2  = 7
const iB    = 8

# ═══════════════════════════════════════════════════════════════
# ODE SYSTEM
# ═══════════════════════════════════════════════════════════════

"""
    levan_ode!(du, u, p, t)

Right-hand side of the levansucrase ODE system.

State vector u = [S, G, F, F_LS, μ₀, μ₁, μ₂, B]
Parameters p = LevanParams struct
"""
function levan_ode!(du, u, p::LevanParams, t)
    # Unpack state (clamp non-negative)
    S    = max(u[iS],   0.0)
    G    = max(u[iG],   0.0)
    F    = max(u[iF],   0.0)
    FLS  = max(u[iFLS], 0.0)
    mu0  = max(u[iMU0], 0.0)
    mu1  = max(u[iMU1], 0.0)
    mu2  = max(u[iMU2], 0.0)
    B    = max(u[iB],   0.0)

    # Derived quantities
    LS       = max(p.E_total - FLS, 0.0)    # Free enzyme (conservation law)
    nre      = mu0                            # Non-reducing ends (one per chain)
    dp_avg   = mu0 > 1e-15 ? mu1 / mu0 : 2.0
    internal = max(mu1 - mu0, 0.0)           # Internal fru units (branching sites)

    # Environmental correction
    env = env_factor(p)

    # ── Reaction rates ──────────────────────────────────────

    # Rxn 1: S + LS → G + F-LS  (sucrose cleavage)
    v1 = env * p.k_suc * LS * S / (p.Km_suc + S)

    # Rxn 2: S + F-LS → L₁ + LS  (initiation, sucrose acceptor)
    v2 = env * p.k_init_suc * FLS * S / (p.Km_init_suc + S)

    # Rxn 3: F + F-LS → L₁ + LS  (initiation, fructose acceptor)
    v3 = F > 1e-15 ? env * p.k_init_fru * FLS * F / (p.Km_init_fru + F) : 0.0

    # Rxn 4a: F-LS + Lₙ → Lₙ₊₁ + LS  (elongation, β-2,6)
    v4 = nre > 1e-15 ? env * p.k_elong * FLS * nre / (p.Km_elong + nre) : 0.0

    # Rxn 4b: F-LS + Lₙ → Lₙ(br) + LS  (branching, β-2,1)
    current_bf = mu1 > 1e-15 ? B / mu1 : 0.0
    f_sat = max(0.0, 1.0 - current_bf / p.beta_max)
    f_dp  = 1.0 / (1.0 + exp(-(dp_avg - p.n_thresh)))
    v4b = internal > 1e-15 ?
        env * p.k_branch * f_dp * f_sat * FLS * internal / (p.Km_branch + internal) : 0.0

    # Rxn 5: Lₙ + LS → Lₙ₋₁ + F-LS  (depolymerisation)
    v5 = mu0 > 1e-15 ? env * p.k_depol * LS * mu0 / (p.Km_depol + mu0) : 0.0

    # Rxn 6: F-LS → LS + F  (hydrolysis)
    v6 = env * p.k_hyd * FLS

    # Total new chain initiation rate
    v_new = v2 + v3

    # ── ODEs ────────────────────────────────────────────────

    # dS/dt: consumed by cleavage (rxn 1) and as acceptor (rxn 2)
    du[iS] = -v1 - v2

    # dG/dt: produced only by sucrose cleavage (rxn 1)
    # Glucose from acceptor sucrose in rxn 2 is capped in chain
    du[iG] = v1

    # dF/dt: produced by hydrolysis (rxn 6), consumed as acceptor (rxn 3)
    du[iF] = v6 - v3

    # d[F-LS]/dt: loaded by rxn 1 & 5, unloaded by rxn 2,3,4,4b,6
    du[iFLS] = v1 + v5 - v2 - v3 - v4 - v4b - v6

    # dμ₀/dt: chains created by initiation, never destroyed
    du[iMU0] = v_new

    # dμ₁/dt: +1 per elong, +1 per branch, +2 per new chain, −1 per depol
    du[iMU1] = v4 + v4b + 2.0 * v_new - v5

    # dμ₂/dt: mean-field moment closure
    n_bar = dp_avg > 0.0 ? dp_avg : 2.0
    du[iMU2] = (2.0 * n_bar + 1.0) * (v4 + v4b) +
               4.0 * v_new -
               (2.0 * n_bar - 1.0) * v5

    # dB/dt: branch points only created, never removed
    du[iB] = v4b

    return nothing
end

# ═══════════════════════════════════════════════════════════════
# SOLVE
# ═══════════════════════════════════════════════════════════════

"""
    solve_levan(params, conditions; kwargs...)

Solve the levansucrase ODE system.
Returns an ODE solution object.
"""
function solve_levan(params::LevanParams = LevanParams(),
                     conditions::LevanConditions = LevanConditions();
                     solver = Tsit5(),
                     reltol = 1e-8,
                     abstol = 1e-12)

    u0   = initial_state(conditions)
    tspan = (0.0, conditions.t_end)

    prob = ODEProblem(levan_ode!, u0, tspan, params)
    sol  = solve(prob, solver; reltol, abstol, maxiters = 1_000_000)

    return sol
end

# ═══════════════════════════════════════════════════════════════
# DERIVED QUANTITIES
# ═══════════════════════════════════════════════════════════════

"Number-average degree of polymerisation."
dp_avg(sol, i) = sol[iMU0, i] > 1e-15 ? sol[iMU1, i] / sol[iMU0, i] : 0.0

"Polydispersity index."
function pdi(sol, i)
    mu0, mu1, mu2 = sol[iMU0, i], sol[iMU1, i], sol[iMU2, i]
    mu1 > 1e-15 ? mu2 * mu0 / mu1^2 : 1.0
end

"Branch fraction (β-2,1 linkages)."
branch_frac(sol, i) = sol[iMU1, i] > 1e-15 ? sol[iB, i] / sol[iMU1, i] : 0.0

"Levan yield (fraction of initial sucrose fru units in polymer)."
levan_yield(sol, i, S0) = S0 > 0.0 ? sol[iMU1, i] / S0 : 0.0

"Free enzyme concentration."
ls_free(sol, i, E_total) = E_total - sol[iFLS, i]

# ═══════════════════════════════════════════════════════════════
# PLOTTING
# ═══════════════════════════════════════════════════════════════

"""
    plot_results(sol, params, conditions; save_dir="plots")

Generate all diagnostic plots for the simulation.
"""
function plot_results(sol, params::LevanParams, conditions::LevanConditions;
                      save_dir = "plots")

    mkpath(save_dir)

    t_min = sol.t ./ 60.0  # Convert to minutes
    n = length(sol.t)
    S0 = conditions.S_0

    # Extract time series (in mM for concentrations)
    S_mM    = sol[iS, :]   .* 1000
    G_mM    = sol[iG, :]   .* 1000
    F_mM    = sol[iF, :]   .* 1000
    FLS_uM  = sol[iFLS, :] .* 1e6
    LS_uM   = [ls_free(sol, i, params.E_total) * 1e6 for i in 1:n]
    mu1_mM  = sol[iMU1, :] .* 1000
    dp_arr  = [dp_avg(sol, i) for i in 1:n]
    pdi_arr = [pdi(sol, i) for i in 1:n]
    bf_arr  = [branch_frac(sol, i) .* 100 for i in 1:n]
    yield_arr = [levan_yield(sol, i, S0) .* 100 for i in 1:n]

    # ── Plot 1: Concentration time courses ──────────────────
    p1 = plot(t_min, S_mM, label = "Sucrose", lw = 2,
              xlabel = "Time [min]", ylabel = "Concentration [mM]",
              title = "Small molecule kinetics")
    plot!(p1, t_min, G_mM, label = "Glucose", lw = 2)
    plot!(p1, t_min, F_mM, label = "Fructose", lw = 2)
    plot!(p1, t_min, mu1_mM, label = "Levan (fru units)", lw = 2.5, ls = :dash)
    savefig(p1, joinpath(save_dir, "01_concentrations.png"))

    # ── Plot 2: Enzyme state ────────────────────────────────
    p2 = plot(t_min, FLS_uM, label = "F-LS (loaded)", lw = 2,
              xlabel = "Time [min]", ylabel = "Concentration [μM]",
              title = "Enzyme partitioning")
    plot!(p2, t_min, LS_uM, label = "LS (free)", lw = 2, ls = :dash)
    savefig(p2, joinpath(save_dir, "02_enzyme_state.png"))

    # ── Plot 3: Average DP and PDI ──────────────────────────
    p3 = plot(t_min, dp_arr, label = "DP (number-avg)", lw = 2.5,
              xlabel = "Time [min]", ylabel = "Degree of polymerisation",
              title = "Chain length evolution",
              legend = :topleft)
    p3b = twinx(p3)
    plot!(p3b, t_min, pdi_arr, label = "PDI", lw = 2, ls = :dash,
          ylabel = "PDI", color = :red, legend = :topright)
    savefig(p3, joinpath(save_dir, "03_dp_pdi.png"))

    # ── Plot 4: Branch fraction ─────────────────────────────
    p4 = plot(t_min, bf_arr, label = "β(2→1) fraction", lw = 2.5,
              xlabel = "Time [min]", ylabel = "Branch linkages [%]",
              title = "Branching", color = :teal)
    savefig(p4, joinpath(save_dir, "04_branching.png"))

    # ── Plot 5: Levan yield ─────────────────────────────────
    p5 = plot(t_min, yield_arr, label = "Levan yield", lw = 2.5,
              xlabel = "Time [min]", ylabel = "Yield [%]",
              title = "Levan yield (fructose basis)", color = :purple,
              ylims = (0, 100))
    savefig(p5, joinpath(save_dir, "05_yield.png"))

    # ── Combined panel ──────────────────────────────────────
    panel = plot(p1, p2, p3, p4, p5,
                 layout = (3, 2), size = (1000, 1200),
                 margin = 5Plots.mm)
    savefig(panel, joinpath(save_dir, "00_summary.png"))

    println("Plots saved to $(save_dir)/")
    return panel
end

# ═══════════════════════════════════════════════════════════════
# MASS BALANCE CHECKS
# ═══════════════════════════════════════════════════════════════

"""
    check_balances(sol, params, conditions)

Print mass balance diagnostics at the final time point.
"""
function check_balances(sol, params::LevanParams, conditions::LevanConditions)
    i = length(sol.t)
    S0 = conditions.S_0

    S    = sol[iS, i]
    G    = sol[iG, i]
    F    = sol[iF, i]
    FLS  = sol[iFLS, i]
    mu0  = sol[iMU0, i]
    mu1  = sol[iMU1, i]
    B    = sol[iB, i]
    LS   = params.E_total - FLS

    # Fructose-unit balance: S₀ = S + F + F_LS + μ₁
    fru_sum = S + F + FLS + mu1
    fru_err = abs(fru_sum - S0) / S0 * 100

    # Enzyme balance: LS + F_LS = E_total
    enz_err = abs(LS + FLS - params.E_total)

    # Glucose balance: S₀ = S + G + N_caps
    N_caps = S0 - S - G

    println("═══════════════════════════════════════════")
    println("  SIMULATION RESULTS (t = $(sol.t[i]/60) min)")
    println("═══════════════════════════════════════════")
    println("  Sucrose:       $(round(S*1000, digits=2)) mM")
    println("  Glucose:       $(round(G*1000, digits=2)) mM")
    println("  Fructose:      $(round(F*1000, digits=2)) mM")
    println("  F-LS:          $(round(FLS*1e6, digits=4)) μM")
    println("  LS (free):     $(round(LS*1e6, digits=4)) μM")
    println("  Levan (μ₁):    $(round(mu1*1000, digits=2)) mM fru units")
    println("  Chains (μ₀):   $(round(mu0*1000, digits=2)) mM")
    println("  Avg DP:        $(round(dp_avg(sol,i), digits=1))")
    println("  PDI:           $(round(pdi(sol,i), digits=3))")
    println("  Branch frac:   $(round(branch_frac(sol,i)*100, digits=2))%")
    println("  Levan yield:   $(round(levan_yield(sol,i,S0)*100, digits=1))%")
    println("  Glc in caps:   $(round(N_caps*1000, digits=2)) mM")
    println("───────────────────────────────────────────")
    println("  Fru balance err:  $(round(fru_err, digits=6))%")
    println("  Enzyme balance:   $(round(enz_err*1e9, digits=6)) nM")
    println("═══════════════════════════════════════════")
end