function [rxbits conf channels, auto_cors] = ofdm_rx_channel(rxsignal, conf, txbits)

L = length(rxsignal);
duration = (L - 1) / conf.f_s; % Ensures L samples with the given Fs
t = linspace(0, duration, L).';
baseband = rxsignal .* exp(-1*j*2*pi*conf.f_c*t);
lp_signal = 2*ofdmlowpass(baseband, ceil((conf.n_carriers +1)*conf.f_spacing/2)+10, conf.f_s);


rolloff = 0.22;
pulse = rrc(ceil(conf.os_factor), rolloff, 20);

filtered_rx_signal = conv(lp_signal, pulse, 'full');
[start_index, phase, magnitude] = frame_sync(filtered_rx_signal, ceil(conf.os_factor), conf);
lp_signal = lp_signal(start_index:end);

N = conf.f_s/conf.f_spacing;
Ng = conf.n_g*conf.f_s/conf.f_spacing;
Ns = N+Ng;

channels = zeros(conf.n_channel_training, conf.n_carriers);
auto_cors = [];

rxbits = [];

for i = 1:conf.n_channel_training
    ofdm_with_prefix = lp_signal(1+(i-1)*Ns:i*Ns);
    ofdm_symbol = ofdm_with_prefix(1+Ng:end);
    hx = osfft(ofdm_symbol, conf.os_factor);
    x = txbits(1+(i-1)*conf.n_carriers:i*conf.n_carriers);
    h = hx ./ x;
    channels(i, :) = h;
    % size(xcorr(h, h'))
    auto_cors = [auto_cors xcorr(h, h')];
    hx = hx ./ channels(1, :).';
    % hx = hx ./ h;
    % real(hx) < 0
    bits = real(hx) < 0;
    rxbits = [rxbits; bits];
end


% rxbits = zeros(1, conf.n_ofdm_symbols * conf.n_carriers *2).';