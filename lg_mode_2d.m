function [phase_out, intensity, lg_complex] = lg_mode_2d(p, l, k, w0, xx, yy)
%LG_MODE_2D  Generate a Laguerre–Gaussian LG(p,l) mode on a 2D grid.
%
%   [phase_out, intensity, lg_complex] = LG_MODE_2D(p, l, k, w0, xx, yy)
%
%   Generates the complex field of a Laguerre–Gaussian mode LG_p^l on the
%   2D Cartesian grid defined by coordinate matrices xx and yy.
%
%   INPUTS:
%     p        - radial index (non-negative integer)
%     l        - azimuthal index (integer, can be negative)
%     k        - wavenumber (2*pi / lambda)
%     w0       - beam waist radius (m)
%     xx, yy   - coordinate matrices defining the Cartesian grid (m)
%
%   OUTPUTS:
%     phase_out - wrapped phase of the LG mode (rad)
%     intensity - normalized intensity profile |LG|^2 (arbitrary units)
%     lg_complex- complex field LG_p^l(xx,yy) (unnormalized global phase)
%
%   Reference:
%     D. G. Voelz, "Computational Fourier Optics", LG mode formulation.


    % Rayleigh range
    zR = k * w0^2 / 2;

    % Plane at which the mode is evaluated
    z = 0.0;

    % Cartesian grid
    [xx, yy] = meshgrid(xx, yy);

    % Cylindrical coordinates
    [phi, r] = cart2pol(xx, yy);

    % Fundamental Gaussian beam U00 at z
    U00 = 1 ./ (1 + 1i * z / zR) .* ...
          exp(-r.^2 / w0^2 ./ (1 + 1i * z / zR));

    % Beam radius at z and normalized radial coordinate
    w = w0 * sqrt(1 + (z.^2 / zR^2));
    R = sqrt(2) * r ./ w;

    % Associated Laguerre polynomial L_p^l(R^2)
    Lpl = nchoosek(p + l, p) * ones(size(R));
    for m = 1:p
        Lpl = Lpl + (-1)^m / factorial(m) * ...
              nchoosek(p + l, p - m) .* R.^(2 * m);
    end

    % LG field
    U = U00 .* R.^l .* Lpl .* exp(1i * l * phi) .* ...
        exp(-1i * (2 * p + l + 1) * atan(z / zR));

    % Outputs
    intensity  = abs(U).^2;
    phase_out  = angle(U);
    lg_complex = U;
end
