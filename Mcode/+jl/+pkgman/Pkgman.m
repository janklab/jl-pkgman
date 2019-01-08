classdef Pkgman < handle
    %PKGMAN Overall interface to jl-pkgman
    
    properties
        world = jl.pkgman.internal.World
    end
    
    methods
        function install(this, pkgVerSpec, repoName)
            if nargin < 3; repoName = []; end
            
            if isempty(repoName)
                repoName = this.world.defaultRepoName;
            end
            repo = this.world.getRepo(repoName);
            repo.install(pkgVerSpec);
        end
        
    end
end
