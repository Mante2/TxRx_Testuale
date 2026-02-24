%% Realizzazione parametri per la trasmissione e creazione oggetto pluto TX

% Parametri frequenza e campionamento
SamplingRate = 1e6;
fc = 2.4e9;

% Parametri  modulazione e filtro rrc
M = 2;
sps = 2; 
span = 6;
alfa = 0.5;

% Creazione oggetto pluto TX
idTX = 'usb:0';

txPluto = sdrtx('Pluto',...
       'RadioID',idTX,...
       'CenterFrequency',fc,...
       'Gain',-6, ... %must be between -89 and 0
       'BasebandSampleRate',SamplingRate);

%% Filtro radice di Nyquist

rrcFilter = rcosdesign(alfa, span, sps, 'sqrt');

%% Realizzazione messaggio da trasmettere

% Creazione header pseudo-randomico con seme
rng(42);
header = randi([0 1], 100, 1);

% Acquisizione messaggio da terminale
msg = input('Inserisci il messaggio da trasmettere: ', 's');

% Conversione in binario
dataAscii = uint8(msg);
bitMatrix = de2bi(dataAscii, 8, 'left-msb');
msgBin = reshape(bitMatrix.', [], 1);

% Calcolo lunghezza messaggio (8 bit quindi al massimo 255 caratteri) e conversione in binario
len = length(dataAscii);
lenBits = de2bi(len, 8, 'left-msb').';

% Composizione messaggio
txBits = [header;lenBits; msgBin;];

% Modulazione M-PSK (nel nostro caso BPSK)
modSig = pskmod(txBits, M, 0, 'gray', 'InputType', 'bit');

% Filtraggio e Normalizzazione
txSig = upfirdn(modSig, rrcFilter, sps);
txNorm = (txSig / max(abs(txSig))) * 0.7;

% Trasmissione con pausa di 5 ms di zeri
tx = [txNorm; zeros(round(SamplingRate*5e-3), 1)];
transmitRepeat(txPluto, tx);