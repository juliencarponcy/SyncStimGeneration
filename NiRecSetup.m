daqList = daqlist("ni");
daqObject = daq("ni");
daqObject.Rate = 10000; %Sampling rate of NiDaq

Terminals = daqList.DeviceInfo.Terminals;  
Terminals{35};
CtrCam = addoutput(daqObject,daqList.DeviceID(1), 'ctr2', "PulseGeneration"); %ctr0 = PFI12
CtrCam.Frequency = 100;
CtrCam.DutyCycle = 0.5;
DigSessionBit = addoutput(daqObject,daqList.DeviceID(1), 'port0/line7', "Digital");
%%

write(daqObject,[0 0])

%%
  start(daqObject,"Continuous")
%%
stop(daqObject)
write(daqObject,double(0))
