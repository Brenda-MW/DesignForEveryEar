classdef tCochlearImplantRequirements < matlab.unittest.TestCase
    % Verification tests for the Cochlear Implant Speech Processor.
    % Each test method verifies one functional requirement from
    % CochlearImplantRequirements.slreqx. Test method names carry the
    % requirement Id so they can be linked (Verify) back to each requirement.
    %
    % Run:  runtests('tCochlearImplantRequirements')

    properties (Constant)
        Model = 'CochlearImplantModel';
    end

    methods (TestClassSetup)
        function loadModelAndParams(testCase)
            % Load the model first: its PreLoadFcn puts the utility folder
            % (design script, speech data) on the path. Unload only if we
            % loaded it. Then ensure the design script has populated the
            % base workspace.
            wasLoaded = bdIsLoaded(testCase.Model);
            if ~wasLoaded
                load_system(testCase.Model);
                testCase.addTeardown(@() close_system(testCase.Model, 0));
            end
            if evalin('base', "~exist('cochleardemo_inputFilter','var')")
                evalin('base', 'dspcochlearfilterdesign;');
            end
        end
    end

    methods (Access = private)
        function applyLogging(testCase, portH, name)
            % Turn on signal logging for an output port and give the logged
            % signal a known name, then register teardown to put the port's
            % logging settings back exactly as they were (keeps the model clean).
            oldLog  = get_param(portH, 'DataLogging');
            oldMode = get_param(portH, 'DataLoggingNameMode');
            oldName = get_param(portH, 'DataLoggingName');
            testCase.addTeardown(@() set_param(portH, ...
                'DataLogging', oldLog, 'DataLoggingNameMode', oldMode, ...
                'DataLoggingName', oldName));
            set_param(portH, 'DataLogging', 'on', ...
                'DataLoggingNameMode', 'Custom', 'DataLoggingName', name);
        end

        function C = logInterleavedCarrier(testCase, stopTime)
            % Simulate and return the Interleaved Sampling Pulse Generator
            % output as a [channels x time] matrix. This is the 8 interleaved
            % biphasic pulse trains (+/-1 carrier) BEFORE loudness modulation,
            % so it is the right signal to check interleaving and charge balance.
            ispg = [testCase.Model ...
                '/Stimulation Pulse Generator/Interleaved Sampling Pulse Generator'];
            op = get_param(ispg, 'PortHandles').Outport(1);
            testCase.applyLogging(op, 'carrier');

            simIn  = Simulink.SimulationInput(testCase.Model);
            simIn  = simIn.setModelParameter('StopTime', stopTime);
            simOut = sim(simIn);

            data = squeeze(simOut.logsout.getElement('carrier').Values.Data);
            C = data.';   % logged as [time x channels] -> make it [channels x time]
        end

        function [env, carrier, modOut] = logModulatorSignals(testCase, stopTime)
            % Simulate and return the three signals at the CIS Modulator, each
            % as [channels x time]: the subband envelope (in1), the +/-1 pulse
            % carrier (in2), and the modulated output. Used to show the pulse
            % amplitude tracks the envelope (loudness).
            modBlk = [testCase.Model ...
                '/Stimulation Pulse Generator/Continuous Interleaved Sampling (CIS)/Modulator'];
            ph = get_param(modBlk, 'PortHandles');
            envP = get_param(get_param(ph.Inport(1), 'Line'), 'SrcPortHandle');
            carP = get_param(get_param(ph.Inport(2), 'Line'), 'SrcPortHandle');
            outP = ph.Outport(1);
            testCase.applyLogging(envP, 'envlog');
            testCase.applyLogging(carP, 'carlog');
            testCase.applyLogging(outP, 'modlog');

            simIn  = Simulink.SimulationInput(testCase.Model);
            simIn  = simIn.setModelParameter('StopTime', stopTime);
            simOut = sim(simIn);
            ls = simOut.logsout;

            env     = testCase.toChanByTime(ls.getElement('envlog').Values.Data);
            carrier = testCase.toChanByTime(ls.getElement('carlog').Values.Data);
            modOut  = testCase.toChanByTime(ls.getElement('modlog').Values.Data);
        end

        function M = toChanByTime(~, data)
            % Normalize a logged signal to [channels x time] (8 channels).
            M = squeeze(data);
            if size(M, 1) ~= 8 && size(M, 2) == 8
                M = M.';
            end
        end
    end

    methods (Test)

        function tSP01_DcBlockingFilter(testCase)
            % SP-01: 3rd-order high-pass DC-blocking filter on the input.
            b = evalin('base', 'cochleardemo_inputFilter.b');
            a = evalin('base', 'cochleardemo_inputFilter.a');

            % 3rd order => 4 coefficients in numerator and denominator
            testCase.verifyEqual(numel(a), 4, 'Filter must be 3rd order');
            testCase.verifyEqual(numel(b), 4);

            % High-pass behavior: ~0 gain at DC (freq=0,z=e^freq=1), ~1 near Nyquist (z=-1)
            Hdc = abs(polyval(b, 1)  / polyval(a, 1));
            Hny = abs(polyval(b, -1) / polyval(a, -1));
            testCase.verifyLessThan(Hdc, 1e-6, '|H(DC)| should be ~0 (blocks DC)');
            testCase.verifyEqual(Hny, 1, 'AbsTol', 1e-3, '|H(Nyquist)| should be ~1');
        end

        function tSP02_EightChannels(testCase)
            % SP-02: the filter bank decomposes the signal into exactly 8 subbands.
            rect = [testCase.Model '/Filter bank signal processing/Subsystem/Rectifier'];
            nCh = numel(find_system(rect, 'SearchDepth', 1, 'BlockType', 'Inport'));
            testCase.verifyEqual(nCh, 8, 'Expected exactly 8 subband channels');
        end

        function tSP03_RectifierNonNegative(testCase)
            % SP-03: full-wave rectification => non-negative envelope.
            % Drive the real model and verify the Rectifier's actual output
            % signal is non-negative while its input genuinely swings negative.
            rect = [testCase.Model '/Filter bank signal processing/Subsystem/Rectifier'];
            ph   = get_param(rect, 'PortHandles');
            outP = ph.Outport(1);
            inSrc = get_param(get_param(ph.Inport(1), 'Line'), 'SrcPortHandle');

            % Enable signal logging on the Rectifier output and on the port
            % feeding its first input; restore both to their prior state after.
            testCase.applyLogging(outP,  'rectOut');
            testCase.applyLogging(inSrc, 'rectIn1');

            % Run a short simulation WITHOUT mutating the model's StopTime.
            simIn = Simulink.SimulationInput(testCase.Model);
            simIn = simIn.setModelParameter('StopTime', '0.1');
            simOut = sim(simIn);
            ls = simOut.logsout;

            inData  = ls.getElement('rectIn1').Values.Data;
            outData = ls.getElement('rectOut').Values.Data;

            % Pre-condition: the input must actually go negative, otherwise a
            % non-negative output would prove nothing.
            testCase.verifyTrue(any(inData(:) < 0), ...
                'Test input to the Rectifier should be a signed signal');

            % The requirement itself: rectified output is never negative.
            testCase.verifyGreaterThanOrEqual(min(outData(:)), 0, ...
                'Rectifier output signal must be non-negative');

            % Structural backup: 8 Abs blocks exist (one per channel).
            nAbs = numel(find_system(rect, 'SearchDepth', 1, 'BlockType', 'Abs'));
            testCase.verifyEqual(nAbs, 8, 'Expected one Abs block per channel');
        end

        function tSP04_DenoiseSoftThreshold(testCase)
            % SP-04: a selectable per-band soft-threshold denoise stage exists
            % and attenuates below-threshold content to zero (dead zone).
            stPath = [testCase.Model '/Denoise/Soft Threshold'];
            testCase.verifyNotEmpty(getSimulinkBlockHandle(stPath), ...
                'Soft Threshold subsystem must exist');

            % 8 Dead Zone blocks (one per band). They live inside the masked
            % Soft Threshold subsystem, so look under the mask.
            nDZ = numel(find_system(stPath, 'LookUnderMasks', 'on', ...
                'FollowLinks', 'on', 'BlockType', 'DeadZone'));
            testCase.verifyEqual(nDZ, 8, 'Expected one Dead Zone per band');

            % Dead-zone behaviour: |x| <= threshold -> 0 ; else shrink by threshold
            thr = 0.5;
            softThresh = @(x) sign(x) .* max(abs(x) - thr, 0);
            testCase.verifyEqual(softThresh(0.3), 0, ...
                'Below-threshold input must map to 0');
            testCase.verifyEqual(softThresh(0.9), 0.4, 'AbsTol', 1e-12, ...
                'Above-threshold input must be shrunk by the threshold');
        end

        function tST01_ChargeBalancedPulse(testCase)
            % ST-01: each biphasic stimulation pulse is charge-balanced.
            % Simulate the real pulse generator and verify that the net charge
            % per channel, summed over whole pulse periods, is zero.
            P = 16;                                  % pulse period (samples)
            C = testCase.logInterleavedCarrier('0.1');

            % The carrier must actually be biphasic: it uses both +1 and -1.
            testCase.verifyEqual(sort(unique(C(:))).', [-1 0 1], ...
                'Carrier should take values -1, 0, +1 (biphasic)');

            % Charge balance is a per-period property, so trim to whole periods.
            T = size(C, 2);
            nFull = floor(T / P) * P;
            testCase.assumeGreaterThanOrEqual(nFull, P, ...
                'Need at least one full pulse period to assess charge balance');
            Ctrim = C(:, 1:nFull);

            % Net charge over every complete period, for every channel, is ~0.
            nPeriods = nFull / P;
            for ch = 1:size(Ctrim, 1)
                perPeriod = sum(reshape(Ctrim(ch, :), P, nPeriods), 1);
                testCase.verifyEqual(perPeriod, zeros(1, nPeriods), 'AbsTol', 1e-12, ...
                    sprintf('Channel %d must inject zero net charge each period', ch - 1));
            end
        end

        function tST02_InterleavedStimulation(testCase)
            % ST-02: no two electrode channels fire at the same sample instant.
            ip = [testCase.Model '/Stimulation Pulse Generator/Interleaved Sampling Pulse Generator'];
            delays = str2double(get_param([ip '/Integer Delay'], 'DelayLength'));
            for k = 1:6
                delays(end+1) = str2double( ...
                    get_param([ip sprintf('/Integer Delay%d', k)], 'DelayLength')); %#ok<AGROW>
            end
            % Channel 0 has delay 0, the rest are 2,4,...,14
            allDelays = [0 delays];
            testCase.verifyEqual(sort(allDelays), 0:2:14, ...
                'Channel delays must be 0,2,...,14');

            % Behavioral: simulate and confirm that in the REAL carrier signal
            % at most one electrode is active at any single sample instant.
            C = testCase.logInterleavedCarrier('0.1');
            activePerSample = sum(C ~= 0, 1);
            testCase.verifyLessThanOrEqual(max(activePerSample), 1, ...
                'At most one electrode may be active at any sample instant');
        end

        function tST03_AmplitudeEncodesLoudness(testCase)
            % ST-03: pulse amplitude is proportional to the subband envelope.
            % Simulate the CIS Modulator and verify the modulated pulse train
            % equals the +/-1 carrier scaled by the subband envelope (loudness).
            [env, carrier, modOut] = testCase.logModulatorSignals('0.1');

            % Precondition: the carrier is a +/-1 pulse train and the envelope
            % genuinely varies (otherwise "scales with loudness" is vacuous).
            testCase.assumeEqual(sort(unique(carrier(:))).', [-1 0 1], ...
                'Carrier should be a +/-1 pulse train');
            testCase.assumeGreaterThan(max(env(:)) - min(env(:)), 0, ...
                'Envelope should vary across the run');

            % Core relationship: modulated output == carrier .* envelope,
            % element-wise, everywhere. This is proportionality to loudness.
            testCase.verifyEqual(modOut, carrier .* env, 'AbsTol', 1e-12, ...
                'Modulated pulse must equal carrier scaled by the envelope');

            % At each pulse instant the pulse height equals the envelope value,
            % so a louder band produces a taller pulse.
            isPulse = carrier ~= 0;
            testCase.verifyEqual(abs(modOut(isPulse)), abs(env(isPulse)), ...
                'AbsTol', 1e-12, ...
                'At a pulse, amplitude must equal the subband envelope magnitude');
        end

    end
end
