function arrr = draw_circle(arraysz, radius)
    % draw_circle - Creates a circular mask
    % Inputs:
    %   arraysz - Size of the output square matrix
    %   radius - Radius of the circle
    % Output:
    %   arrr - Binary image with a centered circle
    
    [xx, yy] = meshgrid(-radius:radius, -radius:radius);
    circle = (xx.^2 + yy.^2) <= radius^2;
    
    % Center the circle on a zero-valued background
    arrr = center_overlay(arraysz, arraysz, double(circle));
end