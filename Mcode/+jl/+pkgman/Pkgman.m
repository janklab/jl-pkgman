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
        
        function load(this, pkgVerSpec)
            %LOAD Load an installed package
            for i = 1:numel(this.world.repoOrder)
                repoName = this.world.repoOrder{i};
                repo = this.world.getRepo(repoName);
                if repo.hasPkgInstalled(pkgVerSpec)
                    repo.loadPackage(pkgVerSpec);
                    return;
                end
            end
            error('Could not find package %s installed', pkgVerSpec);
        end
        
        function remove(this, pkgVerSpec)
            %REMOVE Remove an installed package
            found = false;
            for i = 1:numel(this.world.repoOrder)
                repoName = this.world.repoOrder{i};
                repo = this.world.getRepo(repoName);
                if repo.hasPkgInstalled(pkgVerSpec)
                    repo.removePackage(pkgVerSpec);
                    found = true;
                end
            end
            if ~found
                log_info('Package %s is not installed', pkgVerSpec);
            end
        end
        
    end
end
