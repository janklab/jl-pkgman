classdef Receipt
    
    properties
        installDate
        pkgDefinition
    end
    
    methods (Static)
        function out = parseJson(jsonText)
            j = jsondecode(jsonText);
            out = jl.pkgman.internal.Receipt;
            out.installDate = j.installDate;
            out.pkgDefinition = jl.pkgman.internal.PkgVerDefinition.parseJson(...
                jsonencode(j.pkgDefinition));
        end
    end
end