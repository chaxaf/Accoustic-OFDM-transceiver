function [rxbits conf] = ofdm_rx_freq_offset(rxsignal, conf, frame_number)

L = length(rxsignal);
duration = (L - 1) / conf.f_s; % Ensures L samples with the given Fs
t = linspace(0, duration, L).';
baseband = rxsignal .* exp(-1*j*2*pi*(conf.f_c + (frame_number - 1)*0.005)*t);
lp_signal = 2*ofdmlowpass(baseband, ceil((conf.n_carriers +1)*conf.f_spacing/2)+10, conf.f_s);


rolloff = 0.22;
pulse = rrc(ceil(conf.os_factor), rolloff, 20);

filtered_rx_signal = conv(lp_signal, pulse, 'full');
[start_index, phase, magnitude] = frame_sync(filtered_rx_signal, ceil(conf.os_factor), conf);
lp_signal = lp_signal(start_index:end);

N = conf.f_s/conf.f_spacing;
Ng = conf.n_g*conf.f_s/conf.f_spacing;
Ns = N+Ng;

%pilot decoding
if (frame_number == 1)
    ofdm_with_prefix = lp_signal(1:Ns);
    ofdm_symbol = ofdm_with_prefix(1+Ng:end);
    channel = osfft(ofdm_symbol, conf.os_factor) ./ generate_pilot(conf.n_carriers);
    theta = angle(channel);
    conf.theta = theta;
else
    theta = conf.theta;
end

rxbits = [];


extra_pilot = 0;
if conf.pilot_frequency ~= 0
    extra_pilot = ceil(conf.n_ofdm_symbols / conf.pilot_frequency) - 1;
end


pilot_decoded = 0;

start = 1;
finish = conf.n_ofdm_symbols;
if (frame_number == 1)
    start = 2;
    finish = conf.n_ofdm_symbols+1;
end

for i = start:finish
    index = i + pilot_decoded;
    ofdm_with_prefix = lp_signal(1+(index - 1)*Ns:index*Ns);
    ofdm_symbol = ofdm_with_prefix(1+Ng:end);
    qpsk_symbols = osfft(ofdm_symbol, conf.os_factor);
    
    % VITERBI-VITERBI - TRIALS
    if (frame_number ~= 1)
        deltaTheta = 1/4*angle(-qpsk_symbols.^4) + pi/2*(-1:4);
        [~, ind] = min(abs(deltaTheta - theta), [], 2);
        theta_values = deltaTheta(ind);
        theta = mod(0.01*theta_values + 0.99*theta, 2*pi);
    end
    %END VITERBI-VITERBI - TRIALS
    
    
    qpsk_symbols = qpsk_symbols .* exp(-1j * theta);
    bits = demapper(qpsk_symbols);
    rxbits = [rxbits; bits];
    
    if conf.pilot_frequency ~= 0 && mod(i-1, conf.pilot_frequency) == 0 && pilot_decoded < extra_pilot
        pilot_decoded = pilot_decoded + 1;
        index = i + pilot_decoded;
        
        % disp(sprintf("pilot decoded frequency for %d", index))
        ofdm_with_prefix = lp_signal(1+(index - 1)*Ns:index*Ns);
        ofdm_symbol = ofdm_with_prefix(1+Ng:end);
        channel = osfft(ofdm_symbol, conf.os_factor) ./ generate_pilot(conf.n_carriers);
        if (frame_number == 1)
            conf.theta = angle(channel);
        end
    end
    
    
end

% VITERBI-VITERBI - TRIALS
% deltaTheta = 1/4*angle(-qpsk_symbols.^4) + pi/2*(-1:4);
% [~, ind] = min(abs(deltaTheta - theta), [], 2);
% theta_values = deltaTheta(ind);
% theta = mod(0.01*theta_values + 0.99*theta, 2*pi);
%END VITERBI-VITERBI - TRIALS

% rxbits = zeros(1, conf.n_ofdm_symbols * conf.n_carriers *2).';