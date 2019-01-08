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
            out = fullfile(this.path, 'metadata');
        end
        
        function out = get.pkgsDir(this)
            out = fullfile(this.path, 'pkgs');
        end
        
        function out = get.tapsDir(this)
            out = fullfile(this.path, 'taps');
        end
        
        function out = cacheDir(this, cacheName)
            if nargin == 1
                out = fullfile(this.path, 'caches');
            else
                out = fullfile(this.path, 'caches', cacheName);
            end
        end
        
        function out = defnFileForPkgVer(this, pkgSpec)
            out = sprintf('%s/pkgs/%s/%s-%s.json', ...
                this.metadataDir, pkgSpec.name, pkgSpec.name, pkgSpec.version);
        end
        
        function out = installDirForPkgVer(this, pkgSpec)
            out = sprintf('%s/%s/%s', ...
                this.pkgsDir, pkgSpec.name, pkgSpec.version);
        end
        
        function out = hasPkgVerDefinition(this, pkgSpec)
            file = this.defnFileForPkgVer(pkgSpec);
            out = exist(file, 'file');
        end

        function out = getPkgVerDefinition(this, pkgSpec)
            file = this.defnFileForPkgVer(pkgSpec);
            if exist(file, 'file')
                out = jl.pkgman.internal.PkgVerDefinition.readFromJson(file);
                return;
            end
            % TODO: Search taps
            error('No definition found for %s in repo %s', ...
                dispstr(pkgSpec), this.name);
        end
        
        function install(this, pkgDefn)
            %INSTALL Install a requested package
            mustBeA(pkgDefn, 'jl.pkgman.internal.PkgVerDefinition');
            
            % Download
            distFile = this.cachedDownload(pkgDefn);
            % Prep dirs
            pkgDestDir = [this.pkgsDir '/' pkgDefn.name '/' pkgDefn.version.str];
            mymkdir(pkgDestDir);
            contentsDir = [pkgDestDir '/contents'];
            if exist(contentsDir, 'dir')
                log_warn('%s %s is already installed', pkgDefn.name, pkgDefn.version);
                return;
            end
            mymkdir(contentsDir);
            try
                % Extract
                this.extractToDir(distFile, contentsDir, pkgDefn);
                % Build
                this.build(pkgDefn, pkgDestDir, contentsDir);
                % Detect Mcode and Java paths
                effPkgDefn = this.detectPkgPaths(pkgDefn, contentsDir);
                % Write receipt
                this.writeReceipt(effPkgDefn, pkgDestDir);
            catch err
                % TODO: Remove bad installation directory
                rethrow(err);
            end
            log_info('Installed %s %s', pkgDefn.name, pkgDefn.version);
        end

        function out = cachedDownload(this, pkgDefn)
            %CACHEDDOWNLOAD Download a package's distribution file, caching
            url = pkgDefn.url;
            extn = this.sniffDownloadExtensionFromUrl(url);
            name = pkgDefn.name; %#ok<*PROPLC>
            ver = pkgDefn.version;
            baseFile = sprintf('%s-%s%s', name, ver.str, extn);
            cacheDlDir = [this.cacheDir '/pkg-downloads'];
            mymkdir(cacheDlDir);
            cacheFile = [cacheDlDir '/' baseFile];
            if exist(cacheFile, 'file')
                log_info('Already downloaded: %s', cacheFile);
                out = cacheFile;
                return;
            end
            log_info('Downloading: %s', url);
            tempFile = [cacheFile '.' num2str(randi(10^10)) '.tmp'];
            websave(tempFile, url);
            mymovefile(tempFile, cacheFile);
            out = cacheFile;
        end
        
        function extractToDir(this, archiveFile, targetDir, pkgDefn)
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
            % Hoist single-subdir contents
            if pkgDefn.hoistSingleDir
                d = mydir(targetDir);
                if isscalar(d) && d.isdir
                    subDirName = d.name;
                    subDir = [targetDir '/' subDirName];
                    d = mydir(subDir);
                    for i = 1:numel(d)
                        movefile([subDir '/' d(i).name], targetDir);
                    end
                    rmdir(subDir);
                end
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
            out = regexpi(url, '\.tgz$|\.tar\.gz$|\.zip$', 'match');
            if isempty(out)
                error('Unable to determine archive file extension from URL: "%s"', ...
                    url);
            end
            out = lower(out{1});
            if isequal(out, '.tgz')
                out = '.tar.gz';
            end
        end
        
        function writeReceipt(this, effPkgDefn, pkgDestDir)
            receipt = jl.pkgman.internal.Receipt;
            timestamp = mylocaltime();
            receipt.installDate = sprintf('%s %s', ...
                datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), timestamp.TimeZone);
            receipt.pkgDefinition = effPkgDefn;
            receiptFile = [pkgDestDir '/RECEIPT.json'];
            jsonText = jsonencode(receipt);
            jl.pkgman.internal.spew(receiptFile, jsonText);
        end
        
        function out = hasPkgInstalled(this, pkgSpec)
            installDir = this.installDirForPkgVer(pkgSpec);
            out = exist(installDir, 'dir');
        end
        
        function loadPackage(this, pkgSpec)
            if ~this.hasPkgInstalled(pkgSpec)
                error('Package %s is not installed in repo %s', ...
                    pkgSpec, this.name);
            end
            % Get receipt from installation
            installDir = this.installDirForPkgVer(pkgSpec);
            contentsDir = [installDir '/contents'];
            receiptFile = [installDir '/RECEIPT.json'];
            receiptText = jl.pkgman.internal.slurp(receiptFile);
            receipt = jl.pkgman.internal.Receipt.parseJson(receiptText);
            pkgDefn = receipt.pkgDefinition;
            % Add paths
            for i = 1:numel(pkgDefn.mcodePaths)
                addpath(fullfile(contentsDir, pkgDefn.mcodePaths{i}));
            end
            for i = 1:numel(pkgDefn.javaPaths)
                javaaddpath(fullfile(contentsDir, pkgDefn.javaPaths{i}));
            end
            % Call custom init code
            if ~isempty(pkgDefn.loadCode)
                origCd = pwd;
                try
                    loadCode = strjoin(pkgDefn.loadCode, '\n');
                    eval(loadCode);
                catch err
                    cd(origCd);
                    rethrow(err);
                end
                cd(origCd);
            end
            log_info('Loaded package %s', pkgSpec);
        end
        
        function removePackage(this, pkgSpec)
            if ~this.hasPkgInstalled(pkgSpec)
                log_warn('Package %s is not installed in repo %s', ...
                    pkgSpec, this.name);
            end
            installDir = this.installDirForPkgVer(pkgSpec);
            rm_rf(installDir);
            log_info('Removed package %s', pkgSpec);
        end
    end
end

function out = mylocaltime
origWarn = warning;
warning off MATLAB:datetime:NonstandardSystemTimeZone
out = datetime('now', 'TimeZone','local');
warning(origWarn);
end