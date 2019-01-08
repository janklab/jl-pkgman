function rm_rf(file)
%RM_RF Recursively delete a file or directory

if ispc
    system(sprintf('del /q /s "%s"', file));
else
    [status,~] = system(sprintf('rm -rf "%s"', file));
    if status ~= 0
        error('Failed deleting "%s"', file);
    end
end
    