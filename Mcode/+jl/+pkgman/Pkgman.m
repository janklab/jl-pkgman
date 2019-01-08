classdef Pkgman < handle
    %PKGMAN Overall interface to jl-pkgman
    
    properties
        world = jl.pkgman.internal.World
    end
    
    methods
        function install(this, pkgVerSpec, repoName)
            if nargin < 3; repoName = []; end
            mustBeA(pkgVerSpec, 'jl.pkgman.internal.PkgVerSpec');
            
            % Get definition
            pkgDefn = this.world.getPkgVerDefinition(pkgVerSpec);
            % Do installation
            if isempty(repoName)
                repoName = this.world.defaultRepoName;
            end
            repo = this.world.getRepo(repoName);            
            repo.install(pkgDefn);
        end
        
    end
end
