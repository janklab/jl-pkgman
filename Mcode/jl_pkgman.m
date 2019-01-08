function jl_pkgman(subcmd, varargin)
%JL_PKGMAN Command style interface to jl-pkgman
%
% jl_pkgman <command> [...arguments...]
%
% Usage:
%
%   jl_pkgman install <package> <version>
%

if nargin < 1
    error('<command> is required.');
end

pm = jl.pkgman.Pkgman;

switch subcmd
    case 'install'
        [name,versionStr] = varargin{:};
        version = jl.pkgman.internal.Version(versionStr);
        pkgVer = jl.pkgman.internal.PkgVerSpec(name, version);
        pm.install(pkgVer);
    case 'load'
        [name,versionStr] = varargin{:};
        version = jl.pkgman.internal.Version(versionStr);
        pkgVer = jl.pkgman.internal.PkgVerSpec(name, version);
        pm.load(pkgVer);
    otherwise
        error('Invalid command: %s', subcmd);
end