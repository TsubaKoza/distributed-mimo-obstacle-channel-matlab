function antennaPos = generateAPArrayPositions(APpos,cfg)
%GENERATEAPARRAYPOSITIONS Return M x N_AP x 3 physical ULA coordinates.
M = size(APpos,1); N = cfg.N_AP;
offset = ((0:N-1)-(N-1)/2)*cfg.arraySpacing;
antennaPos = zeros(M,N,3);
for m = 1:M
    coordinates = APpos(m,:) + offset(:)*cfg.ulaDirection;
    antennaPos(m,:,:) = reshape(coordinates,1,N,3);
end
end
