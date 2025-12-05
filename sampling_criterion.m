function out = sampling_criterion(lambda, prop_dist, L, dx, M)
%SAMPLING_CRITERION  Check sampling condition for scalar propagation.
%
%   out = SAMPLING_CRITERION(lambda, prop_dist, L, dx, M)
%
%   Implements the sampling criterion from Appendix 1 of:
%   D. G. Voelz, "Computational Fourier Optics: A MATLAB Tutorial" (SPIE).
%
%   INPUTS:
%     lambda    - wavelength (m)
%     prop_dist - propagation distance z (m)
%     L         - side length of the initial field window (m)
%     dx        - current sample spacing in the source plane (m), dx = L / M
%     M         - number of samples per dimension
%
%   The function compares dx to the critical sampling interval
%       dx_crit = (lambda * prop_dist) / L
%   and prints a short diagnostic message. It also suggests alternative
%   parameters (prop_dist, L, M) that would satisfy the sampling condition.
%
%   OUTPUT:
%     out =  0  -> critically sampled      (dx == dx_crit)
%           1  -> oversampled             (dx >  dx_crit)
%          -1  -> undersampled            (dx <  dx_crit)
%
%   Notes:
%     - Used mainly for diagnostics in the main demo.
%     - The suggestions printed are indicative values for (z, L, M) that
%       satisfy the sampling criterion.


    dx_crit = (lambda * prop_dist) / L;

    if dx == dx_crit
        fprintf("Sampling criterion: critical (dx = dx_crit).\n");
        out = 0;

    elseif dx > dx_crit
        fprintf("Sampling criterion: oversampled (dx > dx_crit).\n");

        proper_distance = ((L^2) / M) / lambda;
        L_proper        = (lambda * prop_dist) / (dx * M);
        M_proper        = L / dx_crit;

        fprintf(['It is suggested to apply one of the following changes:\n', ...
                 '  - Change propagation distance from z = %g to z = %g\n', ...
                 '  - Change side length from L = %g to L = %g\n', ...
                 '  - Change sampling points from M = %g to M = %g\n'], ...
                 prop_dist, proper_distance, L, L_proper, M, M_proper);

        out = 1;

    elseif dx < dx_crit
        fprintf("Sampling criterion: undersampled (dx < dx_crit).\n");

        proper_distance = ((L^2) / M) / lambda;
        L_proper        = (lambda * prop_dist) / (dx * M);
        M_proper        = L / dx_crit;

        fprintf(['It is suggested to apply one of the following changes:\n', ...
                 '  - Change propagation distance from z = %g to z = %g\n', ...
                 '  - Change side length from L = %g to L = %g\n', ...
                 '  - Change sampling points from M = %g to M = %g\n'], ...
                 prop_dist, proper_distance, L, L_proper, M, M_proper);

        out = -1;

    else
        fprintf("Sampling criterion: unexpected condition (check inputs).\n");
        out = NaN;
    end
end
