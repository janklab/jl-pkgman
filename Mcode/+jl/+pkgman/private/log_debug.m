function log_debug(fmt, varargin)
jl.pkgman.internal.Logger.instance.debug(fmt, varargin{:});
end