function response = computeArrayResponse3D(antennaCoordinates,arrayCenter,direction,cfg)
%COMPUTEARRAYRESPONSE3D Physical-coordinate ULA response (N_AP x 1).
relative = antennaCoordinates-arrayCenter;
phaseOffset = relative*direction(:);
response = exp(-1j*2*pi/cfg.lambda*phaseOffset);
response = response(:);
end
