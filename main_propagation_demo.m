% GPU-accelerated propagation of an LG vortex beam:
% Comparison of Angular Spectrum Method (ASM) and 2-step Fresnel propagation.
%
% This script:
%   - Defines a square simulation window and LG(p,l) vortex input beam
%   - Checks Fresnel and sampling criteria (Voelz sampling rules)
%   - Propagates the field with:
%       (1) Angular Spectrum Method (ASM, same input/output window)
%       (2) Custom 2-step GPU-based Fresnel propagator (scaled output window)
%   - Optionally includes a thin lens and a ring aperture mask
%   - Compares irradiance and phase between both methods (2D maps + 1D cuts)
%
% Distances:
%   z        - free-space propagation distance (m)
%   foc_dist - thin lens focal distance (m)
%
% Window sizes:
%   L_input  - side length of source-plane computational window (m)
%   L_output - side length of observation-plane window (m) for 2-step Fresnel
%
% Dependencies (local .m files):
%   lg_mode_2d.m              - LG mode generator (Voelz-based formulation)
%   fresnel_number_criterion.m
%   sampling_criterion.m
%   thin_lens_phase_gpu.m
%   two_step_fresnel_gpu.m
%   angular_spectrum_gpu.m
%   ring_aperture_mask_gpu.m
%   draw_circle.m
%   center_overlay.m

close all; clear; clc;

% --- Units ---------------------------------------------------------------
cm = 1e-2;
mm = 1e-3;
um = 1e-6;
nm = 1e-9;

% --- Switches ------------------------------------------------------------
use_lens     = 1;   % 1 -> include thin lens operator
use_pup      = 0;   % 1 -> apply ring aperture mask
save_figures = 0;   % 1 -> save figures in current folder

% Example alternative parameters:
% beam_diameter = 4*mm; L_input = 12*mm; M = 1000; z = 300*cm; scale_factor = 1;

% --- Source and simulation parameters -----------------------------------
beam_diameter = 0.6*cm;         % Source diameter (m)
beam_radius   = beam_diameter / 2;  % Source radius (m)

L_input       = 1.28*cm;        % Side length of computational window (m)
M             = 2048*1;           % Number of samples per dimension
scale_factor  = 1/1;              % Scaling for observation-plane window

z        = 30*cm;               % Propagation distance (m)
foc_dist = z;                   % Lens focal distance (m)
name_extention = cat(2, ['_samples_', num2str(M), '_scale', num2str(scale_factor), '_focus_', num2str(foc_dist), '_lens_', num2str(use_lens)]);

% --- Spatial sampling ----------------------------------------------------
dx = L_input / M;                           % Source sample interval
x1 = -L_input/2 : dx : L_input/2 - dx;     % Source coordinates (x)
y1 = x1;                                   % Source coordinates (y)

% --- Optical parameters --------------------------------------------------
lambda      = 500*nm;          % Wavelength (m), 500 nm
k           = 2*pi / lambda;   % Wavenumber
lens_radius = 2.54*cm;         % Lens radius (m) ~ 2 inch lens

% --- LG mode parameters --------------------------------------------------
p = 0;
l = 1;

[phase, int, lg_comp] = lg_mode_2d(p, l, k, beam_radius, x1, y1);
lg_phase              = rescale(phase, 0, 1);

% --- Put LG mode on GPU -------------------------------------------------
lg_comp_gpu = gpuArray(lg_comp);

% --- Diagnostic checks: Fresnel number & sampling ------------------------
% Fresnel number criterion (prints a diagnostic message, value not reused)
fresnel_number_criterion(lambda, z, beam_radius);

% Sampling criterion (prints diagnostic; status available if needed)
sampling_criterion(lambda, z, L_input, dx, M);

% Source field: LG mode
u1 = lg_comp_gpu;                 % Pure LG mode as input

% I_source = abs(u1.^2);           % Source irradiance

% apply aperture
if use_pup == 1
    % Create ring aperture mask
    hole_radius = 4;
    circ_radius = 40;
    ring_aperture = gpuArray(ring_aperture_mask_gpu(numel(x1), hole_radius, circ_radius));

    % Apply mask
    u1 = u1 .* ring_aperture;
end


% Apply lens
u_after_lens = thin_lens_phase_gpu(u1, L_input, lambda, foc_dist, lens_radius);

L_output = scale_factor * L_input;

% --- Propagation (lens / free space, ASM vs 2-step) ---------------------
if use_lens == 1
    % Propagation through lens (using GPU)
    u2_two_step = two_step_fresnel_gpu(u_after_lens, L_input, L_output, lambda, z);
    u2_asm      = angular_spectrum_gpu(u_after_lens, L_input, lambda, z);
else
    % Free-space propagation (using GPU)
    u2_two_step = two_step_fresnel_gpu(u1, L_input, L_output, lambda, z);
    u2_asm      = angular_spectrum_gpu(u1, L_input, lambda, z);
end

