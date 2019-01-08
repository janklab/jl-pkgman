function mymovefile(source, destination)

[ok,msg,msgid] = movefile(source, destination);
if ~ok
    error('Failed moving file "%s" to "%s": %s', source, ...
        destination, msg);
end