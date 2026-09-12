function gain = computePathGain(pathLength,reflectionCoefficient,cfg)
%COMPUTEPATHGAIN Complex field gain for one propagation path.
% Assumption/Extension: Friis free-space field amplitude is used. For a
% reflected path it is multiplied by a user-configurable complex Gamma.
if pathLength < cfg.minPathLength
    error('Path length %.3g is below the numerical limit.',pathLength);
end
switch lower(char(cfg.pathGainModel))
    case 'friisfield'
        amplitude = cfg.lambda/(4*pi*pathLength);
    otherwise
        error('Unknown pathGainModel: %s',cfg.pathGainModel);
end
gain = reflectionCoefficient*amplitude* ...
    exp(-1j*2*pi*pathLength/cfg.lambda);
end