% --- Move results back to CPU for visualization -------------------------
I_asm      = gather(abs(u2_asm).^2);       % Obs. irradiance (ASM)
I_two_step = gather(abs(u2_two_step).^2);  % Obs. irradiance (2-step)

x2 = x1;    % Observation coordinates
y2 = y1;

[~, mCols] = size(I_asm);
midCol     = floor(mCols/ 2) + 1;          % Middle column (cross-section)

%% =======================================================================
%  FIGURE 1: LG input beam + ring aperture diagnostics
% ========================================================================

figure('Name','LG beam','Position',[150 150 1000 450]);

% (a) LG intensity
subplot(1,2,1);
imagesc(x1, y1, int);
axis image; axis xy;
colormap(gca, 'turbo');
colorbar;
xlabel('x (m)'); ylabel('y (m)');
title('LG intensity (p=0, l=1)');

% (b) LG phase
subplot(1,2,2);
imagesc(x1, y1, phase);
axis image; axis xy;
colormap(gca, 'inferno');
colorbar;
xlabel('x (m)'); ylabel('y (m)');
title('LG phase');


% Save figure
if save_figures == 1
    exportgraphics(gcf, cat(2, ['fig01_lg_beam', name_extention, '.png']), 'Resolution', 300);
else
end

%% =======================================================================
%  FIGURE 2: 2D irradiance comparison (ASM vs two-step)
% ========================================================================

figure('Name','2D irradiance comparison','Position',[150 150 1000 450]);

% ASM irradiance
subplot(1,2,1);
imagesc(x2, y2, I_asm);
axis image; axis xy;
colormap(gca, 'turbo');
colorbar;
xlabel('x (m)'); ylabel('y (m)');
title('ASM propagated irradiance');
if use_lens == 1
    zoom_range = 0.075e-3;
    xlim([-zoom_range zoom_range]);
    ylim([-zoom_range zoom_range]);
else
end

% Two-step irradiance
subplot(1,2,2);
imagesc(x2, y2, I_two_step);
axis image; axis xy;
colormap(gca, 'turbo');
colorbar;
xlabel('x (m)'); ylabel('y (m)');
title('Two-step Fresnel irradiance');
if use_lens == 1
    zoom_range = 0.075e-3;
    xlim([-zoom_range zoom_range]);
    ylim([-zoom_range zoom_range]);
else
end

% Save figure
if save_figures == 1
    exportgraphics(gcf, cat(2, ['fig02_2d_irradiance_comparison', name_extention, '.png']), 'Resolution', 300);
else
end

%% =======================================================================
%  FIGURE 2B: 2D irradiance comparison (ASM vs two-step)
% ========================================================================

figure('Name','2D phase comparison','Position',[150 150 1000 450]);

% ASM phase
subplot(1,2,1);
imagesc(x2, y2, unwrap(angle(u2_asm), 2*pi));
axis image; axis xy;
colormap(gca, 'inferno');
colorbar;
xlabel('x (m)'); ylabel('y (m)');
title('Phase (ASM)');
if use_lens == 1
    zoom_range = 0.075e-3;
    xlim([-zoom_range zoom_range]);
    ylim([-zoom_range zoom_range]);
else
end

% Two-step irradiance
subplot(1,2,2);
imagesc(x2, y2, unwrap(angle(u2_two_step), 2*pi));
axis image; axis xy;
colormap(gca, 'inferno');
colorbar;
xlabel('x (m)'); ylabel('y (m)');
title('Phase (2-step)');
if use_lens == 1
    zoom_range = 0.075e-3;
    xlim([-zoom_range zoom_range]);
    ylim([-zoom_range zoom_range]);
else
end

% Save figure
if save_figures == 1
    exportgraphics(gcf, cat(2, ['fig02B_2d_phase_comparison', name_extention, '.png']), 'Resolution', 300);
else
end
%% =======================================================================
%  FIGURE 2C: Phase comparison (1D midline)
% ========================================================================


figure('Name','1D phase comparison','Position',[250 250 900 500]);

plot(x2, unwrap(angle(u2_asm(:, midCol)), 2*pi), 'Color', [0.5, 0, 0.5], 'LineWidth', 1.6); hold on;
plot(x2, unwrap(angle(u2_two_step(:, midCol)), 2*pi), 'Color', [0, 1, 1], 'LineWidth', 1.6);
Phase_diff = unwrap(angle(u2_asm(:, midCol)), 2*pi) - unwrap(angle(u2_two_step(:, midCol)), 2*pi);
plot(x2, Phase_diff, '.', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1.4); % Difference plot
hold off;
xlabel('x (m)'); ylabel('Phase (rad)');
title('Obs. field phase');
legend('ASM', '2-step', 'Diff.', 'Location', 'best');
grid('on')
if use_lens == 1
    zoom_range = 0.075e-3;
    xlim([-zoom_range zoom_range]);
else
end

% Save figure
if save_figures == 1
    exportgraphics(gcf, cat(2, ['fig04_phase_comparison_midline', name_extention, '.png']), 'Resolution', 300);
else
end
