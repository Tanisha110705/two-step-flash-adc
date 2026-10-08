%% Sensitivity of extracted DNL/INL to the input-sweep step
% The reference model sweeps Vin in 1 mV steps, which is not an integer
% fraction of the 7.8125 mV LSB, so each transition can only be located to
% the next 1 mV grid point. This script repeats the transition-based
% DNL/INL extraction with the same converter for several sweep steps and
% writes the extremes to ../results/sweep-study/sweep_step_study.csv.

N = 8; N_stage = 4; Vref = 2;
LSB = Vref / (2^N);

% Steps (V): the report's 1 mV, finer decimal steps, and LSB-aligned steps
steps  = [1e-3, 5e-4, 1e-4, 1e-5, LSB/8, LSB/64];
labels = {'1 mV (report)', '0.5 mV', '0.1 mV', '0.01 mV', 'LSB/8', 'LSB/64'};

root = fileparts(fileparts(mfilename('fullpath')));
if isempty(root), root = '..'; end
fid = fopen(fullfile(root, 'results', 'sweep-study', 'sweep_step_study.csv'), 'w');
fprintf(fid, 'label,step_v,points,missing_codes,dnl_min,dnl_max,inl_min,inl_max\n');
for s = 1:numel(steps)
   Vin = 0:steps(s):Vref;
   D_out = two_step_adc_convert(Vin, N_stage, Vref);
   [~, DNL, INL] = transition_linearity(Vin, D_out, N, LSB);
   n_missing = numel(setdiff(0:2^N-1, unique(D_out)));
   fprintf('%-14s step=%.7g V  pts=%7d  missing=%d  DNL [%+.4f, %+.4f]  INL [%+.4f, %+.4f]\n', ...
           labels{s}, steps(s), numel(Vin), n_missing, min(DNL), max(DNL), min(INL), max(INL));
   fprintf(fid, '%s,%.10g,%d,%d,%.6f,%.6f,%.6f,%.6f\n', labels{s}, steps(s), numel(Vin), ...
           n_missing, min(DNL), max(DNL), min(INL), max(INL));
end
fclose(fid);
