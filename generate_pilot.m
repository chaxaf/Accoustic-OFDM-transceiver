function pilot = generate_pilot(length)
pilot = 1 - 2*lfsr_framesync(length);
end