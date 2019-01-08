classdef SemVerVersion
    %SEMVERVERSION A version specification that follows semver
    %
    % This is based on a modified style of SemVer, in which the Minor and
    % Patch components are not required to be explicitly included in the
    % string form of the version.
    properties (SetAccess = private)
        % The full string that is the package version
        String = ''
        % Whether this version looks like a SemVer version
        IsSemVerish = false
        % The "major" component as double, if SemVer, or NaN otherwise
        Major = NaN
        % The "minor" component as double, if SemVer, or NaN otherwise
        Minor = NaN
        % The "patch" component as double, if SemVer, or NaN otherwise
        Patch = NaN
        % The "prerelease" component as char, if SemVer, or empty otherwise
        PreRelease = []
        % The "build info" component as char, if SemVer, or empty otherwise
        Build = []
        % True for known special versions, like 'HEAD' or 'latest'
        IsSpecial = false
    end
    
    methods
        function this = Version(varargin)
            if nargin == 0
                return
            end
            if nargin == 1
                in = varargin{1};
            end
            if isstring(in)
                in = cellstr(in);
                this = repmat(jl.pkgman.internal.Version, size(in));
                for i = 1:numel(in)
                    this(i) = jl.pkgman.internal.Version.parseVersionStr(in{i});
                end
            end
        end
    end
    
    methods (Static = true)
        function out = parseVersionStr(str)
            out = jl.pkgman.internal.Version;
            out.String = str;
            semver_pat = '^(\d+)(?\.(\d+)(?\.(\d+))?])?([-]\S+)?(\+[0-9A-Za-z-]+)?$';
            match = regexp(str, semver_pat, 'match');
            if isempty(match)
                % Not SemVer
            else
                % Is SemVer
                s = str;
                ix_plus = find(str == '+', 1);
                if ~isempty(ix_plus)
                    out.Build = s(ix_plus+1:end);
                    s = s(1:ix_plus-1);                    
                end
                ix_dash = find(str == '-', 1);
                if ~isempty(ix_dash)
                    out.PreRelease = s(ix_dash+1:end);
                    s = s(1:ix_dash-1);
                end
                str_components = strsplit(
            end
        end
    end
    
end