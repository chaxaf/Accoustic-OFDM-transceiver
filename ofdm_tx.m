function [txsignal conf] = ofdm_tx(txbits, conf)
% Convert to QPSK symbols
bits = 2 * (txbits - 0.5);
bits2 = reshape(bits, 2, []);

real_p = ((bits2(1,:) > 0)-0.5)*sqrt(2);
imag_p = ((bits2(2,:) > 0)-0.5)*sqrt(2);

symbols = real_p + 1i*imag_p;
ofdm_symbols = [];
% symbols = 1:512;
grouped_symbols = reshape(symbols, conf.n_carriers, []).';

pilot = generate_pilot(conf.n_carriers);
% size(pilot)
ofdm_pilot = osifft(pilot, conf.os_factor); %conversion to time domain
prefix_length = round(length(ofdm_pilot) * conf.n_g);
ofdm_pilot = [ofdm_pilot(end-prefix_length+1:end); ofdm_pilot]/4;
% ofdm_pilot = ofdm_pilot/(norm(ofdm_pilot)^2);
ofdm_symbols = [ofdm_symbols; ofdm_pilot];

extra_pilot = 0;
if conf.pilot_frequency ~= 0
    extra_pilot = ceil(conf.redondancy* conf.n_ofdm_symbols / conf.pilot_frequency) - 1
end

pilot_inserted = 0;
for i = 1:conf.redondancy*conf.n_ofdm_symbols
    ofdm_symbol = osifft(grouped_symbols(i, :), conf.os_factor);
    prefix_length = round(length(ofdm_symbol) * conf.n_g);
    ofdm_symbol = [ofdm_symbol(end-prefix_length+1:end); ofdm_symbol];
    ofdm_symbols = [ofdm_symbols; ofdm_symbol];
    
    if conf.pilot_frequency ~= 0 && mod(i, conf.pilot_frequency) == 0 && pilot_inserted < extra_pilot
        pilot_inserted = pilot_inserted + 1;
        % disp(sprintf("pilot frequency for %d", i))
        pilot = generate_pilot(conf.n_carriers);
        ofdm_pilot = osifft(pilot, conf.os_factor);
        prefix_length = round(length(ofdm_pilot) * conf.n_g);
        ofdm_pilot = [ofdm_pilot(end-prefix_length+1:end); ofdm_pilot]/4;
        ofdm_symbols = [ofdm_symbols; ofdm_pilot];
    end
end

% preamble part
preamble = 1 - 2*lfsr_framesync(conf.npreamble).';
preamble_up = upsample(preamble, ceil(conf.os_factor));

% base-band pulse shaping
rolloff = 0.22;
pulse = rrc(ceil(conf.os_factor), rolloff, 20);

% Shape the symbol diracs with pulse
filtered_preamble = conv(preamble_up, pulse.', 'full').';


txsymbols = [filtered_preamble/(norm(filtered_preamble)*2); ofdm_symbols*2];


L = length(txsymbols);
duration = (L - 1) / conf.f_s; % Ensures L samples with the given Fs
t = linspace(0, duration, L).';
carrier_vec = exp(1*j*2*pi*conf.f_c*t);

txsignal = real(txsymbols .* carrier_vec);
% txsignal = real(ofdm_symbols);
% size(txsignal)


