classdef Logger
    
    properties (Constant)
        instance = jl.pkgman.internal.Logger;
    end
    
    properties
        levelMap = struct(...
            'ERROR', 5, ...
            'WARN',  4, ...
            'INFO',  3, ...
            'DEBUG', 2, ...
            'TRACE', 1);
        currentLevel = 3;
    end
    
    methods
        function error(this, fmt, varargin)
            this.log('ERROR', fmt, varargin{:});
        end
        
        function warn(this, fmt, varargin)
            this.log('WARN', fmt, varargin{:});
        end
        
        function info(this, fmt, varargin)
            this.log('INFO', fmt, varargin{:});
        end
        
        function debug(this, fmt, varargin)
            this.log('DEBUG', fmt, varargin{:});
        end
        
        function trace(this, fmt, varargin)
            this.log('TRACE', fmt, varargin{:});
        end
        
        function log(this, level, fmt, varargin)
            levelValue = this.levelMap.(level);
            if this.currentLevel > levelValue
                return;
            end
            fprintf([fmt sprintf('\n')], varargin{:});
        end
    end
    
end