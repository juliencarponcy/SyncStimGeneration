daqList = daqlist("ni");
daqObject = daq("ni");
daqObject.Rate = 10000; %Sampling rate of NiDaq
LaserAnaCh = addoutput(daqObject,daqList.DeviceID(1),"ao0","Voltage");
LaserDigCh = addoutput(daqObject,daqList.DeviceID(1), 'port0/line4', 'Digital');

%% White noise

Fs = uint32(daqObject.Rate);
minTarget = -0.35;
maxTarget = 0.35;
SignalDur = 30;

noise = wgn(Fs*SignalDur,1,0);
Scaled = noise*(maxTarget-minTarget)/2;
DigOn = ones(length(Scaled),1);
%% Send White noise
preload(daqObject,[Scaled DigOn])
start(daqObject)
while daqObject.Running == 1
    pause(0.1)
end
write(daqObject, [0 0]);

%% Symmetric Concave Quadratic Chirp
SignalDur = 30;
InterStimDur = 5;
Fs= daqObject.Rate;
t = -SignalDur/2:1/Fs:SignalDur/2;
fo = 100;
f1 = 0.5;
t1 = SignalDur/2;
y = chirp(t,fo,t1,f1,'quadratic',[],'concave');

%% Compute and plot the spectrogram of the chirp. Divide the signal into segments such that the time resolution is 0.1 second. Specify 99% of overlap between adjoining segments and a spectral leakage of 0.85.
figure;
pspectrum(y,t,'spectrogram','FrequencyLimits',[1 100],'TimeResolution',2);%,'Leakage',0.85
ylim(gca,[0 100])
set(gca, 'Clim', [-30 10])
figure; plot(t,y)
minTarget = -0.35;
maxTarget =0.35;

PositiveSignal = (y+1)/2;
Scaled = PositiveSignal*(maxTarget-minTarget)+minTarget;

figure; plot(t,Scaled)

paddedScaled = [Scaled'; zeros(Fs*InterStimDur,1)];
DigitalSig = [ones(length(Scaled),1); zeros(Fs*InterStimDur,1)];
%% Send Chirp
% preload(daqObject,PositiveNoise)
% removechannel(daqObject,2)
write(daqObject, [paddedScaled DigitalSig]); %Zero padding added to avoid laser ON after signal
write(daqObject, 0);

stop(daqObject)
%% Send Analog AND Digital Signal
daqreset;

daqList = daqlist("ni");
daqObject = daq("ni");
daqObject.Rate = 10000; %Sampling rate of NiDaq
LaserAnaCh = addoutput(daqObject,daqList.DeviceID(1),"ao0","Voltage");

LaserDigCh = addoutput(daqObject, ...
    daqList.DeviceID(1),daqList.DeviceInfo.Subsystems(1, 3).ChannelNames(8) ,"Digital");

write(daqObject, [paddedScaled DigitalSig]); %Zero padding added to avoid laser ON after signal
% write(daqObject, 0);

%%
LaserAnaCh = addoutput(daqObject,daqList.DeviceID(1),"ao0","Voltage");
% daqObject.Channels(1).Range = [-10 10];


LaserDigCh = addoutput(daqObject, ...
    daqList.DeviceID(1),daqList.DeviceInfo.Subsystems(1, 3).ChannelNames(1) ,"Digital");
% LaserDigCh = addoutput(daqObject, ...
%     daqList.DeviceID(1),daqList.DeviceInfo.Subsystems(1, 5).ChannelNames(2) ,"PulseGeneration");
 % Subsystem 5 is for counter channels

% Following return the terminal of the counter
% LaserAnaCh.Terminal
 
 
%% Example for 5ms pulses (Digital Mode)

StimDur=1; % in sec
AnaLevel=2; % in V
% setting up Analog level to control Laser power
SampleNb = daqObject.Rate*StimDur;

AnaOutput = ones(SampleNb,1)*AnaLevel;

write(daqObject, AnaOutput);

pulseWidth = 0.005; %5ms in sec
LaserDigCh.Frequency = 10;

digDutyC = LaserDigCh.Frequency*pulseWidth;

LaserDigCh.InitialDelay = 0; % in seconds
LaserDigCh.DutyCycle = digDutyC;

start(daqObject) %, "Duration", seconds(2));
% 
% while dq.Running
%     pause(0.1);
% end
% 
% data = read(dq, seconds(1));
% plot(data.Time, data.Variables);
stop(daqObject) %, "Duration", seconds(2));

%% Monotonous Single pulses, random or fixed Inter pulse interval
% Signal Preparation for full stim protocol
PulseDur = 3;
PulseNb = 10;

InterStimDur = [1 3];
AnaValue = 0.025;
daqObject.Rate = 10000; %Sampling rate of NiDaq

DigLine = [];
%random inter pulse duration1.51.
if numel(InterStimDur) == 2
    rdelays = InterStimDur(1) + (InterStimDur(2)-InterStimDur(1)).*rand(PulseNb+1,1); % +1 because of before first and after last 
    DigLine=[DigLine; zeros(round(rdelays(1)*daqObject.Rate),1)];
    for p=1:PulseNb
        DigLine=[DigLine; ones(round(PulseDur*daqObject.Rate),1); zeros(round(rdelays(p+1)*daqObject.Rate),1)];
    end
    
% fixed inter pulse duration
else
    DigLine=[DigLine; zeros(round(InterStimDur(1)*daqObject.Rate),1)];
    for p=1:PulseNb
        DigLine=[DigLine; ones(round(PulseDur*daqObject.Rate),1); zeros(round(InterStimDur(1)*daqObject.Rate),1)];
    end
end
% paddedScaled = [Scaled'; zeros(Fs*InterStimDur,1)];
AnaLine = ones(length(DigLine),1).*AnaValue;

%% Board preparation

daqList = daqlist("ni");
daqObject = daq("ni");
daqObject.Rate = 10000; %Sampl0.2ing rate of NiDaq
LaserAnaCh = addoutput(daqObject,daqList.DeviceID(1),'ao0','Voltage');
LaserDigCh = addoutput(daqObject,daqList.DeviceID(1), 'port0/line4', 'Digital');

loadMat = [AnaLine DigLine];
preload(daqObject,loadMat)
start(daqObject)

%%
stop(daqObject)
write(daqObject,[0 0])
clear all
