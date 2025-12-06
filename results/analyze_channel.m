clc

% analyse_channels("channels_exterior.mat", "exterior")
analyse_channels("channels_exterior_1.mat", "exterior");

function analyse_channels(filename, tit)

channels = load(filename).channels;
[nb_samples, ~] = size(channels);
avg_channels = mean(channels, 1);
% impulse_response_db = 10*log10(impulse_response);

% bar(impulse_response_db(1:100))
% title(tit)
% xlabel('\tau');
% ylabel('Power [dB]');
% hold on

% plot(abs(avg_channels))
figure
sgtitle(tit);

subplot(2, 1, 1);
bar(abs(avg_channels))
title("|h(f)|")
xlabel("Carrier index")
ylabel("|h(f)|")

subplot(2, 1, 2);
bar(angle(avg_channels))
title("arg(h(f))")
xlabel("Carrier index")
ylabel("arg(h(f))")


figure
subplot(2, 1, 1)
bar(abs(channels(1, :)))

subplot(2, 1, 2)

bar(abs(channels(nb_samples - 1, :)))

figure
channel_1_evolution = angle(channels(:, 1));
bar(channel_1_evolution)
title(sprintf("Evolution of carrier 1 - %s", tit))
% sgtitle("Evolution of carrier 1")
xlabel("Carrier index")
ylabel("arg(h(f))")
end