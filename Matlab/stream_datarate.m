
snew = instrfind;
if ~(isempty(snew) )  
    fclose(snew)
    delete(snew)
    clear snew
end
echotcpip('off');
close all;
clear all;
tic

data = 'stream';

counter=0;

t = tcpip('169.254.158.27', 15533, 'NetworkRole', 'client','InputBufferSize',1000000);

fopen(t)
N=5;
measure_sec=1;
meandata= zeros(N,1);
for i=1:N
    if (t.BytesAvailable > 0)
        %data_in=strcat(data_in,transpose(fread(t, t.BytesAvailable,'char')));
        data_in=strcat(data_in,transpose(fread(t, t.BytesAvailable,'char')));
    end
    data_in='';
    fwrite(t,data); 
    start_time = toc; 
    currenttime=toc;
while (currenttime < start_time+measure_sec)
    if (t.BytesAvailable > 0)
        %data_in=strcat(data_in,transpose(fread(t, t.BytesAvailable,'char')));
        data_in=strcat(data_in,transpose(fread(t, t.BytesAvailable,'char')));
    end
    currenttime=toc;
end
    fwrite(t,'off');
    meandata(i) = size(data_in,2)*2;
end 
 
fclose(t)
delete(t)

data_in;

bitrate = meandata./measure_sec;

plot(bitrate)

title('XMOS Ethernet Stream - Datenrate ')
xlabel('Anzahl an Messung')
ylabel('Bytes pro sekunde')
axis([1 size(meandata,1) 0 max(meandata)*1.1])
snew = instrfind;
if ~(isempty(snew) )  
    fclose(snew)
    delete(snew)
    clear snew
end