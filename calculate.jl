# be sure they are installed Pkg.add
using Random, Distributions, StatsBase, Plots;

Random.seed!(123)

function cost_calculation_rds_postgres_per_user(v_invocations, v_gb)
    out_costs = 0.09 
    storage_cost = 0.23
    out_costs_per_user = out_costs * v_gb * v_invocations + storage_cost * v_gb
end

function cost_calculation_rds_postgres(v_invocations, v_gb)
    user_costs = cost_calculation_rds_postgres_per_user.(v_invocations, v_gb)
    backup_costs = sum(v_gb) * 0.010 +  sum(v_gb) * 0.022 # s3 1 backup 
    backup_costs + sum(user_costs)
end

function cost_calculation_s3(v_invocations, v_gb)
    storage_costs = sum(v_gb) * 0.023
    post_cost = length(v_gb) * 0.005 / 1000 * 31 * 1 # once per day store day transaction file
    select_costs = length(v_gb) * v_invocations * 0.0004 / 1000
    storage_costs + post_cost + select_costs
end

function gb_dist(users)
    data_distribution = SkewNormal(2.0, 3.0, 6.0)
    #plot(x->pdf(data_distribution,x+4))
    sample_values = rand(data_distribution, users)
    dt = fit(UnitRangeTransform, sample_values, dims = 1)
    # normalise 0:1
    StatsBase.transform(dt, sample_values)
end

max_users= 100000
v_gb = 0.0001 .+ gb_dist(max_users) .* 1.5;    # Distribution 100kb -> 1.5 Gb
v_invocations = 1 # download

u=1000
p,s = cost_calculation_rds_postgres(v_invocations, v_gb[1:u]), cost_calculation_s3(v_invocations, v_gb[1:u])
  
