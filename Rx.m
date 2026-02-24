%% Realizzazione parametri per la ricezione, Creazione oggetti per le correzioni e creazione oggetto pluto RX

% Parametri frequenza e campionamento
SamplingRate = 1e6;
fc = 2.4e9; 

% Parametri modulazione e filtro rrc
M = 2;
span = 6;
sps = 2;
alfa = 0.5;

% Realizzazione header analogamente alla trasmissione
rng(42);
header = randi([0 1], 100, 1);

% Realizzazione filtro di ricezione adattato radice di Nyquist
rrc = rcosdesign(alfa, span, sps, 'sqrt');

% Realizzazione header modulato
headerMod = pskmod(header, M, 0, 'gray', 'InputType', 'bit');

% Creazione oggetto Symbol Synchronizer
symbSync = comm.SymbolSynchronizer(...
    'TimingErrorDetector', 'Gardner (non-data-aided)',...
    'SamplesPerSymbol', sps, ...
    'DampingFactor', 0.707,...
    'NormalizedLoopBandwidth', 0.01);

% Creazione oggetto Carrier Synchronizer
carrierSync = comm.CarrierSynchronizer(...
    'Modulation', 'BPSK', ...
    'SamplesPerSymbol', 1, ...      
    'DampingFactor', 0.707, ...       
    'NormalizedLoopBandwidth', 0.05);

% Creazione oggetto pluto RX 
rxPluto = sdrrx('Pluto','RadioID',...
    "usb:0",'CenterFrequency',fc,...
    'GainSource','Manual',...
    'Gain', 30,...
    'OutputDataType','single',...
    'BasebandSampleRate',SamplingRate);

%% Cattura e power control

% Ciclo while per la cattura con gestione gain in ricezione
while true
    disp('Cattura...');
    rx = capture(rxPluto, round(SamplingRate*10e-2));
    peak = max(abs(rx));
    currGain = rxPluto.Gain;

    if currGain > 68 % Max gain per 2.4 Ghz è di 71 dB!
        break;
    end

    if peak > 0.9
        rxPluto.Gain = currGain - 3;
        continue
    elseif peak < 0.05
        rxPluto.Gain = currGain + 3;
        continue
    else
       break;
    end

end

rx = rx / max(abs(rx)); % Normalizzazione

%% Algoritmo M-Th Power per la correzione "grezza" CFO

% Algoritmo elevando alla ^M per M-PSK (nel nostro caso BPSK)
rxM = rx .^ M;
L = length(rxM); % Lunghezza del segnale ricevuto
n = 2^18; % Dimensione FFT elevata per massimizzare la risoluzione in frequenza
Y = fft(rxM, n);
t = (0:length(rx)-1)' / SamplingRate; % Crea il vettore tempo per applicare la correzione di fase
f = (-n/2 : n/2-1) * (SamplingRate / n); % Crea l'asse delle frequenze centrato sullo zero
Y_shifted = fftshift(Y); % Sposta la componente DC (0 Hz) al centro dello spettro

[valoreMax, indiceMax] = max(abs(Y_shifted));
peakFrequence = f(indiceMax);
estimatedCFO = peakFrequence / M; % Ftx < Frx, quindi estimatedCFO negativa

% Correzione effettiva
rxCFO = rx .* exp(-1j*2*pi*estimatedCFO*t);

% Plot per vedere il picco alla frequenza sfasamentoCFO*2
figure; 
plot(f, abs(Y_shifted));
xlabel('Frequenza (Hz)'); grid on;

%% Filtraggio di ricezione
rxFilt = upfirdn(rxCFO, rrc, 1, 1);

%% Correzione con gli oggetti creati in precedenza 

% Campionamento e downsampling con Symbol Synchronizer
rxSymb = symbSync(rxFilt);

% Correzione "fine" CFO con Carrier Synchronizer
rxSync = carrierSync(rxSymb);

%% Cross-correlazione con header ed estrazione messaggio calcolandone la lunghezza

% Cross-correlazione e calcolo massimo di questa e suo indice
[phaseCorr, phaseLag] = xcorr(rxSync, headerMod);
[phaseCorrMax, phaseCorrIdx] = max(phaseCorr);

% Plot per vedere il picco della cross correlazione (inizio header)
figure;
plot(phaseLag, abs(phaseCorr));
xlabel('Lag');
ylabel('Cross-Correlazione');
grid on;
xlim([phaseLag(phaseCorrIdx-200), phaseLag(phaseCorrIdx+200)]);

% Correzione sfasamento dato dalla distanza M-PSK (nel nostro caso BPSK)
phaseErr = angle(phaseCorrMax);
rxSync = rxSync*exp(-1i*phaseErr);

% Calcolo indice di start (da fine header in poi)
lagPeak = phaseLag(phaseCorrIdx);
idxStart = lagPeak + length(headerMod) + 1;
rxPayload = rxSync(idxStart:end);

% Estrazione lunghezza messaggio ricevuto
lenSymb = rxPayload(1 : 8/log2(M)); 
lenBits = pskdemod(lenSymb, M, 0, 'gray', 'OutputType', 'bit');
len = bi2de(lenBits.', 'left-msb');

% Taglio per prendere solo il messaggio
rxFinal = rxPayload(1+8/log2(M):8/log2(M)+len*8);

% Plot della costellazione ricevuta
scatterplot(rxFinal); 
title('Costellazione Ricevuta');

%% Demodulazione e decodifica

% Demodulazione M-PSK (BPSK nel nostro caso)
sigDemod = pskdemod(rxFinal, M, 0, 'gray', 'OutputType', 'bit');

% Conversione da ASCII a testo
rxBitMatrix = reshape(sigDemod, 8, []); 
rxAscii = bi2de(rxBitMatrix.', 'left-msb');
rxText = char(rxAscii.');

%% Verifica errori sull'header e stampa messaggio finale

% Verifica dei bit errati
rxHeaderSymb = rxSync(idxStart-length(headerMod) : idxStart - 1);
rxHeaderBits = pskdemod(rxHeaderSymb, M, 0, 'gray', 'OutputType', 'bit');
[numErrors, BER] = biterr(rxHeaderBits, header);
numMaxErrors = 1; 
    
% Stampa solo se l'header ricevuto ha 0 errori
if numErrors < numMaxErrors
    fprintf('%s', rxText);
else
    fprintf("Messaggio ricevuto non correttamente!");
end