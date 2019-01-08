classdef World < handle
    %WORLD The world known to this jl-pkgman
    %
    % This includes all the repos, configuration dirs, cache dirs, commands,
    % and anything else on this system that jl-pkgman might use.
    
    properties
        % All the repos struct<name, repo>
        repos = struct
        % Order of precedence for repos, in descending order
        repoOrder = {};
    end
    
    methods
        function this = World()
            %WORLD Initialize a new World
            
            % Standard taps
            if ispc
                error('Windows is not implemented yet.');
            else
                this.addRepo('user', [getenv('HOME') '/.jl-pkgman']);
                this.addRepo('system', '/usr/local/share/jl-pkgman/repo');
            end
        end
        
        function addRepo(this, name, path)
            if ismember(name, this.repoOrder)
                error('Repo %s is already defined.', name);
            end
            repo = jl.pkgman.internal.Repo(name, path);
            this.repos.(name) = repo;
            this.repoOrder{end+1} = name;
        end
        
        function out = getRepo(this, name)
            if ~ismember(name, this.repoOrder)
                error('Unknown repo: %s.', name);
            end
            out = this.repos.(name);
        end
        
        function removeRepo(this, name)
            if ~ismember(name, fieldnames(this.repos))
                error('No such repo: %s', name);
            end
            this.repos = rmfield(this.repos, name);
            this.repoOrder = setdiff(this.repoOrder, name, 'stable');
        end
        
        function out = userRepo(this)
            if ~ismember('user', this.repoOrder)
                error('No user repo defined.\n');
            end
            out = this.repos.user;
        end
        
        function out = defaultRepoName(this)
            out = this.repoOrder{1};
        end
        
        function out = getPkgVerDefinition(this, pkgSpec)
            for i = 1:numel(this.repoOrder)
                repoName = this.repoOrder{i};
                repo = this.repos.(repoName);
                if repo.hasPkgVerDefinition(pkgSpec)
                    out = repo.getPkgVerDefinition(pkgSpec);
                    return
                end
            end
            error('No definition found for %s', dispstr(pkgSpec));
        end
    end
end