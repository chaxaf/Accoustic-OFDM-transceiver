function [txsignal conf] = ofdm_tx_channel(txbits, conf)

ofdm_symbols = [];
grouped_symbols = reshape(txbits, conf.n_carriers, []).';


for i = 1:conf.n_channel_training
    ofdm_symbol = osifft(grouped_symbols(i, :), conf.os_factor);
    prefix_length = round(length(ofdm_symbol) * conf.n_g);
    ofdm_symbol = [ofdm_symbol(end-prefix_length+1:end); ofdm_symbol];
    ofdm_symbols = [ofdm_symbols; ofdm_symbol];
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


