function ring_mask = ring_aperture_mask_gpu(array_size, inner_diameter, outer_diameter)
%RING_APERTURE_MASK_GPU  Create a binary ring (annulus) mask.
%
%   ring_mask = RING_APERTURE_MASK_GPU(array_size, inner_diameter, outer_diameter)
%
%   Builds a binary ring mask by subtracting a centered inner disk from a
%   centered outer disk. Suitable as a ring aperture or pupil mask.
%
%   INPUTS:
%     array_size     - size of the (square) output mask, in pixels
%     inner_diameter - diameter of the inner (hollow) circle, in pixels
%     outer_diameter - diameter of the outer circle, in pixels
%
%   OUTPUT:
%     ring_mask      - binary ring mask (array_size x array_size), values 0/1
%
%   Helper functions used (defined in this file):
%     draw_circle    - generate a centered circular binary mask
%     center_overlay - place a smaller mask in the center of a larger array
%
%   Note:
%     Output is a CPU array. Wrap with gpuArray(...) in the calling code
%     if GPU execution is required.

    % Create the inner "hole" mask
    hole2be = draw_circle(array_size, inner_diameter);
    hole2be = center_overlay(array_size, array_size, hole2be);
    circular4 = hole2be * 4;
    circular42 = ones(size(circular4));
    circular42(circular4 == 4) = 4;
    hole = circular42;
    hole(hole == 4) = 0;

    % Create outer circular aperture
    circular_aperture = draw_circle(array_size, outer_diameter);
    circular_aperture = center_overlay(array_size, array_size, circular_aperture);

    % Combine outer aperture with inner hole to form the ring mask
    ring_mask = hole .* circular_aperture;
end
