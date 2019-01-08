function mymkdir(folder)
origWarn = warning;
warning off MATLAB:MKDIR:DirectoryExists
[ok,msg,~] = mkdir(folder);
warning(origWarn);
if ~ok
    error('Failed creating folder "%s": %s', folder, msg);
end
end
