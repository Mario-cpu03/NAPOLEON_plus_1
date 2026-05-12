function envIdx = env_to_idx(envName)
% creating different environments indeces. The scope is to align the
% strings defining the environments to the cell based access to the bank of
% channels.
switch string(envName)
    case "Urban"
        envIdx = 1;

    case "Suburban"
        envIdx = 2;

    case "Village"
        envIdx = 3;

    case "RuralWooded"
        envIdx = 4;
end

end