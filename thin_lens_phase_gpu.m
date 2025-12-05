function uout = thin_lens_phase_gpu(uin, L, lambda, zf, radius)
%THIN_LENS_PHASE_GPU  Thin lens phase with circular aperture on GPU.
%
%   uout = THIN_LENS_PHASE_GPU(uin, L, lambda, zf, radius)
%
%   Applies a thin lens phase term with focal length zf to an input field
%   uin, together with a circular aperture of radius "radius". The output
%   field is returned on the GPU.
%
%   INPUTS:
%     uin    - input field (M x M), CPU or GPU array
%     L      - side length of computational window (m)
%     lambda - wavelength (m)
%     zf     - focal distance (m); zf > 0 converging, zf < 0 diverging
%     radius - lens aperture radius (m)
%
%   OUTPUT:
%     uout   - output field (M x M), gpuArray
%
%   Notes:
%     - If uin is already a gpuArray, the coordinate grid is created
%       directly on the GPU to avoid extra transfers.
%     - A circular pupil is applied in addition to the quadratic phase
%       term of the thin lens.
%
%   Reference:
%     - D. G. Voelz, "Computational Fourier Optics", Eq. 6.12 (thin lens).
%     - J. W. Goodman, "Introduction to Fourier Optics",
%         *Thin Lens Phase Transmittance*:
%           2nd Ed., Sec. 5-2
%           3rd Ed., Sec. 4.2.2  (standard form:  exp(-i k (x^2+y^2)/(2f)) )

    % Grid size and sampling
    [M, ~] = size(uin);       % Input field array size (assumed square)
    dx     = L / M;           % Sample interval
    k      = 2*pi / lambda;   % Wavenumber

    % Coordinate grid:
    % If uin is already on the GPU, create the grid directly there
    if isa(uin, 'gpuArray')
        x = gpuArray.linspace(-L/2, L/2 - dx, M);
    else
        x = -L/2 : dx : L/2 - dx;
    end
    [X, Y] = meshgrid(x, x);

    % Ensure input field is on the GPU
    if ~isa(uin, 'gpuArray')
        uin = gpuArray(uin);
    end

    % Circular aperture (pupil)
    pupil = double(sqrt(X.^2 + Y.^2) <= radius);

    % Thin lens phase term: exp(-i k (x^2 + y^2) / (2 zf))
    lens_phase = exp(-1i * k * (X.^2 + Y.^2) / (2 * zf));

    % Apply aperture and lens
    uout = uin .* pupil .* lens_phase;
end
