function out = slurp(file, encoding)
%SLURP Read text from a file
if nargin < 2 || isempty(encoding);  encoding = 'UTF-8'; end
[fid,errmsg] = fopen(file, 'r', 'n', encoding);
if fid < 0
    error('Could not read file %s: %s', file, errmsg);
end
out = fread(fid, '*char');
out = out';
fclose(fid);
end