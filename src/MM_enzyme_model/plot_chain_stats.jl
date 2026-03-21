#=
plot_chain_stats.jl — Plot levan chain statistics over time.

Drop this into the same directory as model_script.jl and run_script.jl.

Usage (after run_script.jl has defined `sol`, `params`, `conditions`):
    include("plot_chain_stats.jl")
    plot_chain_statistics(sol, params, conditions)

Or standalone:
    include("model_script.jl")
    include("plot_chain_stats.jl")

    params = LevanParams(...)
    conditions = LevanConditions(...)
    sol = solve_levan(params, conditions)
    plot_chain_statistics(sol, params, conditions)
=#

using Plots

function plot_chain_statistics(sol, params::LevanParams, conditions::LevanConditions;
                               save_path = "plots/chain_statistics.png")

    mkpath(dirname(save_path))

    t_min = sol.t ./ 60.0
    n = length(sol.t)
    S0 = conditions.S_0

    # ── Extract chain statistics ─────────────────────────────
    mu0_mM  = sol[iMU0, :] .* 1000
    mu1_mM  = sol[iMU1, :] .* 1000

    dp_arr    = [dp_avg(sol, i) for i in 1:n]
    pdi_arr   = [pdi(sol, i) for i in 1:n]
    bf_arr    = [branch_frac(sol, i) * 100 for i in 1:n]
    yield_arr = [levan_yield(sol, i, S0) * 100 for i in 1:n]

    # Branches per chain
    bpc_arr = [sol[iMU0, i] > 1e-15 ? sol[iB, i] / sol[iMU0, i] : 0.0 for i in 1:n]

    # Average branch spacing (fru units between branches)
    spacing_arr = [bf_arr[i] > 0.1 ? 100.0 / bf_arr[i] : NaN for i in 1:n]

    # Number-average molecular weight (g/mol, anhydrofructose = 162.14)
    mw_arr = dp_arr .* 162.14

    # Weight of levan (mg/mL, assuming 1 L reaction volume)
    # μ₁ [M] × 162.14 [g/mol] = g/L = mg/mL
    levan_mg_mL = sol[iMU1, :] .* 162.14

    # ── Plot ─────────────────────────────────────────────────

    # Panel 1: Chain count and levan mass
    p1 = plot(t_min, mu0_mM, label = "Chains (μ₀)", lw = 2,
              xlabel = "Time [min]", ylabel = "mM",
              title = "Chain population", color = :steelblue)
    p1b = twinx(p1)
    plot!(p1b, t_min, mu1_mM, label = "Levan mass (μ₁)", lw = 2,
          ylabel = "mM fru units", color = :crimson, ls = :dash,
          legend = :right)

    # Panel 2: Average DP
    p2 = plot(t_min, dp_arr, label = "DPₙ", lw = 2.5,
              xlabel = "Time [min]", ylabel = "DP",
              title = "Number-average DP", color = :darkorange)

    # Panel 3: PDI
    p3 = plot(t_min, pdi_arr, label = "PDI", lw = 2.5,
              xlabel = "Time [min]", ylabel = "PDI",
              title = "Polydispersity index", color = :red,
              ylims = (0.9, max(2.5, maximum(filter(!isnan, pdi_arr)) * 1.1)))

    # Panel 4: Branch fraction
    p4 = plot(t_min, bf_arr, label = "β(2→1) %", lw = 2.5,
              xlabel = "Time [min]", ylabel = "Branch linkages [%]",
              title = "Branch fraction", color = :teal)

    # Panel 5: Branches per chain
    p5 = plot(t_min, bpc_arr, label = "Branches/chain", lw = 2.5,
              xlabel = "Time [min]", ylabel = "Count",
              title = "Branches per chain", color = :purple)

    # Panel 6: Molecular weight and yield
    p6 = plot(t_min, mw_arr, label = "Mₙ", lw = 2,
              xlabel = "Time [min]", ylabel = "Mₙ [g/mol]",
              title = "Molecular weight & yield", color = :navy)
    p6b = twinx(p6)
    plot!(p6b, t_min, yield_arr, label = "Yield", lw = 2,
          ylabel = "Yield [%]", color = :green, ls = :dash,
          legend = :right, ylims = (0, 100))

    # Combine
    panel = plot(p1, p2, p3, p4, p5, p6,
                 layout = (3, 2), size = (1000, 1200),
                 margin = 5Plots.mm,
                 plot_title = "Levan chain statistics")

    savefig(panel, save_path)
    println("Chain statistics saved to $(save_path)")

    return panel
end