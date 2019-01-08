function out = mydir(folder)
out = dir(folder);
names = {out.name};
tf = ismember(names, {'.', '..'});
out(tf) = [];
end