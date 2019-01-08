classdef PkgVerSpec
%PKGVERSPEC Specifies an exact PkgVer
%
% This is for use when you're getting the definition for something and need to
% identify an exact PkgVer. This is the most granular that package definitions
% get.

    properties
        name
        version
    end
    
    methods
        function this = PkgVerSpec(name, version)
            this.name = name;
            this.version = jl.pkgman.internal.Version(version);
        end
        
        function disp(this)
            fprintf('%s', dispstr(this));
        end
        
        function out = dispstr(this)
            if ~isscalar(this)
                out = sprintf('%s %s', size2str(size(this)), class(this));
                return;
            end
            out = sprintf('%s %s', this.name, this.version);
        end
    end
    
end
    