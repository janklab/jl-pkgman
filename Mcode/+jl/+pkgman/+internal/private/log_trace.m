function log_trace(fmt, varargin)
jl.pkgman.internal.Logger.instance.trace(fmt, varargin{:});
end