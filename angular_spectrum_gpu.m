function u2 = angular_spectrum_gpu(u1, L, lambda, z)
%ANGULAR_SPECTRUM_GPU  Angular Spectrum Method (ASM) propagation on GPU.
%
%   u2 = ANGULAR_SPECTRUM_GPU(u1, L, lambda, z)
%
%   Propagates a complex field u1 over a distance z in free space using
%   the Angular Spectrum Method. The sampling grid in the output plane is
%   identical to the input grid (no magnification).
%
%   INPUTS:
%     u1     - input complex field (M x M), CPU or GPU array
%     L      - side length of the computational window (m)
%     lambda - wavelength (m)
%     z      - propagation distance (m)
%
%   OUTPUT:
%     u2     - propagated complex field (M x M), gpuArray
%
%   Notes:
%     - If u1 is already on the GPU, the spatial frequency grid is created
%       directly on the GPU to avoid CPU↔GPU transfers.
%     - The method assumes a square grid (M x M) with sampling dx = L / M.
%
%   Reference:
%     D. G. Voelz, "Computational Fourier Optics", SPIE Press.
%     Angular spectrum propagation (ASM) chapter.


    % Grid size and sampling
    [M, ~] = size(u1);    % Input field array size (assumed square)
    dx     = L / M;       % Sample interval

    % Spatial frequency coordinates (cycles per meter)
    % If u1 is already on the GPU, create the frequency grid directly there
    if isa(u1, 'gpuArray')
        fx = gpuArray.linspace(-1/(2*dx), 1/(2*dx) - 1/L, M);
    else
        fx = -1/(2*dx) : 1/L : 1/(2*dx) - 1/L;
    end
    [FX, FY] = meshgrid(fx, fx);

    % Ensure input is on the GPU (no-op if already gpuArray)
    if ~isa(u1, 'gpuArray')
        u1 = gpuArray(u1);
    end

    % Angular spectrum of the input field
    u_fft = fftshift(fft2(u1));   % Shift and FFT source field

    % Propagation factor kz (propagating + evanescent components)
    k        = 2*pi / lambda;
    argument = (2*pi)^2 * ((1/lambda)^2 - FX.^2 - FY.^2);

    tmp = sqrt(abs(argument));
    kz  = (argument >= 0) .* tmp + (argument < 0) .* (1i * tmp);

    % Transfer function and propagated field
    H  = exp(1i * kz * z);               % Transfer function
    u2 = ifft2(ifftshift(u_fft .* H));   % Back to spatial domain
end
