%% Run the two-step ADC model, report metrics and export result data
% Runs two_step_adc_model.m unchanged, then prints the linearity summary,
% checks for missing codes and monotonicity, and writes CSV files to
% ../results for plotting. Works in MATLAB and GNU Octave.

two_step_adc_model;   % defines Vin, D_out, code_transitions, DNL, INL, ...

root = fileparts(fileparts(mfilename('fullpath')));
if isempty(root), root = '..'; end
res = fullfile(root, 'results');

codes_present = unique(D_out);
missing_codes = setdiff(0:num_codes-1, codes_present);
is_monotonic  = all(diff(D_out) >= 0);
widths_mV     = round(actual_steps * 1e6) / 1e3;   % rounded to 1 uV

flash_comparators    = 2^N - 1;
two_step_comparators = 2 * (2^N_stage - 1);
reduction_pct = 100 * (flash_comparators - two_step_comparators) / flash_comparators;

summary = {
  sprintf('Resolution N                 : %d bit', N)
  sprintf('Stage resolution N_stage     : %d bit (coarse) + %d bit (fine)', N_stage, N_stage)
  sprintf('Reference / input range      : 0 to %g V', Vref)
  sprintf('LSB = Vref/2^N               : %.7f V (%.4f mV)', LSB, LSB*1e3)
  sprintf('LSB_c = Vref/2^N_stage       : %.4f V', Vref/2^N_stage)
  sprintf('Residue gain 2^N_stage       : %d', 2^N_stage)
  sprintf('Input sweep                  : %d points, step %.4f V', numel(Vin), Vin(2)-Vin(1))
  sprintf('Output code range            : %d to %d', min(D_out), max(D_out))
  sprintf('Distinct output codes        : %d of %d', numel(codes_present), num_codes)
  sprintf('Missing codes                : %d', numel(missing_codes))
  sprintf('Monotonic (sweep)            : %d', is_monotonic)
  sprintf('Measured step widths (mV)    : %s', mat2str(unique(widths_mV)))
  sprintf('DNL min / max (LSB)          : %+.4f / %+.4f', min(DNL), max(DNL))
  sprintf('max |DNL| (LSB)              : %.4f', max(abs(DNL)))
  sprintf('INL min / max (LSB)          : %+.4f / %+.4f', min(INL), max(INL))
  sprintf('max |INL| (LSB)              : %.4f', max(abs(INL)))
  sprintf('Flash comparators 2^N-1      : %d', flash_comparators)
  sprintf('Two-step comparators 2(2^Ns-1): %d', two_step_comparators)
  sprintf('Comparator-count reduction   : %.1f %%', reduction_pct)
};
fprintf('%s\n', summary{:});

fid = fopen(fullfile(res, 'summary.txt'), 'w');
fprintf(fid, '%s\n', summary{:});
fclose(fid);

fid = fopen(fullfile(res, 'transfer', 'transfer_characteristic.csv'), 'w');
fprintf(fid, 'vin_v,code\n');
fprintf(fid, '%.4f,%d\n', [Vin; D_out]);
fclose(fid);

fid = fopen(fullfile(res, 'linearity', 'linearity.csv'), 'w');
fprintf(fid, 'code,transition_v,dnl_lsb,inl_lsb\n');
fprintf(fid, '%d,%.4f,%.6f,%.6f\n', [0:num_codes-1; code_transitions; DNL; INL]);
fclose(fid);
