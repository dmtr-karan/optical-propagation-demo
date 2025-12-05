function N_f = fresnel_number_criterion(lambda, prop_dist, aperture_radius)
%FRESNEL_NUMBER_CRITERION  Check validity of Fresnel number for propagation.
%
%   N_f = FRESNEL_NUMBER_CRITERION(lambda, prop_dist, aperture_radius)
%
%   Computes the Fresnel number
%       N_f = a^2 / (lambda * z)
%   for a given wavelength lambda, propagation distance prop_dist, and
%   aperture radius aperture_radius. Prints a diagnostic message and
%   returns the computed N_f.
%
%   INPUTS:
%     lambda          - wavelength (m)
%     prop_dist       - propagation distance z (m)
%     aperture_radius - radius a of the aperture (m)
%
%   OUTPUT:
%     N_f             - Fresnel number (dimensionless)

    N_f = (aperture_radius^2) / (lambda * prop_dist);

    if N_f <= 1
        fprintf("Fresnel number: %.4f  (<= 1, propagation in good regime)\n", N_f);
    elseif N_f <= 30
        fprintf("Fresnel number: %.4f  (>1 and <=30, borderline but acceptable)\n", N_f);
    else
        fprintf("Fresnel number: %.4f  (>30, outside reliable Fresnel regime)\n", N_f);
    end
end
