function u2 = two_step_fresnel_gpu(u1, L_input, L_output, lambda, z)
%TWO_STEP_FRESNEL_GPU  Two-step Fresnel diffraction on the GPU.
%
%   u2 = TWO_STEP_FRESNEL_GPU(u1, L_input, L_output, lambda, z)
%
%   Implements a two-step Fresnel diffraction method (Voelz, Appendix B)
%   using an intermediate “dummy” frequency plane. This version is written
%   for GPU execution.
%
%   Assumptions:
%     - Uniform sampling
%     - Square array
%
%   INPUTS:
%     u1        - complex field at the source plane (M x M), CPU or GPU array
%     L_input   - source plane side length (m)
%     L_output  - observation plane side length (m)
%     lambda    - wavelength (m)
%     z         - propagation distance (m)
%
%   OUTPUT:
%     u2        - complex field at the observation plane (M x M), gpuArray
%
%   Notes:
%     - If u1 is on the CPU, it is moved to the GPU inside this function.
%     - The calling code should use gather(u2) if CPU data is needed.
%
%   Reference:
%     D. G. Voelz, "Computational Fourier Optics", Appendix B (two-step
%     Fresnel method).

    % Input array size
    [M, ~] = size(u1);
    k      = 2*pi / lambda;   % Wavenumber

    % Move input field to GPU only if needed
    if ~isa(u1, 'gpuArray')
        u1 = gpuArray(u1);
    end

    % --- Source plane coordinates ---------------------------------------
    dx1 = L_input / M;
    x1  = gpuArray.linspace(-L_input/2, L_input/2 - dx1, M);
    [X1, Y1] = meshgrid(x1, x1);

    % Quadratic phase factor at source plane (pre-lens scaling term)
    quad_src = exp(1i * k / (2 * z * L_input) * (L_input - L_output) .* (X1.^2 + Y1.^2));

    % Apply source-plane quadratic phase and FFT
    u1_mod = u1 .* quad_src;
    u_fft  = fftshift(fft2(u1_mod));   % Last term in Eq. B.8

    % --- Intermediate (frequency) plane ---------------------------------
    fx1 = gpuArray.linspace(-1/(2*dx1), 1/(2*dx1) - 1/L_input, M);
    [FX1, FY1] = meshgrid(fx1, fx1);

    H_f = exp(-1i * pi * lambda * z * L_input / L_output .* (FX1.^2 + FY1.^2));
    u_f = H_f .* u_fft;
    u_f = ifft2(ifftshift(u_f));

    % --- Observation plane ----------------------------------------------
    dx2 = L_output / M;
    x2  = gpuArray.linspace(-L_output/2, L_output/2 - dx2, M);
    [X2, Y2] = meshgrid(x2, x2);

    quad_obs = exp(1i * k * z - 1i * k / (2 * z * L_output) * ...
                   (L_input - L_output) .* (X2.^2 + Y2.^2));

    % Scale and apply observation-plane quadratic phase
    u2 = (L_output / L_input) .* quad_obs .* u_f;
    u2 = u2 * (dx1^2 / dx2^2);   % x1 → x2 scale adjustment

    % NOTE:
    %   u2 is left as a gpuArray. Use gather(u2) in the calling code if
    %   you need the result on the CPU.
end
