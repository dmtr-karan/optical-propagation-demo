function aa = center_overlay(bg_size_x, bg_size_y, arr)
    % center_overlay - Centers an array on a zero-valued background
    % Inputs:
    %   bg_size_x, bg_size_y - Dimensions of the background
    %   arr - The array to be centered
    % Output:
    %   aa - The centered array on a zero-valued background
    
    arr = double(arr); % Ensure numerical type
    aa = zeros(bg_size_y, bg_size_x); % Create zero background
    
    [arr_height, arr_width] = size(arr);
    start_x = floor((bg_size_x - arr_width) / 2) + 1;
    start_y = floor((bg_size_y - arr_height) / 2) + 1;
    
    % Place the array in the center
    aa(start_y:start_y + arr_height - 1, start_x:start_x + arr_width - 1) = arr;
end