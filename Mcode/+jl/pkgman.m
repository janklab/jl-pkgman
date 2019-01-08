function pkgman(subcmd, varargin)
%PKGMAN Command style interface to jl-pkgman

pm = jl.pkgman.Pkgman;

switch subcmd
    case 'install'
        [name,versionStr] = varargin{:};
        version = jl.pkgman.internal.Version(versionStr);
        pkgVer = jl.pkgman.internal.PkgVerSpec(name, version);
        pm.install(pkgVer);
    otherwise
        error('Invalid command: %s', subcmd);
end