function log_info(fmt, varargin)
jl.pkgman.internal.Logger.instance.info(fmt, varargin{:});
end