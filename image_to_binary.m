function [bits, real_length] = image_to_bits(filename, n_carriers)

image = imread(filename);

if size(image, 3) == 3
    image = rgb2gray(image);
end
image_vector = image(:);

binary_image = dec2bin(image_vector, 8);

bits = reshape(binary_image', 1, []) - '0'; % Converts char '0'/'1' to numeric 0/1

len = length(bits);
real_length = len;

remainder = mod(len, n_carriers);
if remainder ~= 0
    padding_needed = n_carriers - remainder;
else
    padding_needed = 0;
end

% Step 3: Append zeros to make the length a multiple of n_carriers
bits = [bits, zeros(1, padding_needed)];

end


