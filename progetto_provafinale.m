clc
clear all

try
    tx = sdrtx('Pluto');
    disp('Connessione alla PlutoSDR riuscita!');
catch ME
    disp('Errore nella connessione alla PlutoSDR:');
    disp(ME.message);
end

% sto codice è da sistemare

