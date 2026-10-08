%% Behavioral Model of an 8-bit Two-Step Flash ADC
clear; clc;
% Parameters
N = 8;
N_stage = 4;
Vref = 2;
LSB = Vref / (2^N);
Vin = 0:0.001:Vref;
D_out = zeros(size(Vin));

for i = 1:length(Vin)
   LSB_c = Vref / (2^N_stage);
   D_coarse = floor(Vin(i) / LSB_c);
   D_coarse = min(D_coarse, 2^N_stage - 1);
   V_dac = D_coarse * LSB_c;
   V_residue = (Vin(i) - V_dac) * (2^N_stage);
   D_fine = floor(V_residue / LSB_c);
   D_fine = min(D_fine, 2^N_stage - 1);
   D_out(i) = (D_coarse * 2^N_stage) + D_fine;
end
num_codes = 2^N;
code_transitions = zeros(1, num_codes);
for k = 0:num_codes-1
   idx = find(D_out >= k, 1);
   if ~isempty(idx)
       code_transitions(k+1) = Vin(idx);
   end
end
actual_steps = diff(code_transitions);
DNL = (actual_steps - LSB) / LSB;
DNL = [0, DNL];
INL = cumsum(DNL);
figure('Color', 'w');
subplot(2,1,1);
plot(Vin, D_out, 'LineWidth', 1.5);
grid on; title('8-bit Two-Step ADC Transfer Characteristic');
xlabel('Input Voltage (V)'); ylabel('Digital Output Code');
% INL and DNL
subplot(2,1,2);
hold on;
plot(0:num_codes-1, DNL, 'b', 'DisplayName', 'DNL');
plot(0:num_codes-1, INL, 'r', 'DisplayName', 'INL');
grid on; legend;
title('Linearity Analysis (DNL & INL)');
xlabel('Output Code'); ylabel('Error (LSB)');
