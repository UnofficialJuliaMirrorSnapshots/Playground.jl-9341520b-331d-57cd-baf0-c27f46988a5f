"""
    create(; kwargs...)
    create(config::Config, args...; kwargs...)
    create(env::Environment; kwargs...)

Creates a new playground `Environment` including initializing its package directory and installing
any package in the REQUIRE file passed in.

# Optional Arguments
You can optionally pass in an `Environment` instance of a `Config` and args to build one.

# Keywords Arguments
* `julia::AbstractString` - a julia binary to use in this playground environment.
* `reqs_file::AbstractPath` - path to a REQUIRE file of packages to install in this environment.
* `registry::AbstractString` - url to the package registry to be cloned.
* `branch::AbstractString` - registry branch to be checked out.
"""
create(; kwargs...) = create(Environment(); kwargs...)
create(config::Config, args...; kwargs...) = create(Environment(config, args...); kwargs...)

function create(env::Environment; kwargs...)
    debug(logger, "Environment Config: $(env.config)")
    init(env)
    opts = Dict(kwargs)

    julia_exec = if haskey(opts, :julia) && !isempty(opts[:julia])
        join(env.config.bin, opts[:julia])
    else
        join(Path(Base.JULIA_HOME), p"julia")
    end

    debug(logger, "$(julia(env)) -> $julia_exec")
    symlink(julia_exec, julia(env), exist_ok=true, overwrite=true)

    withenv(env) do
        registry = if isempty(get(opts, :registry, ""))
            env.config.default_registry
        else
            opts[:registry]
        end
        branch = if isempty(get(opts, :branch, ""))
            env.config.default_branch
        else
            opts[:branch]
        end
        init_cmd = "Pkg.init(\"$registry\", \"$branch\")"
        Playground.log_output(`$(julia(env)) -e $init_cmd`)

        reqs_file = if haskey(opts, :reqs_file) && !isempty(opts[:reqs_file])
            opts[:reqs_file]
        else
            join(env.config.root, "REQUIRE")
        end

        if exists(reqs_file)
            info(logger, "Installing packages from REQUIRE file $reqs_file...")

            for v in readdir(pkg(env))
                copy(reqs_file, join(pkg(env), v, "REQUIRE"); exist_ok=true, overwrite=true)

                try
                    Playground.log_output(`$(julia(env)) -e 'Pkg.resolve()'`)
                catch
                    warn(logger, string(
                        "Failed to resolve requirements. ",
                        "Perhaps there is something wrong with your REQUIRE file."
                    ))
                end
            end
        end
    end
end
