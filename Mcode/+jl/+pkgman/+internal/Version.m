classdef Version
    %VERSION A package version
    %
    % This class supports arbitrary strings as versions, but has special
    % handling for those that look like SemVer or "componenty"/"radixy"
    % versions: those that are a series of dot-separated numbers, maybe with a
    % "-xxx" suffix.
    %
    % Radixy versions can be sorted. Non-radixy ones can't, because
    % lexicographical sorting won't work, and we don't know how to interpret the
    % version string to evaluate relative ordering.
    
    properties
        % The exact version string
        str
    end
    
    methods
        function this = Version(str)
            %VERSION Construct a new Version
            %
            % this = Version(str)
            %
            % Str (char) is the version string.
            mustBeA(str, 'char');
            this.str = str;
        end
        
        function out = char(this)
            out = this.str;
        end
    end
end