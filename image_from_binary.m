function image_from_binary(bits, height)
% Example bit sequence (binary vector, length must be a multiple of 8)

% Step 1: Group the bit sequence into 8-bit chunks
n_bits_per_pixel = 8;
num_pixels = length(bits) / n_bits_per_pixel;

if mod(length(bits), n_bits_per_pixel) ~= 0
    error('The bit sequence length must be a multiple of 8.');
end

% Reshape into an Nx8 matrix where each row is one pixel's binary value
binary_matrix = reshape(bits, n_bits_per_pixel, [])';

% Step 2: Convert each 8-bit chunk to decimal (grayscale value)
pixel_values = bin2dec(num2str(binary_matrix)); % Convert binary strings to decimal

% Step 3: Reshape the vector into image dimensions
% Specify desired dimensions for the image
image_height = height; % Replace with desired height
image_width = num_pixels / image_height;

if mod(num_pixels, image_height) ~= 0
    error('The number of pixels must be divisible by the image height.');
end

image_matrix = reshape(pixel_values, image_width, image_height); % Reshape into a 2D image

% Step 4: Display the reconstructed image
imshow(uint8(image_matrix)); % Convert to uint8 for display
colormap(gray); % Optional: Use grayscale colormap
title('Reconstructed Image');


end