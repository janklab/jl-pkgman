function out = spew(file, data, encoding)
%SPEW Write text to a file
narginchk(2,3);
if nargin < 3 || isempty(encoding);  encoding = 'UTF-8'; end
[fid,errmsg] = fopen(file, 'w', 'n', encoding);
if fid < 0
    error('Could not write file "%s": %s', file, errmsg);
end
out = fwrite(fid, data, '*char');
fclose(fid);
end