function log_warn(fmt, varargin)
    jl.pkgman.internal.Logger.instance.warn(['WARNING: ' fmt], varargin{:});
end