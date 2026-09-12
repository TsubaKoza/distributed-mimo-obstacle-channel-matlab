function [lossdB,v] = computeKnifeEdgeDiffractionLoss(h,d1,d2,lambda,cfg)
%COMPUTEKNIFEEDGEDIFFRACTIONLOSS ITU-R P.526 single knife-edge approximation.
% The approximation J(v)=6.9+20log10(sqrt((v-0.1)^2+1)+v-0.1)
% applies for v>-0.78. Here h is a nonnegative perpendicular obstruction
% distance, so v is nonnegative. This returns magnitude loss only; the
% propagation phase is calculated separately from the broken path length.
if h<0 || d1<=cfg.minPathLength || d2<=cfg.minPathLength || lambda<=0
    error('Invalid knife-edge geometry.');
end
v = h*sqrt(2*(d1+d2)/(lambda*d1*d2));
if v<=-0.78
    lossdB=0;
else
    lossdB=6.9+20*log10(sqrt((v-0.1)^2+1)+v-0.1);
end
lossdB=min(max(lossdB,0),cfg.diffractionLossCapdB);
end
