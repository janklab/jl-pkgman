classdef PkgVerDefinition
    
    properties
        name
        version
        url
        sha256
        buildCode
        mcodePaths = 'auto'
        javaPaths
        loadCode
    end
    
    methods
        function this = set.mcodePaths(this, in)
            if ~isequal(in, 'auto')
                in = cellstr(in);
            end
            this.mcodePaths = in;
        end
        
        function this = set.javaPaths(this, in)
            if ~isequal(in, 'auto')
                in = cellstr(in);
            end
            this.javaPaths = in;
        end
        
        function this = set.loadCode(this, in)
            if ~isequal(in, 'auto')
                in = cellstr(in);
            end
            this.loadCode = in;
        end
        
        function this = set.buildCode(this, in)
            if ~isequal(in, 'auto')
                in = cellstr(in);
            end
            this.buildCode = in;
        end
        
        function this = set.version(this, in)
            if ~isa(in, 'jl.pkgman.internal.Version')
                in = jl.pkgman.internal.Version(in);
            end
            this.version = in;
        end
        
        function this = set.url(this, in)
            in = char(in);
            this.url = in;
        end
    end
    
    methods (Static)
        function out = readFromJson(file)
            jsonText = jl.pkgman.internal.slurp(file);
            out = jl.pkgman.internal.PkgVerDefinition.parseJson(jsonText);
        end
        
        function out = parseJson(str)
            out = jl.pkgman.internal.PkgVerDefinition;
            j = jsondecode(str);
            fields = {'name' 'version' 'url' 'sha256' 'buildCode' 'mcodePaths', ...
                'javaPaths'};
            for i = 1:numel(fields)
                if isfield(j, fields{i})
                    out.(fields{i}) = j.(fields{i});
                end
            end
            if ~isempty(out.buildCode)
                out.buildCode = cellstr(out.buildCode);
            end
            if ~isempty(out.javaPaths)
                out.javaPaths = cellstr(out.javaPaths);
            end
        end
        
    end
    
end