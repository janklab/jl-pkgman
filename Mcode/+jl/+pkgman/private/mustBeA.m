function mustBeA(value, type)

if ~isa(value, type)
    error('Input must be a %s, but got a %s', type, class(value));
end
