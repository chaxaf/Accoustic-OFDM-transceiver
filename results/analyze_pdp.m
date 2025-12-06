clc
pdp_interior_db= load("pdp_interior.mat").db;
pdp_exterior_db= load("pdp_exterior_1.mat").db;
pdp_cavity_db= load("pdp_cavity.mat").db;

% channels_interior = load("channels_interior").channels;
% channels_exterior = load("channels_exterior_1").channels;
% channels_cavity = load("channels_cavity").channels;

% pdp_interior = abs(ifft(channels_interior(1, :))).^2.';
% pdp_exterior = abs(ifft(channels_exterior(1, :))).^2.';
% pdp_cavity = abs(ifft(channels_cavity(1, :))).^2.';


% bar(pdp)
pdp_interior = 10.^(pdp_interior_db/10);
pdp_exterior = 10.^(pdp_exterior_db/10);
pdp_cavity = 10.^(pdp_cavity_db/10);
f_s = 100;
lim = 128;
ds_cavity = compute_delay_spread(pdp_cavity(1:lim))/f_s
ds_interior = compute_delay_spread(pdp_interior(1:lim))/f_s
ds_exterior = compute_delay_spread(pdp_exterior(1:lim))/f_s

cbw_cavity = 1/ds_cavity
cbw_interior = 1/ds_interior
cbw_exterior = 1/ds_exterior







figure
bar(pdp_cavity_db(1:lim))
hold on
bar(pdp_interior_db(1:lim))
hold on
bar(pdp_exterior_db(1:lim))


legend("Cavity", "Interior", "Exterior")
xlabel('\tau');
ylabel('Power [dB]');

function [rms] = compute_delay_spread(pdp)
tau= 1:length(pdp);
mean = sum(tau.*pdp.')/sum(pdp);
rms = sum((tau- mean).^2.*pdp.')/sum(pdp);

end