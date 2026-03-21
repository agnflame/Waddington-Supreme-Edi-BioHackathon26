#=
run.jl — Solve the levansucrase kinetic model and generate plots.

Usage:
    julia --project=. run.jl

Or from the REPL:
    include("run_script.jl")
=#

include("model_script.jl")
include("plot_chain_stats.jl")

# ═══════════════════════════════════════════════════════════════
# DEFINE PARAMETERS
# ═══════════════════════════════════════════════════════════════

params = LevanParams(
    # Enzyme
    E_total   = 50e-6,          # 1 μM enzyme

    # Rxn 1: sucrose cleavage
    k_suc     = 100.0,         # s⁻¹
    Km_suc    = 0.025,         # M (25 mM)

    # Rxn 6: hydrolysis
    k_hyd     = 5.0,          # s⁻¹    | k2 ()

    # Rxn 2: initiation (sucrose acceptor)
    k_init_suc  = 5.0,        # s⁻¹
    Km_init_suc = 0.05,        # M (50 mM)

    # Rxn 3: initiation (fructose acceptor)
    k_init_fru  = 5.0,         # s⁻¹
    Km_init_fru = 0.2,        # M (100 mM)

    # Rxn 4a: elongation (β-2,6)
    k_elong   = 5.0,          # s⁻¹
    Km_elong  = 0.001,          # M (10 mM)

    # Rxn 4b: branching (β-2,1)
    k_branch  = 1.0,           # s⁻¹
    Km_branch = 0.005,          # M (20 mM)

    # Rxn 5: depolymerisation
    k_depol   = 1.0,           # s⁻¹
    Km_depol  = 0.005,         # M (5 mM)

    # Branching regulators
    n_thresh  = 5.0,           # Min DP for branching
    beta_max  = 0.15,          # Max branch fraction (15%)

    # Environment
    T         = 310.15,        # 37°C
    pH        = 6.0,
)

# ═══════════════════════════════════════════════════════════════
# DEFINE INITIAL CONDITIONS
# ═══════════════════════════════════════════════════════════════

conditions = LevanConditions(
    S_0   = 0.15,               # 12 mM sucrose
    G_0   = 0.03,
    F_0   = 0.03,
    FLS_0 = 0.0,               # No pre-loaded enzyme
    mu0_0 = 0.0,               # No initial chains
    mu1_0 = 0.0,
    mu2_0 = 0.0,
    B_0   = 0.0,               # No initial branches
    t_end = 3600.0,           # time
)

# ═══════════════════════════════════════════════════════════════
# SOLVE
# ═══════════════════════════════════════════════════════════════

println("Solving levansucrase ODE system...")
println("  S₀ = $(conditions.S_0 * 1000) mM sucrose")
println("  E_total = $(params.E_total * 1e6) μM enzyme")
println("  T = $(params.T - 273.15)°C, pH = $(params.pH)")
println()

sol = solve_levan(params, conditions)

println("  ✓ Solved ($(length(sol.t)) time points)")
println()

# ═══════════════════════════════════════════════════════════════
# DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════

check_balances(sol, params, conditions)

# ═══════════════════════════════════════════════════════════════
# PLOTS
# ═══════════════════════════════════════════════════════════════

println("\nGenerating plots...")
plot_results(sol, params, conditions; save_dir = "plots")
plot_chain_statistics(sol, params, conditions)
println("Done!")