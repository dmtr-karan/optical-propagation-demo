function pup = circular_aperture_gpu(x, y, radius)
%CIRCULAR_APERTURE_GPU  Circular aperture function on the GPU.
%
%   pup = CIRCULAR_APERTURE_GPU(x, y, radius)
%
%   Creates a circular aperture (pupil) function on the GPU, with value 1
%   inside the given radius and 0 outside.
%
%   INPUTS:
%     x      - 2D array of x-coordinates (CPU or GPU)
%     y      - 2D array of y-coordinates (same size as x)
%     radius - aperture radius (in the same units as x and y)
%
%   OUTPUT:
%     pup    - binary aperture mask on the GPU (double, 0 or 1)
%
%   Notes:
%     - If x and y are already gpuArray, they remain on the GPU.
%     - This function is used to generate a circular aperture in the
%       input plane before propagation.

    % Ensure inputs are on the GPU
    x = gpuArray(x);
    y = gpuArray(y);

    % Radial distance and aperture mask
    r   = sqrt(x.^2 + y.^2);
    pup = double(r <= radius);   % 1 inside radius, 0 outside
end
