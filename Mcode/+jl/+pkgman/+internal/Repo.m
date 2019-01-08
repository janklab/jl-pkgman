classdef Repo < handle
    %REPO A repository accessible to jl-pkgman on this machine
    %
    % This means a repo that is on the filesystem that this process can see.
    
    properties
        name
        path
    end
    
    properties (Dependent = true)
        metadataDir
        pkgsDir
        tapsDir
    end
    
    methods
        function this = Repo(name, path)
            this.name = name;
            this.path = path;
        end
        
        function out = get.metadataDir(this)
            out = fullfile(this, 'metadata');
        end
        
        function out = get.pkgsDir(this)
            out = fullfile(this, 'pkgs');
        end
        
        function out = get.tapsDir(this)
            out = fullfile(this, 'taps');
        end
        
        function out = cacheDir(this, cacheName)
            if nargin == 1
                out = fullfile(this, 'caches');
            else
                out = fullfile(this, 'caches', cacheName);
            end
        end
        
        function out = defnFileForPkgVer(this, pkgSpec)
            out = sprintf('%s/pkgs/%s/%s-%s.json', ...
                this.metadataDir, pkgSpec.name, pkgSpec.version.str);
        end
        
        function out = getPkgVerDefinition(this, pkgSpec)
            file = sprintf('%s/pkgs/%s/%s-%s.json', ...
                this.metadataDir, pkgSpec.name, pkgSpec.version.str);
            if exist(file, 'file')
                out = this.readPkgVerDefnFromJson(file);
                return;
            end
            % TODO: Search taps
            error('No definition found for %s in repo %s', ...
                dispstr(pkgSpec), this.name);
        end
        
        function install(this, pkgDefn)
            %INSTALL Install a requested package
            
            % Prep dirs
            pkgDestDir = [this.pkgsDir '/' pkgDefn.name '/' pkgDefn.version.str];
            mymkdir(pkgDestDir);
            contentsDir = [pkgDestDir '/contents'];
            mymkdir(contentsDir);
            % Download
            distFile = this.cachedDownload(pkgDefn);
            % Extract
            this.extractToDir(distFile, contentsDir);
            % Build
            this.build(pkgDefn, pkgDestDir, contentsDir);
            % Detect Mcode and Java paths
            effPkgDefn = this.detectPkgPaths(pkgDefn);
            % Write receipt
            this.writeReceipt(effPkgDefn, pkgDestDir);
            fprintf('Installed %s %s\n', pkgDefn.name, pkgDefn.version);
        end

        function out = cachedDownload(this, pkgDefn)
            %CACHEDDOWNLOAD Download a package's distribution file, caching
            url = pkgDefn.url;
            extn = this.sniffDownloadExtensionFromUrl(url);
            name = pkgDefn.name; %#ok<*PROPLC>
            ver = pkgDefinition.version;
            baseFile = sprintf('%s-%s.%s', name, ver.str, extn);
            cacheDlDir = [this.cacheDir '/pkg-downloads'];
            cacheFile = [cacheDlDir '/' baseFile];
            if exist(cacheFile, 'file')
                out = cacheFile;
                return;
            end
            tempFile = [cacheFile '.' num2str(randi(10^10)) '.tmp'];
            websave(tempFile, url);
            mymovefile(tempFile, cacheFile);
            out = cacheFile;
        end
        
        function extractToDir(this, archiveFile, targetDir)
            extn = this.sniffDownloadExtensionFromUrl(archiveFile);
            switch extn
                case '.tar.gz'
                    tempDir = tempname;
                    gunzip(archiveFile, tempDir);
                    [~,tarFileBase] = fileparts(archiveFile);
                    tarFile = [tempDir '/' tarFileBase];
                    untar(tarFile, targetDir);
                case '.zip'
                    unzip(archiveFile, targetDir);
                otherwise
                    error('Unsupported archive file format: %s', extn);
            end
            
        end
        
        function build(this, pkgDefn, pkgDestDir, contentsDir)
            if isempty(pkgDefn.buildCode)
                return
            end
            origCd = pwd;
            try
                cd(contentsDir);
                buildCode = strjoin(pkgDefn.buildCode, sprintf('\n'));
                eval(buildCode);
            catch err
                cd(origCd);
                rethrow(err);
            end
        end

        function out = detectPkgPaths(this, pkgDefn, contentsDir)
            out = pkgDefn;
            if isequal(pkgDefn.mcodePaths, 'auto')
                candidates = {
                    '.'
                    'Mcode'
                    'src'
                    };
                found = {};
                for i = 1:numel(candidates)
                    candidate = candidates{i};
                    cPath = [contentsDir '/' candidate];
                    if ~exist(cPath, 'dir')
                        continue;
                    end
                    d = dir([cPath '/*.m']);
                    if ~isempty(d)
                        found{end+1} = candidate; %#ok<*AGROW>
                    end
                end
                out.mcodePaths = found;
            end
        end
        
        function out = sniffDownloadExtensionFromUrl(this, url) %#ok<*INUSL>
            out = regexpi(url, '\.tar\.gz$|\.zip$', 'match');
            if isempty(out)
                error('Unable to determine archive file extension from URL: "%s"', ...
                    url);
            end
            out = lower(out);
        end
        
        function writeReceipt(this, effPkgDefn, pkgDestDir)
            receipt = jl.pkgman.internal.Receipt;
            timestamp = mylocaltime();
            receipt.installDate = sprintf('%s %s', ...
                datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), timestamp.TimeZone);
            receiptFile = [pkgDestDir '/RECEIPT.json'];
            jsonText = jsonencode(receipt);
            jl.pkgman.internal.spew(receiptFile, jsonText);
        end
    end
end

function out = mylocaltime
origWarn = warning;
warning off MATLAB:datetime:NonstandardSystemTimeZone
out = datetime('now', 'TimeZone','local');
warning(origWarn);
end